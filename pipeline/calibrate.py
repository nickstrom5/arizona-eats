"""How often is a map listing a real, permitted or inspected food business? Measured where official lists exist -> data/az/calibration*.json

Adapted from co-eats/pipeline/calibrate.py (via tx-eats).
- Maricopa County: against every issued food permit (the county's "Restaurant (External)" list: fixed FD permits; mobile MF too).
  The county permits every food business outside tribal land, so this is the full test (two-thirds of Arizona's restaurants).
- Mohave County: against every establishment the county inspected Jan 2025 - Sep 2026 (monthly lists). Most permits get an
  inspection in 21 months; the rest lower the rate a little.
- Pinal County: against every establishment in the county's inspection search for 2025-26 (same caveat).
- Tucson (city limits): against active City of Tucson business licenses with a NAICS 722 code. Not every license carries the code,
  so this is a lower bound.
A match is the same business name nearby, or the same street address with a distinctive name word in common.
"""
import json
import numpy as np, pandas as pd
from shapely.geometry import shape, Point
from shapely.prepared import prep
from common import AZ
from listings_util import official_match

o = pd.read_pickle(f"{AZ}/stage1.pkl")
F = pd.read_pickle(f"{AZ}/official.pkl")
from shapely import STRtree
_CN = json.load(open(f"{AZ}/az_counties_detail.geojson"))
_NAMES = list(_CN)
_GEOMS = [shape(_CN[n]).buffer(0.0003) for n in _NAMES]
_TREE = STRtree(_GEOMS)


def county_of(la, lo):
    if la != la:
        return None
    p = Point(lo, la)
    for i in _TREE.query(p):
        if _GEOMS[i].contains(p):
            return _NAMES[i]
    return None


o["county"] = [county_of(la, lo) for la, lo in zip(o.lat, o.lon)]
# every list is one county's; a placed record keeps the county its point falls in only when that is its own county
OWN = {"mcp": "Maricopa County", "tus": "Pima County", "pin": "Pinal County", "moh": "Mohave County"}
F["county"] = [OWN[j] for j in F.jur]
o.to_pickle(f"{AZ}/stage1.pkl")
F.to_pickle(f"{AZ}/official.pkl")
base = ~o.j_junk & ~o.j_outside
print("listings with a county:", int(o.county.notna().sum()), "of", len(o))


def groups(L, app=False):
    s = L.src.fillna("none")
    if app:
        conf = L.confidence.fillna(0)
        return np.select([L.ov_closed | L.j_closedname, (s == "meta") & (conf >= 0.95), (s == "meta") & (conf >= 0.9),
                          s.isin(["AllThePlaces", "DAC"]), (s == "BrightQuery") & (conf >= 0.95), s == "meta"],
                         ["closed per Overture/name", "meta_high", "meta_mid", "brand_feed", "bq_high", "meta_low"], "other_sources")
    return np.select([L.closed21, L.ov_closed, (s == "meta") & L.in21, s == "meta", s.isin(["AllThePlaces", "DAC"]) & L.in21,
                      s.isin(["AllThePlaces", "DAC"]), L.in21, s == "Foursquare", s == "BrightQuery", s == "Microsoft"],
                     ["Google 2021 says closed", "Overture says closed", "Meta + open in Google 2021", "Meta only",
                      "brand feed + Google 2021", "brand feed only", "Foursquare/BrightQuery/Microsoft + Google 2021",
                      "Foursquare only", "BrightQuery only", "Microsoft only"], "other")


AREAS = {"Maricopa County": ("Maricopa County", F.jur.eq("mcp") & F.active, "mcp"),
         "Tucson": ("Pima County", F.jur.eq("tus") & F.active, "tus"),
         "Mohave County": ("Mohave County", F.jur.eq("moh") & F.active, "moh"),
         "Pinal County": ("Pinal County", F.jur.eq("pin") & F.active, "pin")}
res, app = {}, {}
for label, (cty, sel, own) in AREAS.items():
    L = o[base & (o.county == cty)].reset_index(drop=True)
    R = F[sel & (F.county == cty)].reset_index(drop=True)
    if not len(R):
        print(f"\n== {label}: no official records yet"); continue
    if own == "tus":   # city limits only
        L = L[L.city.eq("Tucson")].reset_index(drop=True)
    m = official_match(L, R)
    L["hit"] = L.index.map(lambda i: i in m)
    L["hit_food"] = L.index.map(lambda i: i in m and R.kind.iat[m[i]] in ("restaurant", "bar", "brewery", "food"))
    for mode, store in ((False, res), (True, app)):
        L["grp"] = groups(L, mode)
        t = L.groupby("grp").agg(n=("id", "size"), official=("hit", "mean"), food=("hit_food", "mean")).sort_values("n", ascending=False)
        print(f"\n== {label} ({'app grouping' if mode else 'web grouping'}): {len(L)} listings, {len(R)} official records")
        print(t.assign(official=(t.official * 100).round(1), food=(t.food * 100).round(1)).to_string())
        store[label] = {"listings": int(len(L)), "official_records": int(len(R)),
                        "groups": {g: {"n": int(r.n), "official": round(float(r.official), 3), "food": round(float(r.food), 3)} for g, r in t.iterrows()}}
    # the other direction: how many official restaurants/bars do the (cleaned, open) map listings hold?
    keepish = ~(L.ov_closed | L.j_closedname | L.closed21)
    got = set(R.biz.iloc[[m[i] for i in L.index[keepish] if i in m]])
    Rr = R[(R.jur == own) & R.kind.isin(["restaurant", "bar", "food"])].drop_duplicates("biz")
    cover = float(np.mean([b in got for b in Rr.biz])) if len(Rr) else None
    print(f"{label}: official food businesses found among open map listings: {cover*100:.1f}% of {len(Rr)}")
    res[label]["coverage"] = round(cover, 3)
    res[label]["official_food"] = int(len(Rr))

per = o[base & o.county.notna() & ~o.ov_closed & ~o.j_closedname].groupby("county").size()
print("\n== open, cleaned listings per county\n" + per.sort_values(ascending=False).to_string())
json.dump({"areas": res, "per_county_listings": {c: int(n) for c, n in per.items()}}, open(f"{AZ}/calibration.json", "w"), indent=1)
json.dump(app, open(f"{AZ}/calibration_app.json", "w"), indent=1)
