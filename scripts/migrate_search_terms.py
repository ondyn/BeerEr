#!/usr/bin/env python3
"""One-time migration: add `search_terms` array to every beer document.

Usage:
    python scripts/migrate_search_terms.py          # dry run
    python scripts/migrate_search_terms.py --apply  # actually write
"""

import argparse
import re
import sys

import firebase_admin
from firebase_admin import credentials, firestore
from unidecode import unidecode


def normalize_name(name: str) -> str:
    return re.sub(r'\s+', ' ', unidecode(name).lower().strip())


def make_search_terms(beer_name: str, brewery_name: str) -> list[str]:
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


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--apply', action='store_true',
                        help='Actually write to Firestore (default is dry run)')
    args = parser.parse_args()

    cred = credentials.ApplicationDefault()
    firebase_admin.initialize_app(cred, {'projectId': 'ondyn-beerer'})
    db = firestore.client()

    print('Fetching all beer documents...')
    docs = db.collection('beers').stream()

    batch = db.batch()
    count = 0
    batch_count = 0

    for doc in docs:
        data = doc.to_dict()
        beer_name = data.get('name', '')
        brewery_name = data.get('brewery_name', '')
        terms = make_search_terms(beer_name, brewery_name)

        if args.apply:
            batch.update(doc.reference, {'search_terms': terms})
            batch_count += 1
            if batch_count >= 499:
                batch.commit()
                batch = db.batch()
                batch_count = 0
        else:
            if count < 5:
                print(f'  {beer_name} -> {terms}')

        count += 1

    if args.apply and batch_count > 0:
        batch.commit()

    action = 'Updated' if args.apply else 'Would update'
    print(f'{action} {count} beer documents.')


if __name__ == '__main__':
    main()
