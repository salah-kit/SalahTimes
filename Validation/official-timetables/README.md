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
| `test_fetch.py`, `test_import_awqaf.py` | Unit tests for the fetchers and the Awqaf importer, run in CI |

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

`fetch.py` makes about 110 requests, 1.5 seconds apart, most of them one per month for Kemenag, the Survey Authority and Banuri Town. If Python can't verify TLS certificates (the python.org installer for macOS ships without them), it falls back to `/etc/ssl/cert.pem`.

## Sources

All data was retrieved on 2026-10-13. Every source covers all 365 days of 2026.
The optional UAE sources were added on 2026-10-14, and the second set of Diyanet, JAKIM and
Kemenag places (Izmir, Van, PNG01, JHR02, SBH07, Surabaya, Medan, Makassar) and the University of
Tehran's, Egypt's Survey Authority's and Banuri Town's timetables on 2026-10-18.

| Source | Authority | Data | Redistributable |
|---|---|---|---|
| `diyanet-istanbul`, `diyanet-ankara`, `diyanet-izmir`, `diyanet-van` | Diyanet, Turkey | The yearly table on namazvakitleri.diyanet.gov.tr. Today the live page shows 2027's table and the next 30 days, so the 2026 table comes from the Internet Archive's unmodified copy of the page from 2 January 2026 (Istanbul, Ankara), 27 January 2026 (Izmir) or 21 April 2026 (Van). Van's only 2026 copy is filed under a truncated address of the same page, which `archivedPage` names. `fetch.py` checks each against the live 30-day table: all 31 overlapping days agree. | No terms stated; cached only |
| `jakim-wly01`, `jakim-png01`, `jakim-jhr02`, `jakim-sbh07` | JAKIM, Malaysia | The e-Solat API's yearly timetable for zones WLY01 (Kuala Lumpur, Putrajaya), PNG01 (Pulau Pinang), JHR02 (Johor Bahru) and SBH07 (Kota Kinabalu) | No terms stated; cached only |
| `muis-singapore` | MUIS, Singapore | data.gov.sg dataset "Muslim Prayer Timetable 2026" (`d_d441e7242e78efc566024dd5b0d9829c`) | Yes: Singapore Open Data Licence 1.0; committed with attribution |
| `ummalqura-makkah`, `ummalqura-riyadh` | Umm al-Qura calendar (KACST), Saudi Arabia | The yearly prayer-time service behind ummulqura.org.sa/prayer-times, for the coordinates in the site's own city list | No terms stated; cached only |
| `kemenag-jakarta`, `kemenag-surabaya`, `kemenag-medan`, `kemenag-makassar` | Kemenag (Bimas Islam), Indonesia | bimasislam.kemenag.go.id/jadwalshalat, Kota Jakarta, Kota Surabaya, Kota Medan and Kota Makassar, one request per month | No terms stated; cached only |
| `moonsighting-london-hanafi`, `moonsighting-london-shafi` | Moonsighting Committee Worldwide | moonsighting.com/praytable.php for London, methods 0 (Hanafi, shafaq general) and 2 (Shafi'i) | No terms stated; cached only |
| `ut-tehran` | Calendar Centre, Institute of Geophysics, University of Tehran, Iran | The Institute's yearly PDF timetables for Tehran on calendar.ut.ac.ir, for the Persian years 1404 and 1405, which together cover 2026. `fetch.py` reads the day numbers and times from the PDFs' compressed text with the standard library, and checks the month lengths and the weekday cycle; each PDF's first Gregorian day is in `sources.json`. The timetable gives no Asr or Isha, so those columns are empty. | No licence; the site reserves all rights. Cached only |
| `esa-cairo` | Egyptian General Authority for Survey | esa.gov.eg/monthlymwaket.aspx: the form is posted back for Cairo and then each month. The page serves only the current year, so the 2026 table must be fetched during 2026. Times include Egypt's summer time. | Copying is forbidden except for private, non-commercial use; cached only |
| `banuri-karachi` | Jamia Uloom-ul-Islamia Allama Banuri Town, Pakistan | banuri.edu.pk/namaz-times for Karachi, the Jamia's own method (`method=1`) with Hanafi Asr (`time_method=1`), one request per month. The request names no year. | No terms stated; cached only |
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

Only the Umm al-Qura service and moonsighting.com compute for coordinates you give them, and only the University of Tehran states the coordinates of its timetable; for those the comparison uses the same coordinates, so any offset is the method's. JAKIM's zone WLY01 is computed for reference stations the Federal Territories Mufti publishes, one for the prayers and one for sunrise, and the comparison uses both (`sunriseLatitude` and `sunriseLongitude` give the second). Diyanet, MUIS, Kemenag, the Survey Authority, Banuri Town and JAKIM's other zones publish one timetable per province, zone, city or country without saying which point it's computed for, and often compute for an extreme point of the zone so that no part of it prays early. For those the comparison uses the usual coordinates of the city centre, and a constant offset can come from the reference point as well as from precautionary minutes. `sources.json` records the coordinates and the reason for each.

### Tried and not used

- **UAE (awqaf.gov.ae)**: the earlier obfuscated-page limitation is superseded by the
  2026-10-14 official public-page exports and optional importer above.
- **Qatar:** the `islam.gov.qa` service gateway requires registered credentials. The alternative
  [Qatar Calendar House releases archive](https://qatarch.com/dar-releases) is public and its
  image-based daily-card PDFs supplied a complete 2025 year on 2026-10-14. The dated OCR
  comparison is described in `docs/validation.md`; it is separate from `fetch.py`'s 2026
  machine-readable sources. On 2026-10-18 the archive covered 2026 up to 11 October; the
  1447 months are images and the 1448 months text PDFs, and the site reserves all rights, so
  2026 is compared in [issue #5](https://github.com/salah-kit/SalahTimes/issues/5) rather than
  here. An exact published reference coordinate/rounding specification was not obtained. No
  preset fit is inferred from missing specifications.
- **Kuwait:** islam.gov.kw refuses connections. Kuwait's official calendar is the Al-Ojeiri
  Scientific Centre's, and https://alojeiri.com/ar/ojeiri-calendar returns a day per request
  without a key, but its terms forbid using or copying the site's content without written
  permission. Its 2026 year is compared in issue #5 and not fetched here.
- **Diyanet's own calculation site (vakithesaplama.diyanet.gov.tr)** needs an account for its tables, and its API (awqatsalah.diyanet.gov.tr) needs registration. The public namazvakitleri pages were used instead.
- **Brunei, Algeria:** the Ministries' timetables (mora.gov.bn's "Waktu Sembahyang" list,
  marw.gov.dz's image-only yearly PDFs) cover 2026, but their terms forbid copying or storing
  them without permission. They're compared in issue #5.
- **Jordan:** awqaf.gov.jo's date search fails on the server, so the page lists only today to
  31 December. **Tunisia:** affaires-religieuses.tn returns only the current day. Neither can
  give a whole year; what they gave is compared in issue #5.
- **ISNA, Bangladesh, Afghanistan:** ISNA publishes no timetable beyond a Ramadan 2026 image
  for its headquarters, the Islamic Foundation Bangladesh only a permanent table of six days a
  month from about 1992, and Afghanistan's Ministry a single image. They're compared in
  issue #5.
