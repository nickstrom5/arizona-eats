"""Download the Overture Maps extracts that arizona.py reads -> data/az/

- overture_az_bbox.parquet     every place in Arizona's bounding box (name, category, address, point)
- overture_az_sources.parquet  which datasets each Arizona eating/drinking listing came from (Meta, Foursquare, ...)
- az_shapes.json               simplified state and county outlines for the map
- az_state_detail.geojson      the state outline at full detail, for the in-state test

Reads the public Overture bucket over S3 with DuckDB (no account needed). Adapted from wi-eats/pipeline/fetch_overture.py
(Arizona: the Gulf shoreline comes from the land division areas).
"""
import os, json, time
import duckdb
from shapely import wkb
from shapely.geometry import mapping, Polygon

RELEASE = "2026-10-21.0"
OUT = os.path.join(os.path.dirname(__file__), "..", "data", "az")
# Arizona (31.33°N–37.0°N, 109.05°W–114.82°W) plus a margin for border towns
BBOX = "bbox.xmin BETWEEN -114.9 AND -108.95 AND bbox.ymin BETWEEN 31.25 AND 37.05"
EAT = "('restaurant','casual_eatery','bar','fast_food_restaurant','coffee_shop','cafe','smoothie_juice_bar','brewery','food_court')"
os.makedirs(OUT, exist_ok=True)

con = duckdb.connect()
con.execute("INSTALL httpfs; LOAD httpfs; INSTALL spatial; LOAD spatial; SET s3_region='us-west-2';")
places = f"s3://overturemaps-us-west-2/release/{RELEASE}/theme=places/type=place/*.parquet"

t = time.time()
if not os.path.exists(f"{OUT}/overture_az_bbox.parquet"):
    con.execute(f"""
COPY (
  SELECT id, names.primary AS name, basic_category AS cat, taxonomy.primary AS tax, taxonomy.hierarchy AS hier, confidence,
         operating_status AS status, brand.names.primary AS brand, addresses[1].freeform AS street, addresses[1].locality AS city,
         addresses[1].postcode AS zip, addresses[1].region AS region, ST_Y(geometry) AS lat, ST_X(geometry) AS lon, websites[1] AS web,
         phones[1] AS phone
  FROM read_parquet('{places}', hive_partitioning=1) WHERE {BBOX}
) TO '{OUT}/overture_az_bbox.parquet' (FORMAT PARQUET)""")
    print("places in bbox", round(time.time() - t), "s", flush=True)
if not os.path.exists(f"{OUT}/overture_az_sources.parquet"):
    con.execute(f"""
COPY (
  SELECT id, list_transform(sources, x -> x.dataset) AS ds, list_transform(sources, x -> x.update_time) AS ut,
         list_transform(sources, x -> x.record_id) AS rid,
         len(socials) AS n_soc, len(websites) AS n_web, len(phones) AS n_ph
  FROM read_parquet('{places}', hive_partitioning=1)
  WHERE {BBOX} AND basic_category IN {EAT}
) TO '{OUT}/overture_az_sources.parquet' (FORMAT PARQUET)""")
    print("sources", round(time.time() - t), "s", flush=True)

areas = f"s3://overturemaps-us-west-2/release/{RELEASE}/theme=divisions/type=division_area/*.parquet"
rows = con.execute(f"""
  SELECT subtype, names.primary AS name, ST_AsWKB(geometry) AS g
  FROM read_parquet('{areas}', hive_partitioning=1)
  WHERE country = 'US' AND region = 'US-AZ' AND subtype IN ('region', 'county') AND class = 'land'
    AND bbox.xmin > -115.5 AND bbox.xmax < -108.5 AND bbox.ymin > 31 AND bbox.ymax < 37.5""").fetchall()


def rings(geom, tol, min_area):
    geom = geom.simplify(tol, preserve_topology=True)
    polys = [p for p in getattr(geom, "geoms", [geom]) if p.geom_type == "Polygon" and p.area >= min_area]
    return [[[round(x, 3), round(y, 3)] for x, y in p.exterior.coords] for p in polys]


out = {"state": None, "counties": []}
for sub, name, g in rows:
    geom = wkb.loads(bytes(g)).buffer(0)
    if sub == "region":
        json.dump(mapping(geom.simplify(0.0005, preserve_topology=True)), open(f"{OUT}/az_state_detail.geojson", "w"))
        out["state"] = [[r] for r in rings(geom, 0.002, 0.0002)]
    else:
        out["counties"].append({"name": name, "c": rings(geom, 0.004, 0.0005)})
# full-detail county polygons for assigning each place to a county (not shipped)
json.dump({name: mapping(wkb.loads(bytes(g)).buffer(0).simplify(0.0003, preserve_topology=True))
           for sub, name, g in rows if sub == "county"}, open(f"{OUT}/az_counties_detail.geojson", "w"))
json.dump(out, open(f"{OUT}/az_shapes.json", "w"), separators=(",", ":"))
print("outlines: state", len(out["state"] or []), "rings +", len(out["counties"]), "counties;", round(time.time() - t), "s total")
