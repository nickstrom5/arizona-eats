"""Pinal County Environmental Health food inspections -> data/raw/official/pinal/<year>-<class>.json

The county's own search (app1.pinal.gov/search/foodinspection-search.aspx; robots.txt allows it, no CAPTCHA) lists every
inspection by official rating class: E Excellent, S Satisfactory, N Needs Improvement, U Unacceptable, 10 rows per page. One search
per class and year, then its pages in order, one request at a time 3 s apart (Nick's yes 2026-10-22, ~600-900 requests). No
per-inspection detail pages are fetched. Resumable: a finished class/year file is skipped.
"""
import html, json, os, re, sys, time
import requests

U = "https://app1.pinal.gov/search/foodinspection-search.aspx"
OUT = os.path.join(os.path.dirname(__file__), "..", "data", "raw", "official", "pinal")
os.makedirs(OUT, exist_ok=True)
s = requests.Session()
s.headers["User-Agent"] = "ArizonaEatsBuild/1.0 (+nick@eatsranked.com)"
ROW = re.compile(r"FoodInspection-Details\.aspx\?id=([\d.]+)\">(.*?)</a></td><td>(.*?)</td><td>(.*?)</td><td>(.*?)</td><td>(.*?)</td>", re.S)


def fields(h):
    return {m.group(1): html.unescape(m.group(2))
            for m in re.finditer(r'<input type="hidden" name="([^"]+)" id="[^"]+" value="([^"]*)"', h)}


def post(d):
    for attempt in range(4):
        try:
            time.sleep(3)
            r = s.post(U, data=d, timeout=120)
            r.raise_for_status()
            return r.text
        except requests.RequestException as e:
            print("retry", e, flush=True)
            time.sleep(30 * (attempt + 1))
    raise SystemExit("Pinal search not answering")


def rows(h):
    return [dict(id=m.group(1), name=html.unescape(m.group(2)).strip(), date=m.group(3), rating=m.group(4),
                 address=html.unescape(m.group(5)).strip(), city=html.unescape(m.group(6)).strip()) for m in ROW.finditer(h)]


for year in ("2026", "2025"):
    for cls in "ESNU":
        path = f"{OUT}/{year}-{cls}.json"
        if os.path.exists(path):
            continue
        h = s.get(U, timeout=60).text
        d = fields(h); d.update(ddlSearchType="RATING CLASS", __EVENTTARGET="ddlSearchType")
        h = post(d)
        base = dict(ddlSearchType="RATING CLASS", ddlRatingClass=cls, ddlRatingClassYear=year)
        d = fields(h); d.update(base, btnRatingClass="Search"); d.pop("__EVENTTARGET", None)
        h = post(d)
        out, page = rows(h), 1
        while f"Page${page + 1}'" in html.unescape(h):
            page += 1
            d = fields(h); d.update(base, __EVENTTARGET="gvRatingClass", __EVENTARGUMENT=f"Page${page}")
            h = post(d)
            got = rows(h)
            if not got:
                break
            out += got
            if page % 25 == 0:
                print(year, cls, "page", page, len(out), flush=True)
        json.dump({"year": year, "class": cls, "fetched": time.strftime("%Y-%m-%d"), "pages": page, "rows": out}, open(path, "w"))
        print(year, cls, "done", page, "pages", len(out), "rows", flush=True)
