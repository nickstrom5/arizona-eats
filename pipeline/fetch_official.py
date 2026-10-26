"""Official lists read through their documented ArcGIS REST APIs -> data/raw/official/*.json

- maricopa_permits.json  Maricopa County Environmental Services "Restaurant (External)" (item 4f5bfeaefa0448a584b46cbc120397ea), edited
                         daily: one row per permit and facility record (105k rows, ~29k distinct LicenseNumber). Nick's yes 2026-10-22
                         (free app, no resale; the item's licence bars commercial download or resale without a sublicense).
- tucson_licenses.json   City of Tucson "Business Licenses (Open Data)" (item b0e8f873aaeb4375b481979be334fbf2), NAICS 722 rows only.
                         ACC_NAME can be a person's name: never shown.
Paged 2,000 rows at a time, one request at a time, 1 s apart, honest user agent.
"""
import json, os, time
import requests

OUT = os.path.join(os.path.dirname(__file__), "..", "data", "raw", "official")
UA = {"User-Agent": "ArizonaEatsBuild/1.0 (+nick@eatsranked.com)"}
LAYERS = {
    "maricopa_permits": ("https://services.arcgis.com/ykpntM6e3tHvzKRJ/arcgis/rest/services/Restaurant_(External)/FeatureServer/0", "1=1"),
    "tucson_licenses": ("https://gis.tucsonaz.gov/arcgis/rest/services/PublicMaps/OpenData_EconomicDevelopment/MapServer/3", "NAIC_CODE LIKE '722%'"),
}


def fetch(url, where):
    rows, off = [], 0
    while True:
        r = requests.get(f"{url}/query", headers=UA, timeout=120, params={
            "where": where, "outFields": "*", "returnGeometry": "true", "outSR": "4326", "orderByFields": "OBJECTID",
            "resultOffset": off, "resultRecordCount": 2000, "f": "json"})
        r.raise_for_status()
        d = r.json()
        if "error" in d:
            raise RuntimeError(d["error"])
        for f in d["features"]:
            a = f["attributes"]
            g = f.get("geometry") or {}
            if "x" in g:
                a["lon"], a["lat"] = g["x"], g["y"]
            rows.append(a)
        off += len(d["features"])
        if off // 2000 % 10 == 0:
            print(" ", off, flush=True)
        if len({r["OBJECTID"] for r in rows}) < len(rows):
            raise RuntimeError("paging repeated rows")
        if not d["features"] or (not d.get("exceededTransferLimit") and len(d["features"]) < 2000):
            return rows
        time.sleep(1)


for name, (url, where) in LAYERS.items():
    meta = requests.get(f"{url}?f=json", headers=UA, timeout=60).json()
    rows = fetch(url, where)
    json.dump({"source": url, "where": where, "fetched": time.strftime("%Y-%m-%d"),
               "edited": (meta.get("editingInfo") or {}).get("dataLastEditDate"), "rows": rows},
              open(f"{OUT}/{name}.json", "w"))
    print(name, len(rows), flush=True)
