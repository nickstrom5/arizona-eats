"""Official records for Arizona -> one table of permitted / inspected food and drink businesses.

Arizona has no statewide food-permit list or inspection feed: ADHS delegates food safety to the 15 counties. Sources (playbook/12-sources.md):
- "mcp": Maricopa County Environmental Services, "Restaurant (External)" (ArcGIS item 4f5bfeaefa0448a584b46cbc120397ea, edited daily):
         every issued food permit (FD fixed, MF mobile) with name, address and a point. 105k rows are ~29k permits (repeated rows,
         sometimes with different points). No inspections. Nick's yes 2026-10-22 (free app, no resale).
- "tus": City of Tucson "Business Licenses (Open Data)" (NAICS 722 rows; city limits only). ACC_NAME can be a person's name.
- "pin": Pinal County Environmental Health inspection search (2025-26), official rating classes E/S/N/U.
- "moh": Mohave County Department of Public Health monthly "Food Safety Inspections" PDFs (Jan 2025 - Sep 2026), official rating
         Excellent / Satisfactory / Needs Improvement (N/A for retail-only permits).

load() returns: jur, lic (our id), name, keys (name keys), addr, city, zip, num, street, lat, lon, kind, active, ltype.
kind: restaurant | bar | food | retail | other.
"""
import os, re, json
import numpy as np, pandas as pd
from common import norm_name, RAW, name_sim, _stems, GENERIC, canon_city

OFF = os.path.join(RAW, "official")
DIRS = {"N": "N", "S": "S", "E": "E", "W": "W", "NORTH": "N", "SOUTH": "S", "EAST": "E", "WEST": "W"}
TYPES = set("ST STREET AVE AV AVENUE BLVD BOULEVARD RD ROAD DR DRIVE LN LANE CT COURT PL PLACE PKWY PARKWAY TER TRL TRAIL WAY HWY CIR "
            "CIRCLE PLZ SQ MALL BND PASS XING RUN ROW WALK RDG LOOP FWY FREEWAY EXPY EXPRESSWAY".split())


def road(a):
    """One spelling for numbered roads: 'US HIGHWAY 89' = 'US-89' = 'US 89'; 'STATE ROUTE 87' = 'SR 87' = 'AZ-87' = 'SH 87';
    'N INTERSTATE 17' = 'I-17'; 'HISTORIC ROUTE 66' = 'US 66'; 'COUNTY ROAD 5' = 'CR 5'."""
    a = re.sub(r"(\d)\s*&\s*(\d)", r"\1-\2", a.upper())
    a = re.sub(r"\b(US|AZ|SR|SH|CR|I|IH)-(\w)", r"\1 \2", a)
    a = re.sub(r"\b(?:INTERSTATE(?: HIGHWAY| HWY)?|IH|I H)\s*(?=\d)", "I ", a)
    a = re.sub(r"\b(?:US|U S)\s+(?:HIGHWAY|HWY)\b", "US", a)
    a = re.sub(r"\b(?:FARM[- ]TO[- ]MARKET(?: ROAD| RD)?|FARM (?:ROAD|RD)|F M)\b", "FM", a)
    a = re.sub(r"\b(?:RANCH[- ]TO[- ]MARKET(?: ROAD| RD)?|RANCH (?:ROAD|RD)|RR|RM)\b(?=\s*\d)", "RM", a)
    a = re.sub(r"\b(?:STATE (?:HIGHWAY|HWY|ROAD|RD|ROUTE|RTE)|SR|SH|ARIZONA (?:HIGHWAY|HWY|STATE (?:HIGHWAY|ROUTE))|AZ (?:HIGHWAY|HWY)|AZ)\b(?=\s*\d)", "SH", a)
    a = re.sub(r"\b(?:HISTORIC )?(?:ROUTE|RT|RTE) 66\b", "US 66", a)
    a = re.sub(r"\b(?:COUNTY (?:HIGHWAY|HWY|ROAD|RD)|CO RD|CTY (?:HWY|RD)|CR)\b", "CR", a)
    a = re.sub(r"\bHIGHWAY\b", "HWY", a)
    return re.sub(r"\b(US|SH|CR|HWY|FM|RM|I) (\w+)\s*-\s*\w+", r"\1 \2", a)


ORD = {"FIRST": "1ST", "SECOND": "2ND", "THIRD": "3RD", "FOURTH": "4TH", "FIFTH": "5TH", "SIXTH": "6TH", "SEVENTH": "7TH",
       "EIGHTH": "8TH", "NINTH": "9TH", "TENTH": "10TH", "ELEVENTH": "11TH", "TWELFTH": "12TH"}


def street_key(a):
    """'2505 Monroe St' -> ('2505', 'MONROE'); '1000 OSAGE STREET' -> ('1000', 'OSAGE'); 'E Colfax Ave' keeps 'COLFAX'."""
    if not isinstance(a, str):
        return None, None
    a = re.sub(r"[.,#]", " ", road(a))
    m = re.match(r"^\s*(\d+)[A-Z]?(?:\s*-\s*\d+[A-Z]?)?\s+(.*)$", a)
    if not m:
        return None, None
    words = [w for w in m.group(2).split() if w]
    if len(words) > 1 and words[0] in DIRS:
        words = words[1:]
    core = []
    for w in words:
        if w in TYPES and core:
            break
        core.append(w)
    core = [ORD.get(w, w) for w in core]
    return m.group(1), " ".join(core[:3]) or None


def street_compat(a, b):
    """Same street, or one is a whole-word prefix of the other: Boulder's 2025 set sometimes truncates ("1206 CENTAUR" = Centaur Village Dr)."""
    if not isinstance(a, str) or not isinstance(b, str) or not a or not b:
        return False
    return a == b or a.startswith(b + " ") or b.startswith(a + " ")


def street_nums(a):
    """'157-159 W Main St' -> {'157', '159'}; '2505 Monroe St' -> {'2505'}."""
    if not isinstance(a, str):
        return set()
    a = road(a)
    m = re.match(r"^\s*(\d+)[A-Z]?(?:\s*-\s*(\d+)[A-Z]?)?\s", a.upper() + " ")
    if not m:
        return set()
    lo = int(m.group(1)); hi = int(m.group(2)) if m.group(2) else lo
    if hi < lo:   # "1500-02"
        hi = int(str(lo)[: len(str(lo)) - len(m.group(2))] + m.group(2)) if m.group(2) else lo
    return {str(x) for x in range(lo, hi + 1, 2 if (hi - lo) % 2 == 0 else 1)} if 0 <= hi - lo <= 12 else {str(lo)}


def _names(*vals):
    out = []
    for v in vals:
        if not isinstance(v, str):
            continue
        v = re.sub(r"\s*\((?:MOBILE|MOBILE UNIT|COMMISSARY|CATERING|SPECIAL EVENT|SPEC EVENT|TEMP(?:ORARY)? EVENT|CP|INSIDE [^)]*)\)\s*$", "", v, flags=re.I)
        for part in re.split(r"\s*/\s*|\s+\bdba\b\s+|\s+&\s+(?=[A-Z][a-z])", v, flags=re.I):
            k = norm_name(re.sub(r"\b(?:LLC|INC|CORP|CORPORATION|LTD|CO)\b\.?", "", part, flags=re.I))
            if k and k not in out:
                out.append(k)
    return out





LIST_DATE = None   # set by load(): the Maricopa list's last edit (ArcGIS editingInfo)
ONPREM = ("restaurant", "bar", "brewery")


def liq_kind(t):
    """Arizona: no liquor-licence list yet (azliquor.gov blocks scripts; a records request is Nick's to send)."""
    return None


def _zip(z):
    z = re.sub(r"\D", "", str(z or ""))
    return z[:5] if len(z) >= 5 else ""


OTHER = re.compile(r"\((?:MOBILE|MOBILE UNIT|COMMISSARY|CATERING|SPECIAL EVENT|TEMP(?:ORARY)? EVENT)\)|\b(?:SCHOOL|ELEMENTARY|MIDDLE|HIGH SCHOOL|"
                   r"ACADEMY|PRESCHOOL|CHILDCARE|CHILD CARE|DAYCARE|DAY CARE|HOSPITAL|JAIL|DETENTION|FOOD BANK|SENIOR|NURSING|USD|"
                   r"MOBILE|FOOD TRUCK|CATERING|CATERER|COMMISSARY|CONCESSION|BOYS (?:AND|&) GIRLS|COMMUNITY C(?:TR|ENTER)|"
                   r"KINDERGARTEN|MONTESSORI|ASSISTED|REHAB|CARE CENTER|HEALTH CENTER|CHURCH|PARISH|CAMP|"
                   # institutional and shared kitchens on the county lists (2026-10-23): not places to eat out
                   r"COMMERCIAL KITCHEN|TEST KITCHEN|CENTRAL KITCHEN|SHARED KITCHEN|SERVING KITCHEN|CULINARY KITCHEN|TEAM KITCHEN|BALLROOM|"
                   r"CORRECTION(?:AL)?|PRISON|CHARTER|CAMPUS|WAREHOUSE|GUEST SERVICES|ANNEX|PREPARATORY|COLLEGE|UNIVERSITY|USD|"
                   r"MHP|RV RESORT|RV PARK|MOBILE HOME|MANUFACTURED HOME|CLUBHOUSE|CLUB HOUSE)\b"
                   # Pinal lists a facility's units as "<facility> - Kitchen", "<facility> - Serving Kitchen"
                   r"|\s-\s*(?:[A-Z]+\s+)?KITCHEN\s*$", re.I)
RETAIL = re.compile(r"\b(?:CIRCLE K|QUIK ?TRIP|QT|7 ELEVEN|SEVEN ELEVEN|SHELL|CHEVRON|ARCO|VALERO|MOBIL|EXXON|SPEEDWAY|MAVERIK|LOVES|PILOT|"
                    r"FLYING J|TA TRAVEL|FRYS|BASHAS|SAFEWAY|ALBERTSONS|WALMART|WAL MART|TARGET|COSTCO|SAMS CLUB|SPROUTS|WHOLE FOODS|"
                    r"TRADER JOES|FOOD CITY|WINCO|SMITHS|DOLLAR|WALGREENS|CVS|MARKET|MART|GROCERY|LIQUOR|CARNICERIA|SUPERMERCADO|"
                    r"TOBACCO|SMOKE SHOP|VAPE|GAS|FUEL)\b")


def _row(jur, lic, name, addr, city, z, la, lo, kind, active=True, ltype=None, holder=None):
    num, st = street_key(addr)
    if OTHER.search(name or ""):
        kind = "other"
    elif kind == "food" and RETAIL.search(norm_name(name)):
        kind = "retail"
    return {"jur": jur, "lic": lic, "name": name, "dba": name, "holder": holder, "keys": _names(name), "addr": addr, "city": city,
            "zip": _zip(z), "num": num, "street": st, "lat": la, "lon": lo, "kind": kind, "active": active, "ltype": ltype}


def load_maricopa():
    global LIST_DATE
    j = json.load(open(f"{OFF}/maricopa_permits.json"))
    LIST_DATE = pd.to_datetime(j["edited"], unit="ms").strftime("%Y-%m-%d") if j.get("edited") else j["fetched"]
    d = pd.DataFrame(j["rows"])
    rows = []
    for lic, g in d.groupby("LicenseNumber", sort=False):
        r = g.iloc[0]
        # repeated rows can carry different points; the one most rows agree on wins (geocode_official checks it against the address)
        pts = g.assign(la=g.lat.round(5), lo=g.lon.round(5)).groupby(["la", "lo"]).size().sort_values(ascending=False)
        la, lo = (pts.index[0] if len(pts) else (np.nan, np.nan))
        mobile = lic.startswith("MF")
        rows.append(_row("mcp", "MCP-" + lic, (r.CompanyName or "").strip(), (r.BusinessAddress or "").strip(), canon_city(r.City),
                         r.Zip, la, lo, "other" if mobile else "food", ltype="Mobile food permit" if mobile else "Food establishment permit"))
        rows[-1]["county"] = "Maricopa"
        rows[-1]["n_pts"] = len(pts)
    return pd.DataFrame(rows)


TUS_KIND = {"Drinking Places (Alcoholic Bever": "bar", "Full-Service Restaurants": "restaurant", "Limited-Service Restaurants": "restaurant",
            "Snack and Nonalcoholic Beverage": "food", "Cafeterias, Grill Buffets, and B": "restaurant", "Mobile Food Services": "other",
            "Caterers": "other", "Food Service Contractors": "other"}


def load_tucson():
    j = json.load(open(f"{OFF}/tucson_licenses.json"))
    rows = []
    for r in j["rows"]:
        if (r.get("LIC_STATUS") or "").strip() != "Active":
            continue
        kind = TUS_KIND.get((r.get("NAIC_DESC") or "").strip(), "food")
        since = pd.to_datetime(r["DT_START"], unit="ms").strftime("%Y-%m-%d") if r.get("DT_START") else None
        x = _row("tus", "TUS-" + str(r["ACC_NUM"]).strip(), (r.get("ACC_NAME") or "").strip(), (r.get("ADDRESS") or "").strip(),
                 canon_city(r.get("CITY")), r.get("ZIP_CODE"), r.get("lat", np.nan), r.get("lon", np.nan), kind,
                 ltype="City of Tucson business license")
        x["since"], x["county"] = since, "Pima"
        rows.append(x)
    return pd.DataFrame(rows)


# ---------------------------------------------------------------- Pinal County: the search's own rows (one per inspection)
PINAL_RATING = {"E": "Excellent", "S": "Satisfactory", "N": "Needs Improvement", "U": "Unacceptable"}


PINAL_FETCHED = None


def _pinal_rows():
    import glob
    global PINAL_FETCHED
    rows = []
    for f in sorted(glob.glob(f"{OFF}/pinal/*.json")):
        j = json.load(open(f))
        PINAL_FETCHED = min(PINAL_FETCHED or j["fetched"], j["fetched"])
        for r in j["rows"]:
            rows.append(r)
    d = pd.DataFrame(rows)
    if d.empty:
        return d
    d["d"] = pd.to_datetime(d.date, format="%m/%d/%y", errors="coerce").dt.strftime("%Y-%m-%d")
    # publication lag: the search shows inspections the next day, but results can still change; keep what's at least 7 days older
    # than the fetch (the playbook's rule), so "records through" never claims the last few days
    d = d[d.d <= (pd.Timestamp(PINAL_FETCHED) - pd.Timedelta(days=7)).strftime("%Y-%m-%d")]
    # an establishment = same name at the same address and town (the search has no permit number column)
    d["est"] = "PIN-" + d.name.str.upper().str.replace(r"\W+", " ", regex=True).str.strip() + "|" + d.address.str.upper().str.strip() \
        + "|" + d.city.str.upper().str.strip()
    return d


def load_pinal():
    d = _pinal_rows()
    rows = []
    if d.empty:
        return pd.DataFrame(rows)
    for est, g in d.sort_values("d").groupby("est", sort=False):
        r = g.iloc[-1]
        x = _row("pin", est, r["name"], r.address, canon_city(r.city), "", np.nan, np.nan, "food",
                 active=g.d.max() >= "2025-04-01", ltype="Pinal County food establishment")
        x["county"] = "Pinal"
        rows.append(x)
    return pd.DataFrame(rows)


def pinal_inspections():
    """One row per inspection in the county's search: establishment, date and the county's own rating class
    (E Excellent / S Satisfactory / N Needs Improvement / U Unacceptable). Oldest first."""
    d = _pinal_rows()
    if d.empty:
        return pd.DataFrame(columns=["lic", "d", "score", "band", "typ", "re"])
    out = pd.DataFrame({"lic": d.est, "d": d.d, "score": np.nan, "band": d.rating.map(PINAL_RATING), "typ": "", "re": False,
                        "iid": pd.to_numeric(d.id, errors="coerce")})
    return out.sort_values(["lic", "d", "iid"]).reset_index(drop=True)


# ---------------------------------------------------------------- Mohave County: monthly PDFs, one row per inspection
MOH_RATING = {"EXCELLENT": "Excellent", "SATISFACTORY": "Satisfactory", "NEEDS IMPROVEMENT": "Needs Improvement", "N/A": None}
_MOH_CACHE = os.path.join(OFF, "mohave", "parsed.json")


def _mohave_parse():
    import glob
    files = sorted(glob.glob(f"{OFF}/mohave/*.pdf"))
    if os.path.exists(_MOH_CACHE):
        c = json.load(open(_MOH_CACHE))
        if c.get("files") == [os.path.basename(f) for f in files]:
            return c["rows"]
    import pdfplumber
    rows, rec = [], None
    for f in files:
        with pdfplumber.open(f) as pdf:
            for pg in pdf.pages:
                # every month's list has the same columns: date | rating ("Status" before 2026) | establishment | address | description
                cut = [80, 168, 334, 465]
                lines = {}
                for w in pg.extract_words():
                    lines.setdefault(round(w["top"]), []).append(w)
                for top in sorted(lines):
                    text = " ".join(w["text"] for w in sorted(lines[top], key=lambda w: w["x0"]))
                    if re.search(r"MOHAVE COUNTY DEPARTMENT|FOOD SAFETY INSPECTIONS|^[A-Z]+ 20\d\d$|\bAREA$|^Inspection\b|^Date$", text):
                        continue
                    cols = ["", "", "", "", ""]
                    for w in sorted(lines[top], key=lambda w: w["x0"]):
                        c = sum(w["x0"] >= x for x in cut)
                        cols[c] = (cols[c] + " " + w["text"]).strip()
                    if re.fullmatch(r"\d\d/\d\d/\d\d", cols[0]):
                        if rec:
                            rows.append(rec)
                        rec = {"date": cols[0], "rating": cols[1], "name": cols[2], "addr": [cols[3]], "desc": cols[4], "file": os.path.basename(f)}
                    elif rec:
                        rec["rating"] = (rec["rating"] + " " + cols[1]).strip()
                        rec["name"] = (rec["name"] + " " + cols[2]).strip()
                        if cols[3]:
                            rec["addr"].append(cols[3])
                        rec["desc"] = (rec["desc"] + " " + cols[4]).strip()
        if rec:
            rows.append(rec)
            rec = None
    json.dump({"files": [os.path.basename(f) for f in files], "rows": rows}, open(_MOH_CACHE, "w"))
    return rows


MOH_TOWNS = ["LAKE HAVASU CITY", "LAKE HAVASU", "LHC", "BULLHEAD CITY", "FORT MOHAVE", "FT MOHAVE", "MOHAVE VALLEY", "GOLDEN VALLEY",
             "DOLAN SPRINGS", "COLORADO CITY", "BEAVER DAM", "LITTLEFIELD", "GOLDEN SHORES", "PEACH SPRINGS", "WHITE HILLS", "KINGMAN",
             "MEADVIEW", "TOPOCK", "OATMAN", "CHLORIDE", "HACKBERRY", "VALENTINE", "WIKIEUP", "YUCCA", "TRUXTON", "SCENIC", "NEEDLES"]


def _moh_addr(parts):
    """['3146 STOCKTON HILL RD,', 'KINGMAN AZ 86401'] -> ('3146 STOCKTON HILL RD', 'Kingman', '86401')."""
    a = re.sub(r"\s+", " ", " ".join(parts)).strip()
    z = (re.search(r"\b(8[56]\d{3})\b", a) or [None, ""])[1]
    a = re.sub(r",?\s*\b(?:AZ|AX|ARIZONA)\b\.?,?\s*(?:\d{5}(?:-\d{4})?)?\s*$", "", a, flags=re.I).strip(" ,")
    city = None
    for t in MOH_TOWNS:
        m = re.search(rf"(?:,\s*|\s+){t}$", a, flags=re.I)
        if m:
            city, a = t, a[:m.start()]
            break
    if city is None and "," in a:
        a, _, city = a.rpartition(",")
    city = {"LHC": "LAKE HAVASU CITY", "LAKE HAVASU": "LAKE HAVASU CITY", "FT MOHAVE": "FORT MOHAVE"}.get((city or "").strip().upper(), city)
    street = re.split(r",\s*(?:STE|SUITE|UNIT|#|BLDG|SPACE|SP)\b", a, flags=re.I)[0]
    return street.strip(" ,"), canon_city(city.strip()) if city and city.strip() else None, z


def _mohave_frame():
    d = pd.DataFrame(_mohave_parse())
    if d.empty:
        return d
    d["d"] = pd.to_datetime(d.date, format="%m/%d/%y", errors="coerce").dt.strftime("%Y-%m-%d")
    parsed = d.addr.map(_moh_addr)
    d["street"], d["city"], d["zip"] = parsed.str[0], parsed.str[1], parsed.str[2]
    d["desc"] = d.desc.str.replace(r"^\d{4}-?\s*", "", regex=True)   # 2025 lists prefix the permit class code ("1003- Type III - Complex")
    # the county's own rating word(s); a doubled cell ("Excellent Excellent", two rows run together) keeps its first rating
    d["band"] = d.rating.str.upper().str.extract(r"(EXCELLENT|SATISFACTORY|NEEDS IMPROVEMENT|UNACCEPTABLE)")[0].str.title()
    d.loc[d.rating.str.upper().str.strip().eq("CLOSED"), "band"] = "Closed"
    d = d[d.d.between("2024-12-01", pd.Timestamp.today().strftime("%Y-%m-%d"))]   # typed dates outside the lists' span (2020, 2036)
    d["est"] = "MOH-" + d.name.str.upper().str.replace(r"\W+", " ", regex=True).str.strip() + "|" + d.street.str.upper() + "|" + d.desc.str.upper()
    return d


MOH_FOOD = re.compile(r"FOOD SERVICE|^TYPE I|BAR/LOUNGE|BAR LOUNGE|BAKERY|RESTAURANT", re.I)


def load_mohave():
    d = _mohave_frame()
    rows = []
    if d.empty:
        return pd.DataFrame(rows)
    for est, g in d.sort_values("d").groupby("est", sort=False):
        r = g.iloc[-1]
        desc = r.desc or ""
        kind = ("bar" if desc.upper().startswith("BAR/LOUNGE") else "food") if MOH_FOOD.search(desc) and not re.search(r"MOBILE|SCHOOL|SATELLITE|INSTITUTION", desc, re.I) \
            else ("retail" if "RETAIL" in desc.upper() else "other")
        x = _row("moh", est, r["name"], r.street, r.city, r.zip, np.nan, np.nan, kind,
                 active=g.d.max() >= "2025-04-01", ltype=desc.title())
        x["county"] = "Mohave"
        rows.append(x)
    return pd.DataFrame(rows)


def mohave_inspections():
    """One row per inspection in the county's monthly lists: establishment (name + address + permit type), date and the county's own
    rating (Excellent / Satisfactory / Needs Improvement; N/A for retail-only permits). Oldest first."""
    d = _mohave_frame()
    out = pd.DataFrame({"lic": d.est, "d": d.d, "score": np.nan, "band": d.band, "typ": "", "re": False})
    return out[out.band.notna()].sort_values(["lic", "d"]).reset_index(drop=True)


def load():
    df = pd.concat([load_maricopa(), load_tucson(), load_pinal(), load_mohave()], ignore_index=True)
    # one business can hold several records (a TABC license and a city inspection): same address and a name in common
    df["biz"] = np.arange(len(df))
    town = df.city.fillna("").str.upper().str.strip()
    for num, g in df[df.num.notna() & df.street.notna()].groupby("num"):
        idx = list(g.index)
        if len(idx) < 2 or len(idx) > 400:
            continue
        for x in range(len(idx)):
            for y in range(x + 1, len(idx)):
                a, b = idx[x], idx[y]
                if not street_compat(df.at[a, "street"], df.at[b, "street"]):
                    continue
                if not ((df.at[a, "zip"] and df.at[a, "zip"] == df.at[b, "zip"]) or (town[a] and town[a] == town[b])):
                    continue
                ka, kb = df.at[a, "keys"], df.at[b, "keys"]
                if not ka or not kb:
                    continue
                if any(name_sim(p, q) >= 85 or ((_stems(p) - GENERIC) & (_stems(q) - GENERIC)) for p in ka for q in kb):
                    old, new = df.at[b, "biz"], df.at[a, "biz"]
                    df.loc[df.biz == old, "biz"] = new
    return df




# ---------------------------------------------------------------- Yavapai County: Golden Plate Award (yearly announcement PDF)
GOLDEN_PLATE_URL = "https://www.yavapaiaz.gov/files/sharedassets/public/v/1/resident-services/community-health/documents/2025-golden-plate-announcement-mixed-cities.pdf"
GOLDEN_PLATE_PAGE = "https://www.yavapaiaz.gov/News-articles/Golden-Plate-Awards-2025"


def golden_plate(year=2025):
    """Yavapai County's Golden Plate Award list: a whole calendar year with no cited priority or priority-foundation violation, an
    approved food safety plan and a certified person in charge (the county's criteria). Three columns of town headings ("▪ Prescott")
    and names, in two risk categories (Complex, Moderate); "4*" before a name = years in a row. Returns name, towns, category, streak."""
    import pdfplumber
    out = []
    with pdfplumber.open(f"{OFF}/yavapai/{year}-golden-plate.pdf") as pdf:
        for pg in pdf.pages:
            ws = pg.extract_words()
            lines = {}
            for w in ws:
                lines.setdefault(round(w["top"]), []).append(w)
            cats = sorted((t, " ".join(w["text"] for w in sorted(l, key=lambda w: w["x0"]))) for t, l in lines.items()
                          if any(w["text"] == "Category:" for w in l))
            if not cats:
                continue
            foot = min([w["top"] for w in ws if w["text"] == "asterisk"] + [10_000]) - 2
            town = None
            for k, (t0, ctext) in enumerate(cats):
                t1 = min(cats[k + 1][0] if k + 1 < len(cats) else 10_000, foot)
                cat = (re.search(r"Category:\s*(\w+)", ctext) or [None, None])[1]
                for lo, hi in ((0, 210), (210, 398), (398, 10_000)):   # a column's first names continue the previous column's town
                    col = {}
                    for w in ws:
                        if t0 + 5 < w["top"] < t1 - 2 and lo <= w["x0"] < hi:
                            col.setdefault(round(w["top"]), []).append(w)
                    for t in sorted(col):
                        text = " ".join(w["text"] for w in sorted(col[t], key=lambda w: w["x0"])).strip()
                        if not re.search(r"[A-Za-z]", text):
                            continue
                        if town and town.endswith("/") and not text.startswith("▪"):   # "▪ Black Canyon City /" + "Crown King"
                            town = f"{town} {text}"
                            continue
                        if text.startswith("▪"):
                            town = text.lstrip("▪ ").strip()
                            continue
                        m = re.match(r"^(\d+)\*\s*(.+)$", text)
                        out.append({"name": (m.group(2) if m else text).strip(), "streak": int(m.group(1)) if m else 1,
                                    "towns": town, "category": cat, "year": year})
    return pd.DataFrame(out)
