# Beer Database Schema Design

## Firestore Collections

### `breweries/{breweryId}`

Document ID: auto-generated Firestore ID.

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `name` | string | yes | Canonical brewery name |
| `name_lower` | string | yes | Lowercase for queries |
| `address` | string | no | |
| `website` | string | no | |
| `year_founded` | string | no | From BeerWeb |
| `region` | string | no | From BeerWeb |
| `atlas_piv_id` | number | no | Original AtlasPiv ID |
| `beerweb_slug` | string | no | Original BeerWeb slug |
| `source` | string | yes | "atlas_piv", "beerweb", "merged", "manual" |

### `beers/{beerId}`

Document ID: auto-generated Firestore ID.

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `name` | string | yes | Beer name |
| `name_lower` | string | yes | Lowercase for search |
| `search_terms` | string[] | yes | Word-prefix tokens for array-contains queries |
| `brewery_id` | string | yes | Reference to breweries collection |
| `brewery_name` | string | yes | Denormalized for display |
| `epm` | string | no | Original Plato degrees string |
| `alcohol_percent` | number | no | Parsed numeric (e.g. 4.6) |
| `malt` | string | no | e.g. "ječný" |
| `fermentation` | string | no | e.g. "spodní" / "svrchní" |
| `type` | string | no | e.g. "světlé" / "tmavé" |
| `group` | string | no | e.g. "ležák" / "výčepní" |
| `beer_style` | string | no | e.g. "India Pale Ale (IPA)" |
| `atlas_piv_beer_id` | number | no | Original AtlasPiv beer ID |
| `beerweb_id` | string | no | Original BeerWeb beer ID |
| `source` | string | yes | "atlas_piv", "beerweb", "merged", "manual" |

## Search Strategy

Beer search in `create_keg_screen.dart`:
1. Normalise & split the user query into words (strip diacritics, lowercase)
2. Pick the longest word and query `beers` collection using `array-contains` on `search_terms`
3. Client-side: filter results so ALL query words appear as substrings in the combined name + brewery
4. Limit to 50 Firestore results

The `search_terms` array stores all word-prefixes (length >= 2) from the
normalised beer name + brewery name. E.g. "zealand" produces tokens
["ze", "zea", "zeal", ..., "zealand"]. This enables autocomplete-style
partial-word matching via a single `array-contains` query.

## Deduplication Strategy (import script)

1. Import BeerWeb first (richer data, more entries)
2. Import AtlasPiv second with fuzzy matching:
   - For each AtlasPiv brewery, find BeerWeb brewery by normalized name match
   - If match found: merge IDs, skip duplicate beers (by normalized name)
   - If no match: create new brewery and beers
3. Name normalization: lowercase, strip accents, collapse whitespace

## Security Rules

```
match /breweries/{breweryId} {
  allow read: if request.auth != null;
  allow write: if false; // Admin-only via import script
}
match /beers/{beerId} {
  allow read: if request.auth != null;
  allow write: if false; // Admin-only via import script
}
```

The beer DB editor app will use Firebase Admin SDK to bypass rules.
