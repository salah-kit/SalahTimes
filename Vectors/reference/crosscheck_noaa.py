"""Compares every vector's sunrise, sunset and transit with NOAA's solar calculator code.

NOAA's Solar Calculator (https://gml.noaa.gov/grad/solcalc/) runs in the browser from main.js.
This script runs that file's calculation functions in Node.js for the coordinates and day of
every unrounded prayer-time vector below 65° of latitude that gives its parameters in full (not
by `method`), for its sunrise, sunset and Dhuhr when they have no adjustment, and reports the
differences from the vectors' expected values. NOAA's code is an implementation of the same
Meeus series written by someone else, so agreement checks the reference's arithmetic, its
transit selection and its iteration, though not the choice of series.

NOAA's sunrise and sunset use a 90.833° zenith, the same -50' altitude as SalahTimes. Its solar
noon function evaluates the equation of time a day early, so this script computes noon itself
from NOAA's `calcEquationOfTime` at the noon instant.

Usage:
    curl -o /tmp/noaa-main.js https://gml.noaa.gov/grad/solcalc/main.js
    python3 Vectors/reference/crosscheck_noaa.py /tmp/noaa-main.js
"""

import calendar
import glob
import json
import os
import re
import subprocess
import sys
import tempfile
from datetime import datetime, timezone

DRIVER = r"""
const cases = JSON.parse(require('fs').readFileSync(process.argv[2], 'utf8'));
const out = [];
for (const [lat, lon, y, m, d] of cases) {
  const jd = getJD(y, m, d);
  const rise = calcSunriseSetUTC(1, jd, lat, lon);
  const set = calcSunriseSetUTC(0, jd, lat, lon);
  const rise2 = calcSunriseSetUTC(1, jd + rise / 1440, lat, lon);
  const set2 = calcSunriseSetUTC(0, jd + set / 1440, lat, lon);
  let noon = 720 - 4 * lon;
  for (let i = 0; i < 3; i++) {
    noon = 720 - 4 * lon - calcEquationOfTime(calcTimeJulianCent(jd + noon / 1440));
  }
  out.push({rise: isFinite(rise2) ? rise2 : null, set: isFinite(set2) ? set2 : null, noon});
}
console.log(JSON.stringify(out));
"""


def extract_functions(main_js):
    """The calculation functions of main.js, between its calculation-section comments."""
    with open(main_js, encoding="utf-8") as handle:
        text = handle.read()
    start = text.index("function calcTimeJulianCent")
    end = text.index("function dayString")
    return text[start:end]


def params_dhuhr_adjusted(adjusted):
    return bool(adjusted.get("dhuhr"))


def parse_instant(text):
    return calendar.timegm(datetime.strptime(text, "%Y-%m-%dT%H:%M:%SZ").timetuple())


def main(main_js):
    vectors_dir = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
    rows = []
    for path in sorted(glob.glob(os.path.join(vectors_dir, "times", "*.json"))):
        with open(path, encoding="utf-8") as handle:
            for vector in json.load(handle)["vectors"]:
                params = vector["input"].get("parameters", {})
                if "method" in vector["input"] or params.get("rounding") != "none":
                    continue
                adjusted = {**params.get("methodAdjustments", {}), **params.get("adjustments", {})}
                rows.append((vector, adjusted))
    # One NOAA case per vector and event. NOAA's functions take a UTC day and find the events
    # around that day's noon at the longitude, so each vector uses the UTC day that contains its
    # transit shifted by the longitude (local mean solar time). Near the date line that's not
    # the civil day.
    jobs = []
    for vector, adjusted in rows:
        c = vector["input"]["coordinates"]
        if abs(c["latitude"]) > 65:
            continue  # NOAA's two-step rise and set isn't meant for near-polar days
        for event, key in (("sunrise", "rise"), ("sunset", "set"), ("dhuhr", "noon")):
            expected = vector["expected"][event]
            if adjusted.get(event) or not isinstance(expected, str):
                continue
            instant = parse_instant(expected)
            transit = parse_instant(vector["expected"]["dhuhr"])
            if params_dhuhr_adjusted(adjusted):
                transit -= 60 * adjusted["dhuhr"]
            day = datetime.fromtimestamp(transit + c["longitude"] * 240, timezone.utc)
            jobs.append((vector["id"], event, key, instant,
                         [c["latitude"], c["longitude"], day.year, day.month, day.day]))
    with tempfile.TemporaryDirectory() as scratch:
        script = os.path.join(scratch, "noaa.js")
        data = os.path.join(scratch, "cases.json")
        with open(script, "w", encoding="utf-8") as handle:
            handle.write(extract_functions(main_js) + DRIVER)
        with open(data, "w", encoding="utf-8") as handle:
            json.dump([job[4] for job in jobs], handle)
        output = json.loads(subprocess.check_output(["node", script, data]))
    # NOAA's code has no ΔT, so its events are off by about ΔT / 365 seconds: a quarter of a
    # second today, but about 5 s in the year 1000 and 14 s in 3000. So modern and historical
    # years are reported apart.
    groups = ("1900-2100", "other years")
    worst = {(g, e): (0, "") for g in groups for e in ("sunrise", "sunset", "dhuhr")}
    compared = {key: 0 for key in worst}
    for (vector_id, event, key, instant, case), noaa in zip(jobs, output):
        if noaa[key] is None:
            continue
        midnight = calendar.timegm((case[2], case[3], case[4], 0, 0, 0))
        diff = instant - (midnight + noaa[key] * 60)
        diff = (diff + 43200) % 86400 - 43200
        group = groups[0] if 1900 <= case[2] <= 2100 else groups[1]
        compared[(group, event)] += 1
        if abs(diff) > abs(worst[(group, event)][0]):
            worst[(group, event)] = (diff, vector_id)
    for (group, event), (diff, vector_id) in worst.items():
        if compared[(group, event)]:
            print(f"{group}, {event}: {compared[(group, event)]} compared, largest difference "
                  f"{diff:+.1f} s ({vector_id})")


if __name__ == "__main__":
    main(sys.argv[1])
