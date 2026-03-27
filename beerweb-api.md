# BeerWeb.cz — API Documentation

> Researched: 13 March 2026  
> Base URL: `https://beerweb.cz`

---

## ✅ Confirmed Working API Endpoints

### `GET /api/Search?term={query}`

**Universal autocomplete search** — returns an XML list of matching breweries, beers, and venues.

| Parameter | Type | Description |
|---|---|---|
| `term` | `string` | Search keyword (e.g. `kozel`, `pilsner`, `prazdroj`) |

**Example request:**
```
GET https://beerweb.cz/api/Search?term=kozel
```

**Response format** — XML (ASP.NET DataContract):
```xml
<ArrayOfNameUrlViewModel
  xmlns:i="http://www.w3.org/2001/XMLSchema-instance"
  xmlns="http://schemas.datacontract.org/2004/07/BeerWeb.WebUI.Models.Shared">
  <NameUrlViewModel>
    <Name>Velkopopovický Kozel, pivovar</Name>
    <Url>/pivovar/kozel</Url>
  </NameUrlViewModel>
  <NameUrlViewModel>
    <Name>Kozel Premium, pivo</Name>
    <Url>/pivo/kozel-premium</Url>
  </NameUrlViewModel>
  <NameUrlViewModel>
    <Name>Kozel Světlý 10°, pivo</Name>
    <Url>/pivo/kozel-svetly-10</Url>
  </NameUrlViewModel>
  ...
</ArrayOfNameUrlViewModel>
```

**Result `Url` prefixes and their meaning:**

| URL prefix | Entity type |
|---|---|
| `/pivo/{slug}` | Beer |
| `/pivovar/{slug}` | Brewery |
| `/p/{id}-{slug}` | Venue / pub |

---

### `GET /MyImage.ashx?ID={id}`

**Image handler** — serves beer and brewery photos by numeric ID.

| Parameter | Type | Description |
|---|---|---|
| `ID` | `integer` | Numeric image ID (found on beer/brewery detail pages) |

**Example request:**
```
GET https://beerweb.cz/MyImage.ashx?ID=1536
```

Returns a JPEG/PNG image directly. The ID is embedded in `<img>` tags on beer and brewery detail pages.

---

## ❌ Non-existent / Probed Endpoints (all return 404)

All guessed REST-style routes under `/api/` returned:
```xml
<Error>
  <Message>No HTTP resource was found that matches the request URI '...'.</Message>
</Error>
```

Probed paths that do **not** exist:
- `/api/Beers`
- `/api/Breweries`
- `/api/Pivovar`
- `/api/Pivo`
- `/api/MapData`
- `/api/MapDataOstatni`
- `/api/PivniMapa`
- `/api/GetMapData`
- `/api/Rating`
- `/api/Degustace`
- `/api/SearchBeer`
- `/api/SearchPivo`
- `/api/SearchPivovar`
- `/api/SearchPodnik`

---

## 📌 Useful Page Routes (HTML, not REST)

These are server-rendered pages — not JSON/XML APIs — but contain structured data useful for scraping if needed.

| URL Pattern | Content |
|---|---|
| `/pivo/{slug}` | Beer detail: name, alcohol %, style, ratings, brewery link |
| `/pivovar/{slug}` | Brewery detail: address, GPS (via Google Maps link), beer list |
| `/p/{id}-{slug}` | Venue / pub detail |
| `/pivovar/{slug}/pivni-mapa` | Single brewery map pin (GPS coordinates embedded) |
| `/pivni-mapa` | Full brewery map (Google Maps, clustered pins) |
| `/pivni-mapa-ostatni` | Pubs / venues map |
| `/degustace/{slug}` | Detailed tasting form (requires login) |
| `/prehledy/piva` | Filterable beer list (server-side ASP.NET postback) |
| `/prehledy/pivovary` | Filterable brewery list |
| `/prehledy/uzivatele` | User list |
| `/prehledy/pivni-styly` | Beer styles list |
| `/prehledy/kalendar-pivni-akce` | Beer events calendar |

---

## 🔑 Usage in Beerer

The only clean public API endpoint suitable for use in Beerer is:

```
GET https://beerweb.cz/api/Search?term={query}
```

**Recommended integration approach:**
- Call this from a **Firebase Cloud Function** (avoids CORS, keeps requests server-side)
- Parse the XML response and return a JSON list of `{ name, url, type }` to the Flutter app
- Use the `Url` field to derive the slug and link back to BeerWeb details
- This replaces or supplements the Untappd API for Czech/Slovak brewery data

**Example Cloud Function shape:**
```ts
// functions/src/index.ts
export const searchBeerWeb = functions.https.onCall(async (data) => {
  const term = data.term as string;
  const res = await fetch(`https://beerweb.cz/api/Search?term=${encodeURIComponent(term)}`);
  const xml = await res.text();
  // parse XML → return JSON array
});
```
