#!/usr/bin/env python3
"""Fetch official prayer timetables for SalahTimes' validation.

Standard library only. Reads sources.json next to this script and writes one CSV per source:

    date,fajr,sunrise,dhuhr,asr,maghrib,isha
    2026-01-01,06:50,08:22,13:12,15:32,17:53,19:19

Times are the authority's local wall-clock times, 24-hour HH:MM. Sources whose terms allow
redistribution ("committed": true) go to data/, which is committed. All others go to the cache
directory, which is gitignored.

Usage:
    python3 fetch.py                      # every source
    python3 fetch.py jakim-wly01 ...      # only these ids
    python3 fetch.py --cache /some/dir    # cache directory (default: ./cache)

Be polite: the script waits between requests and makes about 25 in total.
"""

import argparse
import csv
import html
import http.cookiejar
import json
import os
import re
import ssl
import sys
import time
import urllib.parse
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
USER_AGENT = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/130 Safari/537.36 salah-kit-validation"
)
PAUSE_SECONDS = 1.5
COLUMNS = ["date", "fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha"]

TURKISH_MONTHS = {
    "Ocak": 1, "Şubat": 2, "Mart": 3, "Nisan": 4, "Mayıs": 5, "Haziran": 6,
    "Temmuz": 7, "Ağustos": 8, "Eylül": 9, "Ekim": 10, "Kasım": 11, "Aralık": 12,
}
MALAY_MONTHS = {
    "Jan": 1, "Feb": 2, "Mac": 3, "Apr": 4, "Mei": 5, "Jun": 6,
    "Jul": 7, "Ogo": 8, "Ogos": 8, "Sep": 9, "Okt": 10, "Nov": 11, "Dis": 12,
}
ENGLISH_MONTHS = {
    "Jan": 1, "Feb": 2, "Mar": 3, "Apr": 4, "May": 5, "Jun": 6,
    "Jul": 7, "Aug": 8, "Sep": 9, "Oct": 10, "Nov": 11, "Dec": 12,
}


class Client:
    def __init__(self):
        self.jar = http.cookiejar.CookieJar()
        self.opener = urllib.request.build_opener(
            urllib.request.HTTPCookieProcessor(self.jar),
            urllib.request.HTTPSHandler(context=tls_context()))

    def request(self, url, data=None, headers=None):
        time.sleep(PAUSE_SECONDS)
        body = urllib.parse.urlencode(data).encode() if data is not None else None
        request = urllib.request.Request(url, data=body, headers={"User-Agent": USER_AGENT})
        for key, value in (headers or {}).items():
            request.add_header(key, value)
        with self.opener.open(request, timeout=90) as response:
            raw = response.read()
            if response.headers.get("Content-Encoding") == "gzip":
                import gzip
                raw = gzip.decompress(raw)
            return raw.decode("utf-8", errors="replace")


def tls_context():
    """The default TLS context, falling back to the system's CA bundle.

    The python.org installer for macOS ships without CA certificates until its "Install
    Certificates" step runs; /etc/ssl/cert.pem holds the system's roots.
    """
    context = ssl.create_default_context()
    paths = ssl.get_default_verify_paths()
    has_default = (paths.cafile and os.path.exists(paths.cafile)) or (
        paths.capath and os.path.isdir(paths.capath) and os.listdir(paths.capath))
    if not has_default and not os.environ.get("SSL_CERT_FILE") and os.path.exists(
            "/etc/ssl/cert.pem"):
        context.load_verify_locations("/etc/ssl/cert.pem")
    return context


def hhmm(text):
    """Normalizes '6:06', '06:06' or '06:06:00' to '06:06'."""
    match = re.fullmatch(r"\s*(\d{1,2}):(\d{2})(?::\d{2})?\s*", text)
    if not match:
        raise ValueError(f"not a time: {text!r}")
    return f"{int(match.group(1)):02d}:{match.group(2)}"


def strip_tags(text):
    return html.unescape(re.sub(r"<[^>]+>", " ", text)).split()


def fetch_diyanet(client, source):
    """Diyanet's page shows the next 30 days and a yearly table for the following year.

    The 2026 yearly table is only on copies of the page from 2026, so it comes from the
    Internet Archive's unmodified copy (the id_ form) of the page as of early January 2026.
    The live page's 30-day table is used to check that the archived values are still current.
    """
    spec = source["fetch"]
    archived = client.request(
        f"https://web.archive.org/web/{spec['snapshot']}id_/{spec['page']}")
    rows = parse_diyanet_table(archived, "table-caption-yearly")
    rows = [row for row in rows if row[0].startswith(str(spec["year"]))]
    live = client.request(spec["page"])
    live_rows = {row[0]: row for row in parse_diyanet_table(live, "table-caption-monthly")}
    overlap = [row for row in rows if row[0] in live_rows]
    changed = [row[0] for row in overlap if live_rows[row[0]] != row]
    print(f"  live 30-day table overlaps {len(overlap)} archived days; {len(changed)} differ"
          + (f": {changed}" if changed else ""))
    return rows


def parse_diyanet_table(page, caption_id):
    start = page.find(caption_id)
    if start < 0:
        raise ValueError(f"no table {caption_id}")
    end = page.find("</table>", start)
    rows = []
    for row in re.findall(r"<tr>(.*?)</tr>", page[start:end], re.S):
        cells = [" ".join(strip_tags(cell)) for cell in re.findall(r"<td>(.*?)</td>", row, re.S)]
        if len(cells) != 8:
            continue
        day, month_name, year = cells[0].split()[:3]
        date = f"{int(year):04d}-{TURKISH_MONTHS[month_name]:02d}-{int(day):02d}"
        # Columns: Gregorian date, Hijri date, imsak (Fajr), sunrise, Dhuhr, Asr, Maghrib, Isha.
        rows.append([date] + [hhmm(cell) for cell in cells[2:8]])
    return rows


def fetch_jakim(client, source):
    zone = source["fetch"]["zone"]
    body = json.loads(client.request(
        "https://www.e-solat.gov.my/index.php?r=esolatApi/takwimsolat&period=year&zone=" + zone))
    rows = []
    for day in body["prayerTime"]:
        # Dates such as "01-Mac-2026" use Malay month abbreviations.
        day_text, month_text, year_text = day["date"].split("-")
        date = f"{int(year_text):04d}-{MALAY_MONTHS[month_text]:02d}-{int(day_text):02d}"
        rows.append([date] + [hhmm(day[key]) for key in
                              ("fajr", "syuruk", "dhuhr", "asr", "maghrib", "isha")])
    return rows


def fetch_datagovsg(client, source):
    resource = source["fetch"]["resource"]
    body = json.loads(client.request(
        "https://data.gov.sg/api/action/datastore_search?resource_id=" + resource + "&limit=400"))
    rows = []
    for day in body["result"]["records"]:
        rows.append([day["Date"]] + [hhmm(day[key]) for key in
                                     ("Subuh", "Syuruk", "Zohor", "Asar", "Maghrib", "Isyak")])
    return rows


def fetch_ummalqura(client, source):
    spec = source["fetch"]
    query = urllib.parse.urlencode({
        "lang": "en", "format": "24", "yg": spec["year"],
        "lat": source["latitude"], "lon": source["longitude"], "zone": spec["zone"],
    })
    body = json.loads(client.request(
        "https://umqserv.kacst.gov.sa/api/v1/Prayer/GetPrayerByYear?" + query,
        headers={"Origin": "https://www.ummulqura.org.sa",
                 "Referer": "https://www.ummulqura.org.sa/"}))
    rows = []
    for day in body:
        g = day["gregorianDate"]
        times = day["prayerTimes"]
        rows.append([f"{g['year']:04d}-{g['month']:02d}-{g['day']:02d}"]
                    + [hhmm(times[key]) for key in
                       ("fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha")])
    return rows


def fetch_kemenag(client, source):
    spec = source["fetch"]
    # The first visit only sets the session cookie; the province list appears on the second.
    provinces = {}
    for _ in range(2):
        page = client.request("https://bimasislam.kemenag.go.id/jadwalshalat")
        provinces = dict((name.strip(), value) for value, name in
                         re.findall(r'<option value="([0-9a-f]{32})">([^<]+)', page))
        if spec["province"] in provinces:
            break
    if spec["province"] not in provinces:
        raise ValueError("the province list is missing from the page")
    province = provinces[spec["province"]]
    cities_html = client.request(
        "https://bimasislam.kemenag.go.id/ajax/getKabkoshalat", data={"x": province})
    cities = dict((name.strip(), value) for value, name in
                  re.findall(r'<option value="([0-9a-f]{32})">([^<]+)', cities_html))
    city = cities[spec["city"]]
    rows = []
    for month in range(1, 13):
        body = json.loads(client.request(
            "https://bimasislam.kemenag.go.id/ajax/getShalatbln",
            data={"x": province, "y": city, "bln": month, "thn": spec["year"]}))
        if body.get("status") != 1:
            raise ValueError(f"month {month}: {body.get('message')}")
        for date, day in sorted(body["data"].items()):
            rows.append([date] + [hhmm(day[key]) for key in
                                  ("subuh", "terbit", "dzuhur", "ashar", "maghrib", "isya")])
    return rows


def fetch_moonsighting(client, source):
    spec = source["fetch"]
    query = urllib.parse.urlencode({
        "year": spec["year"], "tz": source["timeZone"], "lat": source["latitude"],
        "lon": source["longitude"], "method": spec["method"], "both": "false", "time": 0,
    })
    page = client.request("https://www.moonsighting.com/praytable.php?" + query)
    rows = []
    for row in re.findall(r"<tr[^>]*>(.*?)</tr>", page, re.S):
        cells = strip_tags(row)
        if len(cells) != 9 or cells[0] not in ENGLISH_MONTHS:
            continue
        date = f"{spec['year']:04d}-{ENGLISH_MONTHS[cells[0]]:02d}-{int(cells[1]):02d}"
        rows.append([date] + [hhmm(cell) for cell in cells[3:9]])
    return rows


FETCHERS = {
    "diyanet": fetch_diyanet,
    "jakim": fetch_jakim,
    "datagovsg": fetch_datagovsg,
    "ummalqura": fetch_ummalqura,
    "kemenag": fetch_kemenag,
    "moonsighting": fetch_moonsighting,
}


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("ids", nargs="*", help="source ids from sources.json (default: all)")
    parser.add_argument("--cache", default=os.path.join(HERE, "cache"),
                        help="directory for data that can't be redistributed")
    args = parser.parse_args()

    with open(os.path.join(HERE, "sources.json"), encoding="utf-8") as file:
        sources = json.load(file)["sources"]
    selected = [s for s in sources if not args.ids or s["id"] in args.ids]
    unknown = set(args.ids) - {s["id"] for s in sources}
    if unknown:
        parser.error(f"unknown ids: {sorted(unknown)}")

    client = Client()
    failures = 0
    for source in selected:
        if source["fetch"]["kind"] == "awqaf-export":
            print(f"{source['id']}: optional public-page export; use import-awqaf.py (README.md)")
            continue
        directory = os.path.join(HERE, "data") if source["committed"] else args.cache
        os.makedirs(directory, exist_ok=True)
        path = os.path.join(directory, source["file"])
        print(f"{source['id']}:")
        try:
            rows = FETCHERS[source["fetch"]["kind"]](client, source)
        except Exception as error:  # Report and continue with the other sources.
            failures += 1
            print(f"  FAILED: {error}", file=sys.stderr)
            continue
        rows.sort()
        with open(path, "w", newline="", encoding="utf-8") as file:
            writer = csv.writer(file, lineterminator="\n")
            writer.writerow(COLUMNS)
            writer.writerows(rows)
        print(f"  {len(rows)} days, {rows[0][0]} to {rows[-1][0]} -> {path}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
