#!/usr/bin/env python3
"""Import an official Awqaf public prayer-page JSON response into the private CSV cache.

Usage: python3 import-awqaf.py <source-id> <response.json> <new-output.csv>

The response is obtained from the public Awqaf prayer page's date-range request. No API
key, account credential, or source data belongs in this repository. See README.md.
"""

import argparse
import csv
import datetime
import json
import pathlib
import re

HERE = pathlib.Path(__file__).resolve().parent
COLUMNS = ["date", "fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha"]
FIELDS = ["fajer", "shuroq", "dhohur", "aser", "maghreb", "isha"]


def rows_from_response(source, response):
    """Validate location identity, official provenance, calendar coverage and wall times."""
    if response.get("errors"):
        raise ValueError("the service returned errors")
    result = response["result"]
    metadata = result["meta_data"]
    location = metadata["location"]
    specification = source["fetch"]
    if str(location["CountryID"]) != "224":
        raise ValueError("the response is not for the United Arab Emirates")
    if str(location["official_id"]) != str(specification["officialId"]):
        raise ValueError("the response has the wrong official city id")
    if metadata["method"]["official"] is not True:
        raise ValueError("the response is calculated rather than official published times")
    year = specification["year"]
    first = datetime.date(year, 1, 1)
    last = datetime.date(year + 1, 1, 1)
    expected = {
        first + datetime.timedelta(days=index) for index in range((last - first).days)
    }
    days = {}
    for record in result["prayer_times"]:
        date = datetime.date.fromisoformat(record["date"])
        # The API contract uses ISO dates. Reject noncanonical input instead of silently
        # assigning it to a different row or accepting Python's compact ISO spelling.
        if record["date"] != date.isoformat():
            raise ValueError("date must use YYYY-MM-DD")
        if date in days:
            raise ValueError("duplicate date: " + date.isoformat())
        if date not in expected:
            raise ValueError("date is outside the requested year: " + date.isoformat())
        times = [record[field] for field in FIELDS]
        if not all(isinstance(value, str) and re.fullmatch(
                r"(?:[01][0-9]|2[0-3]):[0-5][0-9]", value) for value in times):
            raise ValueError("times must use 24-hour HH:MM")
        if times != sorted(times) or len(set(times)) != len(times):
            raise ValueError("prayers are not strictly ordered: " + date.isoformat())
        days[date] = [date.isoformat()] + times
    if set(days) != expected:
        raise ValueError("response does not cover every day of the requested year")
    return [days[date] for date in sorted(days)]


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("source_id")
    parser.add_argument("response", type=pathlib.Path)
    parser.add_argument("output", type=pathlib.Path)
    args = parser.parse_args()
    sources = json.loads((HERE / "sources.json").read_text())["sources"]
    source = next((value for value in sources if value["id"] == args.source_id), None)
    if source is None or source.get("fetch", {}).get("kind") != "awqaf-export":
        parser.error("source_id must identify an Awqaf export in sources.json")
    rows = rows_from_response(source, json.loads(args.response.read_text()))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    # Exclusive creation preserves earlier comparisons and original downloads.
    with args.output.open("x", newline="", encoding="utf-8") as stream:
        writer = csv.writer(stream, lineterminator="\n")
        writer.writerow(COLUMNS)
        writer.writerows(rows)
    print(f"{source['id']}: {len(rows)} complete, validated days -> {args.output}")


if __name__ == "__main__":
    main()
