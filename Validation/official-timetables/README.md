# Official timetables

SalahTimes compared with timetables that the authorities behind its methods publish.

| File | What it is |
|---|---|
| `sources.json` | Every timetable: authority, place, reference coordinates and why, time zone, the SalahTimes method it's compared with, URLs, licence, and how `fetch.py` gets it |
| `fetch.py` | Downloads the timetables (Python 3 standard library only) and writes one CSV per source |
| `data/` | Timetables whose terms allow redistribution, committed |
| `cache/` | Everything else, gitignored |
| `results.md` | The latest comparison, written by the test |

The comparison is `Tests/SalahTimesTests/OfficialTimetableTests.swift`. `docs/validation.md` interprets the results.

## Reproduce

```sh
python3 Validation/official-timetables/fetch.py
SALAHTIMES_OFFICIAL_TIMETABLES=$PWD/Validation/official-timetables/cache \
SALAHTIMES_OFFICIAL_RESULTS=$PWD/Validation/official-timetables/results.md \
  swift test -j 4 --filter OfficialTimetable
```

Delete `results.md` first: the test appends to it. Without `SALAHTIMES_OFFICIAL_TIMETABLES`, only the committed timetables (MUIS) are compared.

`fetch.py` makes about 25 requests, 1.5 seconds apart. If Python can't verify TLS certificates (the python.org installer for macOS ships without them), it falls back to `/etc/ssl/cert.pem`.

## Sources

All data was retrieved on 2026-10-13. Every source covers all 365 days of 2026.

| Source | Authority | Data | Redistributable |
|---|---|---|---|
| `diyanet-istanbul`, `diyanet-ankara` | Diyanet, Turkey | The yearly table on namazvakitleri.diyanet.gov.tr. Today the live page shows 2027's table and the next 30 days, so the 2026 table comes from the Internet Archive's unmodified copy of the page from 2 January 2026. `fetch.py` checks it against the live 30-day table: all 31 overlapping days agree. | No terms stated; cached only |
| `jakim-wly01` | JAKIM, Malaysia | The e-Solat API's yearly timetable for zone WLY01 (Kuala Lumpur, Putrajaya) | No terms stated; cached only |
| `muis-singapore` | MUIS, Singapore | data.gov.sg dataset "Muslim Prayer Timetable 2026" (`d_d441e7242e78efc566024dd5b0d9829c`) | Yes: Singapore Open Data Licence 1.0; committed with attribution |
| `ummalqura-makkah`, `ummalqura-riyadh` | Umm al-Qura calendar (KACST), Saudi Arabia | The yearly prayer-time service behind ummulqura.org.sa/prayer-times, for the coordinates in the site's own city list | No terms stated; cached only |
| `kemenag-jakarta` | Kemenag (Bimas Islam), Indonesia | bimasislam.kemenag.go.id/jadwalshalat, Kota Jakarta, one request per month | No terms stated; cached only |
| `moonsighting-london-hanafi`, `moonsighting-london-shafi` | Moonsighting Committee Worldwide | moonsighting.com/praytable.php for London, methods 0 (Hanafi, shafaq general) and 2 (Shafi'i) | No terms stated; cached only |

The MUIS data's attribution: Contains information from Muslim Prayer Timetable 2026 accessed on 13 October 2026 from data.gov.sg, which is made available under the terms of the Singapore Open Data Licence version 1.0 (https://data.gov.sg/open-data-licence).

### Reference coordinates

Only the Umm al-Qura service and moonsighting.com compute for coordinates you give them; for those the comparison uses the same coordinates, so any offset is the method's. Diyanet, JAKIM, MUIS and Kemenag publish one timetable per province, zone or country without saying which point it's computed for, and often compute for an extreme point of the zone so that no part of it prays early. For those the comparison uses the usual coordinates of the city centre, and a constant offset can come from the reference point as well as from precautionary minutes. `sources.json` records the coordinates and the reason for each.

### Tried and not used

- **UAE (awqaf.gov.ae)**: the prayer-times page is a single-page app whose API paths are obfuscated in its JavaScript bundle. Not pursued.
- **Qatar (islam.gov.qa)**: the site's API sits behind a service gateway that needs a client id, secret and token. Not pursued.
- **Kuwait (islam.gov.kw)**: the host doesn't resolve.
- **Diyanet's own calculation site (vakithesaplama.diyanet.gov.tr)** needs an account for its tables, and its API (awqatsalah.diyanet.gov.tr) needs registration. The public namazvakitleri pages were used instead.
- **Egypt**: no official machine-readable timetable found; not attempted further.
