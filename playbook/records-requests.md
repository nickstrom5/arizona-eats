# Public records requests to send (drafts for Nick; nothing has been sent)

Nick's calls 2026-10-22: Maricopa grades by records request instead of a crawl; liquor licensees by records request.
Both are Nick's to send, from his own account. Arizona Public Records Law: A.R.S. 39-121 et seq. The app is free with no ads and no
purchases, so these are non-commercial requests (A.R.S. 39-121.03 applies to commercial purposes).

## 1. Maricopa County Environmental Services: inspection grades
Where: https://publicrecordsrequest.maricopa.gov (department: Environmental Services).

> Under the Arizona Public Records Law (A.R.S. 39-121), I request an electronic export (CSV or Excel) of retail food establishment
> inspection results for Maricopa County from January 1, 2024 to the present, with these fields where they exist: permit (license)
> number, establishment name, address, city, zip, inspection date, inspection type, grade or rating (A, B, C, D, A+ / Cutting Edge,
> or Not Participating), and the number of priority violations. If an export of the data behind the public Restaurant Ratings search
> is easier, that would be ideal. The information will be used in a free, non-commercial consumer app and website (no advertising,
> no purchases, no resale), so this is not a request for a commercial purpose. Please contact me at nick@eatsranked.com if anything
> needs clarifying or if there is a fee.

## 2. Arizona Department of Liquor Licenses and Control: active licensees
Where: the department's public records request form (azliquor.gov, "Public Records"), or by email to the department.

> Under A.R.S. 39-121, I request an electronic list (CSV or Excel) of all active Arizona liquor licenses of series 6 (bar), 7 (beer
> and wine bar) and 12 (restaurant), with license number, series, status, business (DBA) name, premises address, city, zip, county,
> and original issue and expiration dates. I don't need agent or owner names or home addresses. The list will be used in a free,
> non-commercial consumer app and website (no advertising, no purchases, no resale). Please contact me at nick@eatsranked.com if
> there is a fee or a standard export.

When either file arrives, save it in `data/raw/official/` and tell the az-eats session: `pipeline/official.py` gets a loader for it.
