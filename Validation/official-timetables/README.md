# Official timetables

SalahTimes compared with timetables that the authorities behind its methods publish.

| File | What it is |
|---|---|
| `sources.json` | Every timetable: authority, place, reference coordinates and why, time zone, the SalahTimes method it's compared with, URLs, licence, and how `fetch.py` gets it |
| `fetch.py` | Downloads the timetables (Python 3 standard library only) and writes one CSV per source |
| `import-awqaf.py` | Validates an official Awqaf public-page JSON export and imports it into the private CSV cache |
| `data/` | Timetables whose terms allow redistribution, committed |
| `cache/` | Everything else, gitignored |
| `results.md` | The latest comparison, written by the test, including a place-specific fit for JAKIM's zone WLY01 |

The comparison is `Tests/SalahTimesTests/OfficialTimetableTests.swift`. `docs/validation.md` interprets the results.

## Reproduce

```sh
python3 Validation/official-timetables/fetch.py
SALAHTIMES_OFFICIAL_TIMETABLES=$PWD/Validation/official-timetables/cache \
SALAHTIMES_OFFICIAL_RESULTS=$PWD/Validation/official-timetables/results.md \
  swift test -j 4 --filter OfficialTimetable
```

Use a new result filename for every run: the test appends to it. Without
`SALAHTIMES_OFFICIAL_TIMETABLES`, only the committed timetables (MUIS) are compared.

`fetch.py` makes about 25 requests, 1.5 seconds apart. If Python can't verify TLS certificates (the python.org installer for macOS ships without them), it falls back to `/etc/ssl/cert.pem`.

## Sources

All data was retrieved on 2026-10-13. Every source covers all 365 days of 2026.
The optional UAE sources were added on 2026-10-14.

| Source | Authority | Data | Redistributable |
|---|---|---|---|
| `diyanet-istanbul`, `diyanet-ankara` | Diyanet, Turkey | The yearly table on namazvakitleri.diyanet.gov.tr. Today the live page shows 2027's table and the next 30 days, so the 2026 table comes from the Internet Archive's unmodified copy of the page from 2 January 2026. `fetch.py` checks it against the live 30-day table: all 31 overlapping days agree. | No terms stated; cached only |
| `jakim-wly01` | JAKIM, Malaysia | The e-Solat API's yearly timetable for zone WLY01 (Kuala Lumpur, Putrajaya) | No terms stated; cached only |
| `muis-singapore` | MUIS, Singapore | data.gov.sg dataset "Muslim Prayer Timetable 2026" (`d_d441e7242e78efc566024dd5b0d9829c`) | Yes: Singapore Open Data Licence 1.0; committed with attribution |
| `ummalqura-makkah`, `ummalqura-riyadh` | Umm al-Qura calendar (KACST), Saudi Arabia | The yearly prayer-time service behind ummulqura.org.sa/prayer-times, for the coordinates in the site's own city list | No terms stated; cached only |
| `kemenag-jakarta` | Kemenag (Bimas Islam), Indonesia | bimasislam.kemenag.go.id/jadwalshalat, Kota Jakarta, one request per month | No terms stated; cached only |
| `moonsighting-london-hanafi`, `moonsighting-london-shafi` | Moonsighting Committee Worldwide | moonsighting.com/praytable.php for London, methods 0 (Hanafi, shafaq general) and 2 (Shafi'i) | No terms stated; cached only |
| `awqaf-dubai`, `awqaf-abudhabi` | UAE General Authority of Islamic Affairs, Endowments and Zakat | Official public prayer-page calendar exports, official city IDs 69 and 36, respectively | No redistribution terms stated; cached only; optional import |

### Importing official UAE public-page exports

The [public Awqaf prayer page](https://www.awqaf.gov.ae/prayer-times) requests the
`https://internationalprayertime.awqaf.gov.ae/api/v1/prayertimes` service with a JSON body:
`{"start_date":"2026-01-01","end_date":"2026-12-31","official_id":69}` for Dubai, or
`official_id:36` for Abu Dhabi. Its public frontend supplies the client header. No key or
credential is committed, and `fetch.py` does not decode frontend configuration. Preserve the
unmodified JSON response in the gitignored cache with its source URL, request dates/body,
retrieval date and SHA-256. The original 2026 responses identify country 224, the requested
official city ID, and `method.official:true`; their reference coordinates are withheld.

After acquiring the two public-page exports, import and compare them:

```sh
python3 Validation/official-timetables/import-awqaf.py awqaf-dubai \
  Validation/official-timetables/cache/dubai-response.json \
  Validation/official-timetables/cache/awqaf-dubai-2026.csv
python3 Validation/official-timetables/import-awqaf.py awqaf-abudhabi \
  Validation/official-timetables/cache/abudhabi-response.json \
  Validation/official-timetables/cache/awqaf-abudhabi-2026.csv
python3 -I -m unittest discover -s Validation/official-timetables -p 'test_*.py' -v
SALAHTIMES_OFFICIAL_TIMETABLES=$PWD/Validation/official-timetables/cache \
SALAHTIMES_OFFICIAL_RESULTS=$PWD/Validation/official-timetables/results-$(date +%Y%m%d-%H%M%S).md \
  swift test -j 4 --filter OfficialTimetable
```

The importer rejects the wrong country/city, nonofficial calculation responses, duplicates,
missing or out-of-year dates, noncanonical dates, invalid clocks and unordered prayers. It
sorts valid input and creates its output exclusively, preserving prior files. Coverage is a
whole Gregorian year, including 366 days for a leap year. The cached suite reports a missing
UAE export as optional; every previously required source still fails if absent. This permits
reproducing the older comparison without access to the newer public-page exports.

The 2026 comparison shows Asr 1–3 minutes earlier than the shipped 2018-calibrated preset.
The test also compares the local `parameters.adjustments.asr = -2` fit; all six prayers then
agree within a minute on all 365 days in both cities. This is a city-centre fit, not an
authority-published national adjustment. `docs/validation.md` records the ranges and rationale.

The MUIS data's attribution: Contains information from Muslim Prayer Timetable 2026 accessed on 13 October 2026 from data.gov.sg, which is made available under the terms of the Singapore Open Data Licence version 1.0 (https://data.gov.sg/open-data-licence).

### Reference coordinates

Only the Umm al-Qura service and moonsighting.com compute for coordinates you give them; for those the comparison uses the same coordinates, so any offset is the method's. Diyanet, JAKIM, MUIS and Kemenag publish one timetable per province, zone or country without saying which point it's computed for, and often compute for an extreme point of the zone so that no part of it prays early. For those the comparison uses the usual coordinates of the city centre, and a constant offset can come from the reference point as well as from precautionary minutes. `sources.json` records the coordinates and the reason for each.

### Tried and not used

- **UAE (awqaf.gov.ae)**: the earlier obfuscated-page limitation is superseded by the
  2026-10-14 official public-page exports and optional importer above.
- **Qatar (islam.gov.qa)**: the site's API sits behind a service gateway that needs a client id, secret and token. Not pursued.
- **Kuwait (islam.gov.kw)**: the host doesn't resolve.
- **Diyanet's own calculation site (vakithesaplama.diyanet.gov.tr)** needs an account for its tables, and its API (awqatsalah.diyanet.gov.tr) needs registration. The public namazvakitleri pages were used instead.
- **Egypt**: no official machine-readable timetable found; not attempted further.
