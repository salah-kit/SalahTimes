"""Compares the reference implementation with adhan-swift's published test data.

adhan-swift (MIT) ships official timetables it tests against, as local, minute-rounded times:
Tests/Resources/Times/*.json. This script runs the reference for the same places, days and
methods and reports every difference. It reads the method presets from ../methods.json when that
file exists, and otherwise from the presets of CalculationMethod.swift copied below.

Usage:
    python3 Vectors/reference/crosscheck_adhan.py /path/to/adhan-swift/Tests/Resources/Times

It prints one line per file and every difference over one minute.
"""

import json
import os
import sys
from datetime import date, datetime
from zoneinfo import ZoneInfo

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import salahtimes_reference as ref  # noqa: E402

# adhan-swift's method names, mapped to SalahTimes' method keys.
METHOD_NAMES = {
    "Turkey": "diyanet",
    "Qatar": "qatar",
    "Dubai": "dubai",
    "Kuwait": "kuwait",
    "MoonsightingCommittee": "moonsightingCommittee",
    "UmmAlQura": "ummAlQura",
    "Singapore": "muis",
    "Tehran": "tehran",
}

# The values in Sources/SalahTimes/CalculationMethod.swift, used until Vectors/methods.json lands.
FALLBACK_PRESETS = {
    "diyanet": {
        "fajr": {"angle": 18},
        "isha": {"angle": 17},
        "methodAdjustments": {"sunrise": -7, "dhuhr": 5, "asr": 4, "maghrib": 7},
    },
    "dubai": {
        "fajr": {"angle": 18.2},
        "isha": {"angle": 18.2},
        "methodAdjustments": {"sunrise": -3, "dhuhr": 3, "asr": 3, "maghrib": 3},
    },
    "kuwait": {"fajr": {"angle": 18}, "isha": {"angle": 17.5}},
    "qatar": {"fajr": {"angle": 18}, "isha": {"minutesAfterMaghrib": 90}},
    "ummAlQura": {"fajr": {"angle": 18.5}, "isha": {"minutesAfterMaghrib": 90}},
    "muis": {"fajr": {"angle": 20}, "isha": {"angle": 18}},
    "tehran": {"fajr": {"angle": 17.7}, "isha": {"angle": 14}, "maghrib": {"angle": 4.5}},
    "moonsightingCommittee": {
        "fajr": "moonsightingCommittee",
        "isha": {"moonsightingCommittee": "general"},
        "methodAdjustments": {"dhuhr": 5, "maghrib": 3},
    },
}

PRAYERS = ("fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha")


def load_presets():
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "methods.json")
    if not os.path.exists(path):
        return FALLBACK_PRESETS, "CalculationMethod.swift (copied)"
    from generate import load_methods  # noqa: PLC0415

    return load_methods(path), "Vectors/methods.json"


def minutes_of(text):
    clock, half = text.split()
    hours, minutes = (int(x) for x in clock.split(":"))
    hours %= 12
    if half == "PM":
        hours += 12
    return hours * 60 + minutes


def main(directory):
    presets, origin = load_presets()
    print(f"Presets from {origin}")
    overall = {"compared": 0, "within1": 0}
    for name in sorted(os.listdir(directory)):
        if not name.endswith(".json"):
            continue
        with open(os.path.join(directory, name), encoding="utf-8") as handle:
            data = json.load(handle)
        info = data["params"]
        key = METHOD_NAMES[info["method"]]
        params = dict(presets[key])
        params["madhab"] = info["madhab"].lower()
        params["highLatitudeRule"] = "middleOfTheNight"
        params.setdefault("rounding", "nearest")  # the preset's own rounding wins
        zone = ZoneInfo(info["timezone"])
        variance = data.get("variance", 0)
        counts = {"compared": 0, "within1": 0, "max": 0}
        histogram = {prayer: {} for prayer in PRAYERS}
        notes = []
        for row in data["times"]:
            day = date.fromisoformat(row["date"])
            result = ref.prayer_times(info["latitude"], info["longitude"], day, info["timezone"],
                                      params)
            for prayer in PRAYERS:
                value = result.events[prayer]
                local = datetime.fromtimestamp(value, zone)
                ours = local.hour * 60 + local.minute
                theirs = minutes_of(row[prayer])
                diff = ours - theirs
                counts["compared"] += 1
                counts["max"] = max(counts["max"], abs(diff))
                histogram[prayer][diff] = histogram[prayer].get(diff, 0) + 1
                if abs(diff) <= 1:
                    counts["within1"] += 1
                else:
                    notes.append(f"    {row['date']} {prayer}: ours {local:%H:%M}, "
                                 f"table {row[prayer]} ({diff:+d} min)")
        overall["compared"] += counts["compared"]
        overall["within1"] += counts["within1"]
        print(f"{name}: method {key}, {counts['compared']} times, {counts['within1']} within "
              f"1 min, max |diff| {counts['max']} min (adhan's variance {variance})")
        for prayer in PRAYERS:
            spread = ", ".join(f"{d:+d}: {n}" for d, n in sorted(histogram[prayer].items()))
            print(f"    {prayer:8} minutes ours - table -> count: {spread}")
        for note in notes[:12]:
            print(note)
        if len(notes) > 12:
            print(f"    ... and {len(notes) - 12} more over one minute")
    print(f"Total: {overall['within1']} of {overall['compared']} within 1 minute")


if __name__ == "__main__":
    main(sys.argv[1])
