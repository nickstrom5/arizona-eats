# Arizona Eats (az-eats) — notes for Claude Code sessions

Started 2026-10-22 from `../state-prompts/ARIZONA_PROMPT.md` and `../STATE_EATS_PLAYBOOK.md` (read both). Pipeline and app ported
from `../tx-eats/` (Texas: core + per-region detail files, county inspection model); never modify another state's folder.

Products:
- **Web leaderboard** (`site/`, git-ignored), a private claude.ai Artifact (link in `LOCAL.md` and the session memory, never in a public
  repo). Uses Google 2021 ratings (UCSD snapshot), labeled as such. `scripts/make-leaderboard.py` builds `site/index.html` from
  `../wi-eats/site/index.html`; republish with `arizona.json`, `az_detail.json`, `az_shapes.json`.
- **iOS/iPadOS app** "Arizona Eats: Restaurants" (Home Screen "Arizona Eats", bundle `com.arizonaeats.ios`), `ArizonaEats/`, XcodeGen.
  Nick's calls 2026-10-22: prickly pear cactus icon on flag blue (`scripts/make-brand.swift`, from concept B of
  `scripts/icon-concepts.swift`; passes `../state-prompts/icon-style/check.swift`); palette flag blue #002868, copper #CE5C17 fill /
  #B54E12 text, sun yellow #FFD100 fill only, sand #F3E3C3 (`ArizonaEats/Design/Theme.swift`). Light mode only.
- **Website** (generated `docs/` by `scripts/make-site.py`, 22 pages, built locally 2026-10-23; `scripts/qa-site.py` passes; screenshots
  captured 2026-10-24 with `scripts/capture-screenshots.sh` (iPhone 1320×2868, iPad 2064×2752 with PREFIX=ipad-), site copies by
  `scripts/site-images.sh`. Leave ipad-honors out of the App Store set: the iPad list column cuts its inline title): arizona.eatsranked.com once Nick adds the Cloudflare CNAME; until then
  nickstrom5.github.io/arizona-eats/ (`ArizonaEats/App/Links.swift`). Repo, Pages and DNS need Nick's yes.

## Data rules
- Arizona has no statewide permit list or inspection feed (ADHS delegates to 15 counties). Each county's result is shown as that county
  publishes it, labeled with county and date; we compute no grade. Sources, terms and calibration: `playbook/12-sources.md`.
- Nick's data calls 2026-10-22: Maricopa permit list **used** (free app, no resale); Maricopa grades only via a **records request** Nick
  sends (draft `playbook/records-requests.md`, no crawl); Pinal search **paged** (`pipeline/fetch_pinal.py`); liquor via records request.
- Robots-check every host before the first request: `cd pipeline && ../.venv/bin/python check_sources.py URL`. Never bypass a bot check
  (Coconino, Yuma, Navajo, Santa Cruz, HealthSpace, azliquor.gov and services.arcgis.com/robots.txt answer 403; the ArcGIS REST API is
  read as an API).
- The app ships no Google-derived data (`AZ_APP=1`). Guides that say "hand-checked" list only `hc` places with a 2025–26 source
  (`data/research/app/*.json`); empty guides are hidden on Home and in the iPad sidebar.
- Website links: `pipeline/check_websites.py` (Arizona news hosts added to NEWS), blocklist `pipeline/website_blocklist.json` (union of
  every state's), tracking tags stripped (`tracking_params.py`), blocklist scrub in the export (`link_blocklist.py`).
  First check 2026-10-22: 7,780 ok of 8,973 checked; 172 gambling, adult or hacked pages dropped. Re-run before each submission.
- Tests 2026-10-22: unit 28/28 on the bundled data (Arizona model, guides, county ratings, outline, Bib Gourmand, link and data guards,
  El Güero Canelo's three locations); iPhone UI smoke tests pass on "AZ Eats 6.9" (map layer chips are revealed by swiping the chip
  row: Arizona's labels push "Everything" off a phone); iPad "AZ Eats iPad 13" UI tests pass (2026-10-23).
- Hand-checked research 2026-10-22 (research session): 106 entries, all matched; guides Sonoran dogs 19, Sonoran Mexican 28,
  chimichangas 15, fry bread 3, Route 66 19, saloons 11, oldest 7. Leads and blocked hosts: data/research/app/LEADS.md.

## Rebuild
```bash
.venv/bin/python pipeline/fetch_overture.py && .venv/bin/python pipeline/fetch_extras.py      # Overture 2026-10-21.0 places, outlines, address points
.venv/bin/python pipeline/fetch_official.py && .venv/bin/python pipeline/fetch_pinal.py       # Maricopa permits, Tucson licenses; Pinal (resumable, ~1 h)
cd pipeline && ../.venv/bin/python listings.py && ../.venv/bin/python geocode_official.py && ../.venv/bin/python calibrate.py
../.venv/bin/python arizona.py && AZ_APP=1 ../.venv/bin/python arizona.py && cd ..              # web: site/arizona.json; app: data/app/
.venv/bin/python scripts/make-leaderboard.py
cp data/app/places.json data/app/detail-*.json ArizonaEats/Resources/
```
Mohave PDFs are downloaded by hand-run curl into `data/raw/official/mohave/` (see 12-sources); `official.py` parses and caches them.

## Machine
Simulator "AZ Eats 6.9" (iPhone 17 Pro Max, iOS 27.0), udid in `.simulators`; shut it down after use. Build with
`DEVELOPER_DIR="/Applications/Xcode 1.app/Contents/Developer"` and `-derivedDataPath DerivedData`. Check `ps -u $(id -u) | wc -l` and
free disk before booting (the disk filled up on 2026-10-22).

## Outward actions need Nick's explicit yes, every time
Public repo, pushes, Pages, App Store Connect, uploads, emails, records requests. Never submit for review. Support email nick@eatsranked.com.
- `pipeline/website_blocklist.json` is the union of every state's list, minus one bad entry: California's `http://chick-fil-a.com/`
  ("domain does not resolve") was wrong on 2026-10-23 (chick-fil-a.com and www resolve) and matched every Chick-fil-A link label.
