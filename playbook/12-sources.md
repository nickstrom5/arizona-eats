# Arizona sources (checked 2026-10-22)

Every host below was robots-checked with `pipeline/check_sources.py` (ClaudeBot, Claude-User, anthropic-ai; RFC 9309 matcher)
before any request. User agent on every request: `ArizonaEatsBuild/1.0 (+nick@eatsranked.com)`. Raw files are in
`data/raw/official/` (git-ignored, never public).

Arizona has **no statewide food-permit list or inspection feed**: ADHS delegates retail food safety to the 15 counties, and every
county publishes (or doesn't) in its own way and on its own scale. So nothing is blended into a statewide number: each county's
result is shown as that county published it, with its date, and labeled official. We compute no grade anywhere.

## Statewide

| Source | What | Terms | Cadence | Rows |
|---|---|---|---|---|
| Overture Maps places `2026-10-21.0` (newest release) | Map listings, the statewide base; state and county outlines; address points | CDLA-Permissive-2.0 / Apache-2.0 + Foursquare NOTICE | Monthly | 29,884 eating/drinking listings in AZ; 3.7M address points |
| UCSD Google Local 2021 (`meta-Arizona.json.gz`, mcauleylab.ucsd.edu) | 2021 ratings, reviews, price — **web leaderboard only, never the app** | research dataset | frozen Sep 2021 | 18,276 food listings |
| Census County Business Patterns 2023 (from the prompt) | NAICS 722 establishments: 13,666 statewide; Maricopa 8,992, Pima 1,862, Yavapai 517, Coconino 437 | public | yearly | benchmark only |

## Counties and cities

| Jurisdiction | Source | What it gives | Status |
|---|---|---|---|
| **Maricopa County** (Environmental Services) | ArcGIS "Restaurant (External)", item 4f5bfeaefa0448a584b46cbc120397ea (`services.arcgis.com/ykpntM6e3tHvzKRJ/.../Restaurant_(External)/FeatureServer/0`), read through the documented REST API, 2,000 rows a request | Every issued food permit: name, address, city, zip, LicenseNumber (FD fixed / MF mobile), a point. 105,589 rows = 28,972 permits (repeated rows; 370 permits' rows disagree on the point, so those are re-placed by address). No inspections. Includes schools, stores, gas stations, mobile units | **used** (Nick's yes 2026-10-22: free app, no resale). Item licence: "Any download for commercial intent or resale ... is prohibited, except in accordance with a sublicensing agreement" (A.R.S. 39-121.03), plus a no-warranty clause. services.arcgis.com answers 403 to /robots.txt; the API itself answers normally (co-eats and ct-eats treat ArcGIS REST as an API host) |
| Maricopa County grades | `envapp.maricopa.gov/Permit/PermitResults/<LicenseNumber>` (HTML, 3 years) and the Weekly Report form | The official voluntary A/B/C/D grade card (A+ Cutting Edge), or "Not Participating" + priority violations | **not used yet**: ~29,000 pages. Nick's call 2026-10-22: a public records request for a bulk export (draft in `playbook/records-requests.md`, Nick sends it); no crawl |
| **Pima County** | `healthinspect.pima.gov/portal/` (Hedgerow) | Ratings Excellent / Good / Satisfactory / Needs Improvement / Probation | **not used**: search-only, Google reCAPTCHA and login-only endpoints. Never scripted |
| City of **Tucson** | "Business Licenses (Open Data)", item b0e8f873aaeb4375b481979be334fbf2 (`gis.tucsonaz.gov/.../OpenData_EconomicDevelopment/MapServer/3`), `NAIC_CODE LIKE '722%'` | 1,988 rows (1,846 Active): account name, NAICS, address, start date, point. City limits only. ACC_NAME can be a person's name: never shown | **used** to confirm places |
| **Pinal County** | `app1.pinal.gov/search/foodinspection-search.aspx` (robots allows; no CAPTCHA): one search per rating class and year, paged 10 rows a page, 3 s apart (Nick's yes 2026-10-22; 258 pages) | 2,521 inspections, 1,240 establishments, 2025-10-22 to 2026-10-21 (the search keeps a rolling year): name, date, official rating class **E Excellent / S Satisfactory / N Needs Improvement / U Unacceptable**, address, town. No permit number | **used**; inspections newer than fetch − 7 days dropped (records through 2026-10-15) |
| **Mohave County** | Monthly "Food Safety Inspections" PDFs on mohave.gov (Jan 2025 – Sep 2026, 21 files) | One row per inspection: date, official rating **Excellent / Satisfactory / Needs Improvement** (N/A for retail-only; 6 "Unacceptable", 3 "Closed"), name, address, permit type. 4,595 rated inspections, 4,182 establishments | **used** (parsed by column position; typed dates outside the span, e.g. 2020 and 2036, dropped) |
| **Yavapai County** | HealthSpace (`healthspace.com/.../Yavapai_Web_Live.nsf`) | HTML lists by town with last inspection date | **not used**: healthspace.com answers 403 (bot check) |
| Yavapai County | **Golden Plate Award 2025**: news page `yavapaiaz.gov/News-articles/Golden-Plate-Awards-2025` and its PDF `.../2025-golden-plate-announcement-mixed-cities.pdf` | 245 establishments (we parse 246 lines) with a whole year free of priority / priority-foundation violations, an approved food-safety plan and a certified manager; by town and risk category, with consecutive-year counts | **used** as the county's award (matched by name in Yavapai County: 99 restaurants) |
| Coconino, Yuma, Navajo, Santa Cruz | county sites | — | **not used**: each answers 403 to robots.txt (Cloudflare/bot check). Never bypassed |
| Cochise, Gila | county sites (robots allow) | no bulk inspection list found | not used |
| Tribal lands (Navajo Nation, Tohono O'odham, Salt River, Gila River, ...) | — | outside county inspection | "no county record" |

## Liquor and property
- Department of Liquor Licenses and Control (azliquor.gov): 403 bot check. Not scraped. Nick's call 2026-10-22: a public records request
  for active series 6 (bar) and 12 (restaurant) licensees (draft in `playbook/records-requests.md`; Nick sends it).
- Property values: Maricopa GIS/Assessor downloads bar commercial use without a sublicense. No building-value board.

## Honors (data/research)
- **MICHELIN Guide American Southwest** (guide.michelin.com, robots allows; read 2026-10-22 with Claude's web fetcher, which only reads
  pages the robots allow): Arizona has 19 restaurants, **7 Bib Gourmand** (the guide's own Bib filter page: Huarachis Taqueria, kid sister,
  Lom Wong, Valentine, Pizzeria Bianco, Little Miss BBQ in Phoenix; FnB in Scottsdale) and 12 Recommended; no stars, no Green Stars.
  Each restaurant page read for its address (`michelin.json`). The Young Chef and Sommelier awards in the prompt aren't verified yet.
- **James Beard** (`jbf.json`): America's Classics El Chorro (2005), The Fry Bread House (2012), El Güero Canelo (2018) (Wikipedia's
  list); Best Chef: Southwest René Andrade, Bacanora (2024) and Yotaka Martin, Lom Wong (2025) (KTAR); 2022 Outstanding Restaurateur
  Chris Bianco and Outstanding Baker Don Guerra, Barrio Bread (jamesbeard.org); 12 semifinalists in 2026, no finalists (KTAR).

## Calibration (2026-10-22, `data/az/calibration*.json`): share of map listings found on the official list
| Kind of listing | Maricopa permits (full list) | Pinal inspected | Mohave inspected | Tucson licenses (lower bound) |
|---|---|---|---|---|
| Meta + open in Google 2021 | 88.7% of 6,078 | 85.7% of 308 | 73.5% of 306 | 57.9% of 1,189 |
| Meta only | 51.9% of 4,848 | 42.1% of 335 | 44.1% of 315 | 22.8% of 921 |
| Chain store list only | 66.8% of 473 | 69.4% of 36 | 45.2% of 31 | 29.5% of 61 |
| Foursquare only | 11.4% of 1,498 | 12.3% of 57 | 11.4% of 44 | 5.3% of 227 |
| BrightQuery only | 17.6% of 1,838 | 11.6% of 43 | 26.3% of 57 | 13.8% of 326 |
| App grouping: Meta ≥ 0.95 | 87.4% | 83.4% | 74.9% | 54.6% |
| App grouping: Meta 0.90–0.95 | 52.2% | 55.0% | 51.3% | 18.1% |
| App grouping: Meta < 0.90 | 24.2% | 15.5% | 20.4% | 11.3% |

Same pattern as Colorado, Texas and Idaho, so the same keep rules: web = Meta and chain store lists (plus official and hand-checked),
minus what Google showed closed in 2021; app = Meta ≥ 0.95, Meta 0.90–0.95 with a website, chain store lists, official, hand-checked.
Coverage the other way: the open map listings hold 58.5% of Maricopa's 15,315 permitted "food" businesses (that list also counts school
kitchens, stores and kiosks), 59.9% of Pinal's, 43.0% of Mohave's, 77.6% of Tucson's NAICS-722 licensees; plainly named restaurants among
the rest are added from the lists (1,408 in the first web build).

## Per-county coverage (open, cleaned map listings; official records used)
| County | Listings | Official records | CBP 2023 NAICS 722 |
|---|---|---|---|
| Maricopa | 18,196 | permit list (bulk); grades pending a records request | 8,992 |
| Pima | 3,755 | Tucson licenses only | 1,862 |
| Yavapai | 1,075 | Golden Plate list | 517 |
| Pinal | 901 | inspection ratings | — |
| Coconino | 868 | none (bot check) | 437 |
| Mohave | 850 | inspection ratings | — |
| Yuma | 717 | none (bot check) | — |
| Cochise | 527 | none found | — |
| Navajo | 392 | none (bot check) | — |
| Gila | 240 | none found | — |
| Santa Cruz | 190 | none (bot check) | — |
| La Paz | 144 | none found | — |
| Apache | 112 | none found | — |
| Graham | 89 | none found | — |
| Greenlee | 28 | none found | — |
