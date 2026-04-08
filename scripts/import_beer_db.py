#!/usr/bin/env python3
"""
Import beer data from BeerWeb and AtlasPiv JSON files into Firestore.

Usage:
    pip install firebase-admin unidecode
    export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
    python scripts/import_beer_db.py [--dry-run]

Idempotent: uses beerweb_id / atlas_piv_beer_id to skip already-imported
beers and breweries. Safe to run multiple times.
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore
from unidecode import unidecode

# ---------------------------------------------------------------------------
# Firestore setup
# ---------------------------------------------------------------------------

PROJECT_DIR = Path(__file__).resolve().parent.parent
BEERWEB_DIR = PROJECT_DIR / 'BeerWeb'
ATLASPIV_DIR = PROJECT_DIR / 'AtlasPiv'


def init_firestore():
    cred = credentials.ApplicationDefault()
    firebase_admin.initialize_app(cred, {'projectId': 'ondyn-beerer'})
    return firestore.client()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def normalize_name(name: str) -> str:
    """Lowercase, strip accents, collapse whitespace."""
    return re.sub(r'\s+', ' ', unidecode(name).lower().strip())


def make_search_terms(beer_name: str, brewery_name: str) -> list[str]:
    """Build word-prefix tokens for Firestore array-contains queries.

    For each word of >= 2 characters we store every prefix from length 2
    up to the full word.  E.g. "zealand" -> ["ze", "zea", ..., "zealand"].
    This lets the client query with partial input (autocomplete).
    """
    combined = f'{beer_name} {brewery_name}'
    normalised = normalize_name(combined)
    words = re.split(r'[\s\W]+', normalised)
    prefixes: set[str] = set()
    for w in words:
        if len(w) < 2:
            continue
        for end in range(2, len(w) + 1):
            prefixes.add(w[:end])
    return sorted(prefixes)


def parse_alcohol_beerweb(val: str | None) -> float | None:
    """Parse '5,0% vol.' → 5.0"""
    if not val:
        return None
    m = re.search(r'([\d]+[,.]?\d*)', val)
    if m:
        return float(m.group(1).replace(',', '.'))
    return None


def parse_alcohol_atlaspiv(val: str | None) -> float | None:
    """Parse '4.60 %' → 4.6, 'nezjišteno %' → None"""
    if not val or 'nezji' in val.lower():
        return None
    m = re.search(r'([\d]+[.]?\d*)', val)
    if m:
        return float(m.group(1))
    return None


def parse_epm_clean(val: str | None) -> str | None:
    """Clean EPM string, return None if unknown."""
    if not val:
        return None
    if 'nezji' in val.lower():
        return None
    # Strip trailing ° and whitespace
    return val.replace('°', '').strip() + '°'


def load_json(path: Path) -> dict | list:
    with open(path, encoding='utf-8') as f:
        return json.load(f)


# ---------------------------------------------------------------------------
# Import BeerWeb
# ---------------------------------------------------------------------------

def import_beerweb(db, dry_run: bool):
    print('\n=== Importing BeerWeb ===')
    index_path = BEERWEB_DIR / 'breweries_index.json'
    if not index_path.exists():
        print(f'  Index not found: {index_path}')
        return {}

    index = load_json(index_path)
    print(f'  Found {len(index)} breweries in index')

    # Build lookup of existing breweries by beerweb_slug
    existing_breweries = {}
    for doc in db.collection('breweries').where('beerweb_slug', '!=', '').stream():
        data = doc.to_dict()
        existing_breweries[data.get('beerweb_slug')] = doc.id

    # Build lookup of existing beers by beerweb_id
    existing_beers = set()
    for doc in db.collection('beers').where('beerweb_id', '!=', '').stream():
        data = doc.to_dict()
        existing_beers.add(data.get('beerweb_id'))

    print(f'  Existing: {len(existing_breweries)} breweries, {len(existing_beers)} beers')

    # Map: normalized_name → brewery_doc_id (for AtlasPiv matching later)
    name_to_id = {}
    breweries_created = 0
    beers_created = 0
    beers_skipped = 0

    for entry in index:
        slug = entry.get('brewery_slug') or entry.get('brewery_name', '')
        name = entry['brewery_name']

        # Load brewery file
        # Try slug-based filename first, fall back to index-based
        brewery_file = None
        for f in BEERWEB_DIR.glob('brewery_*.json'):
            try:
                data = load_json(f)
                if data.get('brewery_slug') == slug or data.get('brewery_name') == name:
                    brewery_file = f
                    break
            except (json.JSONDecodeError, KeyError):
                continue

        if brewery_file is None:
            continue

        brewery_data = load_json(brewery_file)
        norm_name = normalize_name(name)

        # Create or get brewery
        if slug in existing_breweries:
            brewery_id = existing_breweries[slug]
        else:
            brewery_doc = {
                'name': name,
                'name_lower': norm_name,
                'address': brewery_data.get('brewery_address') or '',
                'website': brewery_data.get('brewery_website') or '',
                'year_founded': brewery_data.get('brewery_year_founded') or '',
                'region': brewery_data.get('brewery_region') or '',
                'beerweb_slug': slug,
                'source': 'beerweb',
            }
            if dry_run:
                brewery_id = f'dry-run-{slug}'
                print(f'  [DRY RUN] Would create brewery: {name}')
            else:
                ref = db.collection('breweries').document()
                ref.set(brewery_doc)
                brewery_id = ref.id
            existing_breweries[slug] = brewery_id
            breweries_created += 1

        name_to_id[norm_name] = brewery_id

        # Import beers
        for beer in brewery_data.get('beers', []):
            beerweb_id = beer.get('beerweb_id', '')
            if beerweb_id in existing_beers:
                beers_skipped += 1
                continue

            beer_name = beer.get('beer_name', '')
            beer_doc = {
                'name': beer_name,
                'name_lower': normalize_name(beer_name),
                'search_terms': make_search_terms(beer_name, name),
                'brewery_id': brewery_id,
                'brewery_name': name,
                'epm': parse_epm_clean(beer.get('epm')),
                'alcohol_percent': parse_alcohol_beerweb(beer.get('alcohol_content')),
                'malt': beer.get('malt'),
                'fermentation': beer.get('fermentation'),
                'type': beer.get('type'),
                'group': beer.get('group'),
                'beer_style': beer.get('beer_style'),
                'beerweb_id': beerweb_id,
                'source': 'beerweb',
            }
            # Remove None values
            beer_doc = {k: v for k, v in beer_doc.items() if v is not None}

            if dry_run:
                print(f'  [DRY RUN] Would create beer: {beer_name} ({name})')
            else:
                db.collection('beers').document().set(beer_doc)

            existing_beers.add(beerweb_id)
            beers_created += 1

    print(f'  BeerWeb done: {breweries_created} breweries, {beers_created} beers created, {beers_skipped} skipped')
    return name_to_id


# ---------------------------------------------------------------------------
# Import AtlasPiv (with fuzzy matching to BeerWeb)
# ---------------------------------------------------------------------------

def import_atlaspiv(db, name_to_id: dict, dry_run: bool):
    print('\n=== Importing AtlasPiv ===')
    index_path = ATLASPIV_DIR / 'breweries_index.json'
    if not index_path.exists():
        print(f'  Index not found: {index_path}')
        return

    index = load_json(index_path)
    print(f'  Found {len(index)} breweries in index')

    # Build lookup of existing breweries by atlas_piv_id
    existing_breweries = {}
    for doc in db.collection('breweries').where('atlas_piv_id', '!=', 0).stream():
        data = doc.to_dict()
        existing_breweries[data.get('atlas_piv_id')] = doc.id

    # Build lookup of existing beers by atlas_piv_beer_id
    existing_beers = set()
    for doc in db.collection('beers').where('atlas_piv_beer_id', '!=', 0).stream():
        data = doc.to_dict()
        existing_beers.add(data.get('atlas_piv_beer_id'))

    print(f'  Existing: {len(existing_breweries)} breweries, {len(existing_beers)} beers')

    breweries_created = 0
    breweries_merged = 0
    beers_created = 0
    beers_skipped = 0

    for entry in index:
        atlas_id = entry['brewery_id']
        name = entry['brewery_name']

        # Load brewery file
        brewery_file = ATLASPIV_DIR / f'brewery_{atlas_id}.json'
        if not brewery_file.exists():
            continue

        brewery_data = load_json(brewery_file)
        norm_name = normalize_name(name)

        # Check if already imported via atlas_piv_id
        if atlas_id in existing_breweries:
            brewery_id = existing_breweries[atlas_id]
        elif norm_name in name_to_id:
            # Merge with existing BeerWeb brewery
            brewery_id = name_to_id[norm_name]
            if not dry_run:
                db.collection('breweries').document(brewery_id).update({
                    'atlas_piv_id': atlas_id,
                    'source': 'merged',
                })
            else:
                print(f'  [DRY RUN] Would merge brewery: {name}')
            existing_breweries[atlas_id] = brewery_id
            breweries_merged += 1
        else:
            # Create new brewery
            brewery_doc = {
                'name': name,
                'name_lower': norm_name,
                'address': brewery_data.get('brewery_address', ''),
                'website': brewery_data.get('brewery_website', ''),
                'atlas_piv_id': atlas_id,
                'source': 'atlas_piv',
            }
            if dry_run:
                brewery_id = f'dry-run-atlas-{atlas_id}'
                print(f'  [DRY RUN] Would create brewery: {name}')
            else:
                ref = db.collection('breweries').document()
                ref.set(brewery_doc)
                brewery_id = ref.id
            existing_breweries[atlas_id] = brewery_id
            name_to_id[norm_name] = brewery_id
            breweries_created += 1

        # Import beers
        for beer in brewery_data.get('beers', []):
            beer_id = beer.get('beer_id')
            if beer_id in existing_beers:
                beers_skipped += 1
                continue

            beer_name = beer.get('beer_name', '')
            norm_beer = normalize_name(beer_name)

            # Check if a BeerWeb beer with similar name already exists for this brewery
            # (simple dedup: same brewery + normalized name)
            existing_ref = (
                db.collection('beers')
                .where('brewery_id', '==', brewery_id)
                .where('name_lower', '==', norm_beer)
                .limit(1)
                .get()
            )
            if existing_ref:
                # Merge atlas_piv_beer_id into existing beer
                if not dry_run:
                    existing_ref[0].reference.update({
                        'atlas_piv_beer_id': beer_id,
                        'source': 'merged',
                    })
                beers_skipped += 1
                existing_beers.add(beer_id)
                continue

            beer_doc = {
                'name': beer_name,
                'name_lower': norm_beer,
                'search_terms': make_search_terms(beer_name, name),
                'brewery_id': brewery_id,
                'brewery_name': name,
                'epm': parse_epm_clean(beer.get('epm')),
                'alcohol_percent': parse_alcohol_atlaspiv(beer.get('alcohol_content')),
                'atlas_piv_beer_id': beer_id,
                'source': 'atlas_piv',
            }
            beer_doc = {k: v for k, v in beer_doc.items() if v is not None}

            if dry_run:
                print(f'  [DRY RUN] Would create beer: {beer_name} ({name})')
            else:
                db.collection('beers').document().set(beer_doc)

            existing_beers.add(beer_id)
            beers_created += 1

    print(f'  AtlasPiv done: {breweries_created} new, {breweries_merged} merged, '
          f'{beers_created} beers created, {beers_skipped} skipped')


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description='Import beer data into Firestore')
    parser.add_argument('--dry-run', action='store_true',
                        help='Print what would be done without writing to Firestore')
    args = parser.parse_args()

    if args.dry_run:
        print('*** DRY RUN MODE — no Firestore writes ***')
        # Still need a DB client for reading existing data
        db = init_firestore()
    else:
        db = init_firestore()

    # 1. Import BeerWeb first (richer data)
    name_to_id = import_beerweb(db, args.dry_run)

    # 2. Import AtlasPiv with fuzzy matching
    import_atlaspiv(db, name_to_id, args.dry_run)

    print('\nDone!')


if __name__ == '__main__':
    main()
