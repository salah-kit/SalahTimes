# Validating SalahTimes

How SalahTimes' results were checked, what the checks found, and how to repeat them. The numbers are from 2026-10-13, and those for the official timetables added or recomputed on 2026-10-18 from that day, with Swift 6.4 on an Apple M2 Pro (macOS), with the engine of commit `8a32a5e` and the final method presets.

## Summary

- **Astronomy.** At every computed event, an independent solar model (NOAA's equation-of-time formulation) puts the Sun within 0.013° of the altitude that defines the event, and within 0.013° of hour angle (3.1 seconds of time) of the meridian at Dhuhr. That covers 30,952 crossings at latitudes from 60° S to 60° N.
- **adhan-swift.** All eight of adhan-swift's timetables agree within one minute for every prayer, except three prayer columns in two files, on three days in all. adhan-swift's own tests allow two minutes for those two files. Every exception is explained below.
- **Official timetables.** Twenty 2026 timetables from nine authorities, 365 days each. moonsighting.com's London times agree with the `moonsightingCommittee` preset to the minute on 91–97% of days for every prayer but Asr (74–78%), with mean offsets under 0.05 minutes. Diyanet (Istanbul, Ankara, Izmir, Van) and Umm al-Qura (Makkah, Riyadh) agree within a minute on 90–100% of days, and all their mean offsets are 0 or ±0.5 minutes, which is rounding. Kemenag (Jakarta, Surabaya, Medan, Makassar) and MUIS (Singapore) agree within a minute on 99–100% of days. JAKIM's zone WLY01, at its published reference stations, is within a minute of the `jakim` preset on 89–100% of days and runs about half a minute later on average, as rounding up gives; zones PNG01, JHR02 and SBH07, compared at their main cities because their stations weren't found, run about 1 to 1.5 minutes later. The University of Tehran's Institute of Geophysics publishes Fajr, sunrise, Dhuhr and Maghrib for Tehran, and the `tehran` preset gives its minute on 98–99% of days and is never more than a minute off. Egypt's General Authority for Survey (Cairo) and Jamia Uloom-ul-Islamia Banuri Town (Karachi, Hanafi Asr) are within a minute of the `egyptian` and `karachi` presets on every day.
- **Properties.** Events stay in order, change smoothly from day to day, give the same instants with or without daylight saving time, behave as algorithm.md §9 says in polar day and polar night, stay on their civil day at the equator and the date line, and mirror between the hemispheres within 8 seconds. In the Tehran method at 60° and beyond, Maghrib and Isha can be the same instant, as specified (see Known limitations).
- **Speed.** A day's events take about 9 to 11 µs in a release build and 22 to 26 µs in a debug build, depending on the machine's load. 48 hours (three days) take about 28 to 31 µs in release.

The validation found no engine bugs. One was fixed before these numbers were taken: before commit `8a32a5e`, a crossing that came within minutes of the transit or antitransit at the edge of a season, or near a pole, could swing between two instants or settle on a neighboring day's transit, up to 24 hours off. Asr in the days before polar night was the case these checks saw, seconds off, which moved some rows of the wide scan. Section 6 of algorithm.md now bisects such crossings, and every number here is from the fixed engine. An earlier run, against the presets before their research was final, found that the `jakim` preset's Fajr angle was outdated (20° instead of 18°) and that the `muis` and `kemenag` presets lacked their authorities' precautionary minutes and upward rounding. The final presets fix all three, and every number below is from them.

## Astronomy cross-checks

`SelfConsistencyTests.swift` has its own solar model, written from NOAA's "General Solar Position Calculations" and the NOAA Solar Calculator spreadsheet (https://gml.noaa.gov/grad/solcalc/calcdetails.html). Its formulation differs from the engine's:

| | Engine (algorithm.md §4) | Test model (NOAA) |
|---|---|---|
| Time scale | UT for sidereal time, TT (with ΔT) for the Sun | UT throughout |
| Hour angle | Apparent sidereal time minus right ascension, plus longitude | True solar time from the equation of time |
| Root finding | Newton-style iteration on the hour angle | Bisection on the altitude |

The model reproduces Meeus's worked examples: the apparent declination of example 25.a (−7.78507° on 1992-10-13) within 0.002°, and the equation of time of example 28.b (13 min 42.6 s) within 6 seconds.

Both models use the same series for the Sun's longitude (Meeus chapter 25), so this check is
independent in the hour angle, the time scale and the root finding, not in the solar theory.
The independent JPL comparison below now covers that boundary. It is a dated research
comparison, separate from the committed NOAA unit tests. USNO still refused a connection on
2026-10-14; JPL Horizons was accessible. An earlier one-off comparison also found larger
errors near polar transitions, 30–82 seconds, where very shallow solar motion amplifies an
altitude difference. Those transition cases are outside the newer grid.

### Independent JPL Horizons comparison (2026-10-14)

[JPL Horizons](https://ssd-api.jpl.nasa.gov/doc/horizons.html) returned DE441 solar
ephemerides for 48 site-days: 12 cities in both hemispheres and at the date line, on the
March equinox, June solstice, September equinox and December solstice of 2026. The northern
limit was Reykjavík (64.15°), the southern limit Ushuaia (54.80° S). All 144 unrounded
sunrise, transit and sunset events were compared. The inputs, every measured difference and
the exact first-query parameters are in
[`Validation/ephemeris/jpl-2026-10-14.json`](../Validation/ephemeris/jpl-2026-10-14.json).

| Event | Comparisons | Largest absolute difference |
|---|---:|---:|
| Sunrise | 48 | 3.31 seconds |
| Transit | 48 | 1.53 seconds |
| Sunset | 48 | 5.19 seconds |

SalahTimes used `rounding: .none`, no method/user minutes and no high-latitude bounds.
Horizons used an Earth topocentric geodetic site at zero elevation, airless apparent solar
altitude and local apparent hour angle. Sunrise/sunset solve the same fixed −50′ centre
altitude that SalahTimes specifies, rather than adding a second refraction correction;
transit solves hour angle zero. Its
[quantity definitions](https://ssd.jpl.nasa.gov/horizons/manual.html) describe these observables.
Five samples bracket each event. A second JPL query at the interpolated crossing and ±1
second verifies the result; its largest correction was 0.012 seconds. JPL's predicted Earth
orientation after 2026-10-13 applies to the December samples. This supports ordinary solar
event accuracy on the stated grid; it does not validate twilight policy, elevation,
near-pole/near-transition reliability, or exact published mosque minutes.

## adhan-swift parity

**Data.** The eight timetables in adhan-swift's `Tests/Resources/Times/` at commit `a6fa2de` (MIT licence), copied to `Tests/Data/adhan-swift/` with the licence and a README. Several say they were "adjusted +/- 1 or 2 minutes" by adhan-swift's authors to agree with their library.

**Method.** `AdhanParityTests.swift` maps each file's method to the SalahTimes preset: UmmAlQura to `ummAlQura`, Turkey to `diyanet`, Singapore to `muis`, MoonsightingCommittee to `moonsightingCommittee`, and Dubai, Qatar, Kuwait and Tehran to the presets of the same name. It takes the file's madhab and high-latitude rule, computes every listed day, and compares each prayer with the file's local time.

**Results.** The largest difference per prayer, in minutes:

| File | Days | Fajr | Sunrise | Dhuhr | Asr | Maghrib | Isha |
|---|---:|---:|---:|---:|---:|---:|---:|
| Ankara-Turkey | 24 | 1 | 1 | 1 | 1 | 1 | **2** |
| Doha-Qatar | 12 | 0 | 0 | 0 | 1 | 0 | 0 |
| Dubai-Gulf | 12 | 1 | 1 | 1 | 1 | 1 | 1 |
| Kuwait City-Kuwait | 12 | **2** | **2** | 1 | 1 | 1 | 1 |
| London-MoonsightingCommittee | 12 | 0 | 0 | 0 | 1 | 0 | 0 |
| Makkah-UmmAlQura | 12 | 0 | 0 | 0 | 1 | 0 | 0 |
| Singapore-Singapore | 366 | 1 | 1 | 1 | 1 | 1 | 1 |
| Tehran-Tehran | 12 | 0 | 0 | 0 | 1 | 0 | 1 |

The test lists each difference over a minute in `knownDifferences`, with a two-minute limit and its reason. It also fails if a listed difference disappears, so the list can't go stale.

- **Ankara, Isha (2 days of 24).** Diyanet's Isha isn't exactly the Sun at 17°. On 2019-05-01 Diyanet publishes 21:18 and SalahTimes computes 21:19:37; on 2019-09-01, 20:52 against 20:50:16. The 2026 Diyanet comparison below shows the same spread, about ±1.9 minutes, around a mean of zero.
- **Kuwait, Fajr and sunrise (1 day of 12).** The 2016-03-01 row is about 1.6 minutes later than the Sun for both Fajr (04:56 against 04:54:27) and sunrise (06:15 against 06:13:24). The other eleven days agree within a minute. It looks like an irregularity in the source table, which adhan-swift's authors also adjusted.
adhan-swift's own tests allow two minutes (their `variance` key) for these two files, and for Singapore, so adhan-swift doesn't reproduce them within a minute either. Singapore agreed only within two minutes before the `muis` preset was fitted to MUIS's timetables (one Dhuhr minute, rounding up); it now agrees within one minute on all 366 days. Dubai agrees within one minute with the final `dubai` preset.

## Official timetables

**Sources.** Nine authorities, twenty timetables, every day of 2026, retrieved on 2026-10-13. The second set of Diyanet, JAKIM and Kemenag places and the University of Tehran's, the Survey Authority's and Banuri Town's timetables were retrieved on 2026-10-18. `Validation/official-timetables/README.md` and `sources.json` give the URLs, the reference coordinates and why they were chosen, and the licences.

| Timetable | Where the data came from | Reference coordinates |
|---|---|---|
| Diyanet, Istanbul, Ankara, Izmir and Van | namazvakitleri.diyanet.gov.tr. The 2026 yearly tables come from the Internet Archive's copies of 2 January 2026 (Istanbul, Ankara), 27 January 2026 (Izmir) and 21 April 2026 (Van), because the live pages now show 2027. In each, the 31 days that overlap the live 30-day table are identical. | City centres; Diyanet doesn't publish its reference points |
| JAKIM, zones WLY01, PNG01, JHR02 and SBH07 | e-solat.gov.my API | WLY01: its published reference stations, Kg. Gedangsa for the prayers and Cheras for sunrise. The others: George Town, Johor Bahru and Kota Kinabalu, as their stations weren't found |
| MUIS, Singapore | data.gov.sg, "Muslim Prayer Timetable 2026" | Island centre; not published |
| Umm al-Qura, Makkah and Riyadh | The service behind ummulqura.org.sa/prayer-times | Exact: the site's own city list |
| Kemenag, Kota Jakarta, Kota Surabaya, Kota Medan and Kota Makassar | bimasislam.kemenag.go.id/jadwalshalat | City centres; not shown |
| moonsighting.com, London | praytable.php, methods 0 (Hanafi, shafaq general) and 2 (Shafi'i, shafaq ahmer) | Exact: the coordinates requested |
| University of Tehran, Institute of Geophysics, Tehran | The Institute's yearly PDF timetables on calendar.ut.ac.ir for the Persian years 1404 and 1405. They give Fajr, sunrise, Dhuhr, sunset, Maghrib and midnight, and no Asr or Isha. | Exact: the coordinates each PDF states, 35.70° N, 51.42° E |
| Egyptian General Authority for Survey, Cairo | esa.gov.eg/monthlymwaket.aspx, the current year's monthly tables. They include Egypt's summer time. | Central Cairo; not published |
| Jamia Uloom-ul-Islamia Banuri Town, Karachi | banuri.edu.pk/namaz-times, the Jamia's own method with Hanafi Asr, one request per month | City centre; not published |

Only MUIS's data may be redistributed (Singapore Open Data Licence 1.0). It's committed with
attribution, and its comparison runs in every test run. The others stay in a gitignored cache,
and their comparison runs when `SALAHTIMES_OFFICIAL_TIMETABLES` points at it. The UAE's official 2026 calendars, added on 2026-10-14, are compared below. Qatar Calendar House's
accessible 2025 daily-card PDFs also permit a complete dated comparison, described below.
Kuwait's official calendar, the Al-Ojeiri Scientific Centre's, is compared in issue #5 instead,
because its terms don't allow copying it. Comparisons with other
authorities' timetables are welcome: see [issue #5](https://github.com/salah-kit/SalahTimes/issues/5).

**Results.** These are the official time minus SalahTimes' unrounded time, in minutes. "Exact" and "≤ 1 min" compare the preset as it ships, with its own minute adjustments and rounding, against the published minute; their ranges run over the six prayers. Full tables: `Validation/official-timetables/results.md`.

| Timetable | Fajr | Sunrise | Dhuhr | Asr | Maghrib | Isha | Exact | ≤ 1 min |
|---|---|---|---|---|---|---|---|---|
| moonsighting.com London, Hanafi | −0.01 | +0.03 | −0.03 | +0.02 | −0.01 | −0.02 | 74–97% | 100% |
| moonsighting.com London, Shafi'i | −0.01 | +0.03 | −0.03 | −0.02 | −0.01 | −0.01 | 78–97% | 100% |
| Diyanet Istanbul | +0.04 | +0.04 | +0.03 | +0.07 | +0.02 | +0.06 | 25–90% | 90–100% |
| Diyanet Ankara | +0.10 | +0.06 | +0.02 | +0.08 | +0.04 | +0.07 | 27–92% | 93–100% |
| Diyanet Izmir | −0.02 | −0.05 | −0.03 | +0.00 | −0.03 | −0.02 | 31–91% | 96–100% |
| Diyanet Van | +0.02 | −0.01 | −0.02 | +0.06 | +0.02 | +0.01 | 36–95% | 97–100% |
| Umm al-Qura Makkah | +0.52 | −0.50 | +0.52 | +0.51 | +0.50 | +0.50 | 44–51% | 100% |
| Umm al-Qura Riyadh | +0.49 | −0.47 | +0.48 | +0.53 | +0.49 | +0.49 | 41–54% | 98–100% |
| MUIS Singapore | +0.49 | +0.50 | +0.58 | +0.51 | +0.60 | +0.53 | 62–80% | 99–100% |
| Kemenag Jakarta | +0.43 | −0.23 | +0.50 | +0.45 | +0.47 | +0.44 | 25–97% | 100% |
| Kemenag Surabaya | +0.61 | −0.05 | +0.63 | +0.65 | +0.62 | +0.61 | 45–90% | 100% |
| Kemenag Medan | +0.42 | −0.27 | +0.41 | +0.42 | +0.42 | +0.42 | 20–93% | 100% |
| Kemenag Makassar | +0.56 | −0.19 | +0.52 | +0.52 | +0.55 | +0.52 | 33–98% | 100% |
| JAKIM WLY01 | +0.74 | −0.51 | +0.55 | +0.56 | +0.70 | +0.69 | 35–49% | 89–100% |
| JAKIM PNG01 | +1.22 | −1.57 | +1.14 | +1.15 | +1.16 | +1.17 | 0–6% | 44–86% |
| JAKIM JHR02 | +1.31 | +0.33 | +1.43 | +1.30 | +1.32 | +1.33 | 0–67% | 57–100% |
| JAKIM SBH07 | +1.12 | +0.04 | +1.12 | +1.06 | +1.07 | +1.05 | 0–75% | 82–100% |
| University of Tehran | −0.02 | −0.00 | −0.01 | — | −0.00 | — | 98–99% | 100% |
| Survey Authority, Cairo | −0.22 | −0.22 | −0.19 | −0.18 | −0.11 | −0.11 | 77–91% | 100% |
| Banuri Town, Karachi (Hanafi Asr) | −0.20 | −0.20 | −0.22 | −0.21 | −0.20 | −0.20 | 78–82% | 100% |

The table gives the mean offset for each prayer, measured from SalahTimes' time with the preset's minute adjustments but before rounding; the minimum and maximum are in `results.md`. A mean near +0.5 with a spread of about a minute is an authority that rounds up.

**Interpretation.**

- **moonsighting.com** computes for the coordinates given, so this is a pure method comparison: the committee's seasonal Fajr and Isha (shafaq general and ahmer), Hanafi and Shafi'i Asr, and its +5 minutes for Dhuhr and +3 for Maghrib. Every offset lies within ±0.84 minutes, the spread that rounding gives. SalahTimes reproduces the committee's own calculator. The committee's rule as finally specified (algorithm.md §8.2 and §8.4: the seasonal bound always applies, and from 55° the seventh of the night is an extra bound) changes nothing here, because London is below 55°.
- **Diyanet.** Mean offsets are under 0.1 minutes, so Diyanet rounds to the nearest minute and the `diyanet` preset's precautionary minutes (sunrise −7, Dhuhr +5, Asr +4, Maghrib +7) are right. Fajr, sunrise and Dhuhr stay within ±0.85 minutes. Maghrib and Isha spread to about ±1.9 minutes around zero, a seasonal wave rather than an offset: Diyanet's own definitions for those two aren't exactly a constant angle plus constant minutes. Within one minute: 97–99% for Maghrib and 90–93% for Isha. Izmir and Van, at the country's western and eastern ends, show the same: every mean is within ±0.06 minutes, and the same wave puts Maghrib and Isha within a minute on 96–100% of days. Van lies about 1,700 m above sea level, and its sunrise and Maghrib still average within 0.02 minutes of SalahTimes' sea-level horizon, so Diyanet doesn't correct for elevation there.
- **The University of Tehran's Institute of Geophysics** states the coordinates its Tehran timetable is computed for, so this too is a method comparison. Fajr at 17.7°, sunrise at the standard horizon, Dhuhr at the transit and Maghrib at 4.5°, with no added minutes and rounded to the nearest minute, reproduce it: every offset lies within ±0.53 minutes, every mean within 0.02, and the `tehran` preset gives the published minute on 98–99% of days and is never more than a minute off. The Institute publishes no Asr and no Isha, so the preset's 14° Isha can't be checked against it (the "—" above).
- **Egypt's General Authority for Survey** and **Jamia Uloom-ul-Islamia Banuri Town**, after which the `karachi` method is named, publish their times without reference points, so these compare at the city centres. Both reproduce their presets' definitions with nothing added: 19.5° and 17.5° in Cairo, 18° and 18° with Hanafi Asr in Karachi, Dhuhr at the transit, Maghrib at sunset and rounding to the nearest minute. Every prayer is within a minute on all 365 days, and 77–91% (Cairo) and 78–82% (Karachi) match to the minute. Every mean lies between −0.11 and −0.22 minutes. A reference point a few kilometres east of the city centre would give most of that, but not why Cairo's morning prayers run about twice as far ahead as its evening ones (about −0.22 against −0.11 minutes).
- **Umm al-Qura** also computes for the coordinates given. Every prayer averages +0.5 minutes and sunrise −0.5: Umm al-Qura rounds prayers up and sunrise down, the cautious direction for each. The Isha statistics equal Maghrib's exactly, so the published Ramadan Isha (120 minutes in the Umm al-Qura month of Ramadan, 18 February to 19 March 2026) matches `ramadanIsha: .interval(minutes: 120, hijriDayOffset: 0)` on every day. With its default nearest rounding, the `ummAlQura` preset is within a minute on 98–100% of days. `rounding: .up` for prayers would match more days exactly, but SalahTimes has no setting that rounds sunrise down while it rounds the prayers up.
- **MUIS** publishes only timetables, so the `muis` preset is fitted to them: Fajr 20°, Isha 18°, one Dhuhr minute and `rounding: .up`. Every prayer then averages +0.5 to +0.6 minutes before rounding, as upward rounding gives, and the preset matches the published minute exactly on 62–80% of days, within a minute on every day for every prayer but Asr (361 of 365 days). Before the fit (no Dhuhr minute, nearest rounding) only 41% of Dhuhrs were within a minute.
- **Kemenag** documents its rules, and the `kemenag` preset follows them: Fajr 20°, Isha 18°, Maghrib with the Sun 1° below the horizon, ihtiyat (precautionary minutes) of Fajr +2, sunrise −3, Dhuhr +3, Asr +2, Maghrib +2 and Isha +2, and rounding up. Every prayer is within a minute on all 365 days. Fajr, Dhuhr, Maghrib and Isha match exactly on 95–97% of days and Asr on 85%. Sunrise matches exactly on only 25%: its mean is −0.23 minutes, so Kemenag's sunrise sits about a quarter minute earlier than the preset's before rounding, and rounding up then gives the later minute on most days. Surabaya, Medan (north of the equator) and Makassar (Central Indonesian Time) agree the same way: every prayer within a minute on all 365 days, Fajr, Dhuhr, Asr, Maghrib and Isha exactly on 85–98% of days, and sunrise exactly on 20–45%.
- **JAKIM** documents its method, and the `jakim` preset follows it: Fajr 18° (Malaysia moved Subuh from 20° in 2019; Selangor announced it on 28 November 2019 and the other states followed: https://www.bharian.com.my/amp/rencana/komentar/2020/05/691723/bhplus), Isha 18°, and Dhuhr one minute after the transit (the Selangor Mufti's transit plus 1 min 4 s). The Federal Territories Mufti's *Bayan al-Falak* Siri ke-17 (9 August 2022), citing JUPEM's *Almanak Falak Syarie 2021*, gives zone WLY01's reference stations: Kg. Gedangsa (3° 44′ N, 101° 23′ E) for the prayers and Cheras (3° 11′ 24″ N, 101° 45′ 30″ E) for sunrise (https://www.muftiwp.gov.my/en/artikel/bayan-al-falak/5381-bayan-al-falak-siri-ke-17-kaedah-penentuan-waktu-solat). Kg. Gedangsa is in Hulu Selangor, outside the Federal Territories. At these stations the prayers average +0.55 to +0.74 minutes after the preset before rounding, and sunrise −0.51: JAKIM rounds the prayers up and sunrise down, the cautious direction for each, as Umm al-Qura does. Apart from Dhuhr's minute it adds no fixed minutes. The preset as it ships, with nearest rounding, is within a minute on 89–100% of days and never more than 2 minutes off. What's left is seasonal: Fajr in May to July, Asr in April and September, and Maghrib and Isha in November to January come later than the station alone gives, by up to about 1.5 minutes (2 for Asr). A WLY01 fit of `rounding: .up` and a user adjustment (`adjustments`) of sunrise −1, which turns rounding up into rounding down for sunrise, puts every prayer within a minute on 98–100% of days and gives the published minute on 72–96% of them (Fajr 72%, sunrise 96%, Dhuhr 95%, Asr 88%, Maghrib 79%, Isha 81%). The cached comparison runs this fit next to the preset and writes it to `results.md` ("jakim-wly01 … place-specific fit"). JAKIM doesn't document the rounding, so the preset keeps rounding to the nearest minute. At central Kuala Lumpur the same times run 1.8 to 2.0 minutes later than the preset; the reference point explains nearly all of that. Zones PNG01 (Pulau Pinang), JHR02 (Johor Bahru) and SBH07 (Kota Kinabalu) are compared at their main cities' centres, because their stations weren't found. They run later by a smaller and more uniform amount than WLY01 did at its city centre: Fajr, Dhuhr, Asr, Maghrib and Isha average +1.1 to +1.4 minutes in each zone, within a minute of the preset on 57–88% of days. Their sunrise differs from zone to zone (−1.57, +0.33 and +0.04 minutes), which a reference point away from the city centre would cause.

### Official UAE addendum (2026-10-14)

Awqaf's [public prayer page](https://www.awqaf.gov.ae/prayer-times) supplies complete 2026
Dubai and Abu Dhabi calendars through its official date-range service. The metadata marks
them as **Official Times** and identifies Dubai as official city 69 and Abu Dhabi as 36.
It withholds reference coordinates. The comparison uses usual city-centre coordinates:
25.2048, 55.2708 and 24.4539, 54.3773, in `Asia/Dubai`. The JSON importer checks city/country
identity, official provenance, every date of the year, unique days and ordered 24-hour times.
Original responses and CSVs are not redistributed. Sources and the optional import procedure
are in `Validation/official-timetables/README.md`.

Every prayer other than Asr is within a minute on all 365 days in both cities. Official Asr
minus the preset's unrounded Asr averages −2.17 minutes in Dubai (range −2.91 to −1.27)
and −2.56 in Abu Dhabi (−3.11 to −1.94). The rounded preset differs by up to three minutes;
only 11 Dubai Asr values and no Abu Dhabi Asr values are within a minute. This confirms that
the preset's 2018 Asr fit is not an exact reproduction of the 2026 calendars.

With the public `parameters.adjustments.asr = -2` override, all six prayers are within a
minute on every day in both cities. Asr matches exactly on 275 Dubai days (75%) and 169 Abu
Dhabi days (46%). The same test compares both configurations; the preset itself stays stable.
The override describes these two city-centre comparisons, not a published national rule.

### Qatar Calendar House 2025 addendum (2026-10-14)

The [Calendar House releases archive](https://qatarch.com/dar-releases) supplied 13 monthly
Hijri-calendar PDFs covering the complete Gregorian year 2025. The originals are image-based,
so an automated OCR extraction reads their printed Gregorian dates and six prayer clocks.
The extraction checks 365 unique owning dates, exactly six ordered clocks per date, and a
90-minute Maghrib-to-Isha interval on every day. It excludes cards outside 2025. The PDFs and
the extracted times aren't redistributed here, because no redistribution terms were found.
This is a numerical comparison with automated source consistency checks, not a claim that
every printed card received human visual review.

Using `qatar`, Shafi'i Asr, central Doha (25.2854, 51.5310), `Asia/Qatar`, and no Ramadan
override, the mean official-minus-unrounded offsets are −1.02 minutes for Fajr, 0.00 for
sunrise, +0.48 for Dhuhr, +0.51 for Asr and +2.07 for Maghrib and Isha. Rounded differences
are at most three minutes. Isha remains exactly Maghrib plus 90 minutes on all 365 published
rows. Turning on a 120-minute Ramadan override instead produces an Isha difference of up to
28 minutes against this table. The authority does not publish its reference coordinates or
a complete rounding/precautionary-minute rule, so no universal fit is added to the preset.
Current 2026 full-year coverage and the authority's unpublished method details remain
external-source limitations; the 2025 acquisition and comparison are complete.

## Self-consistency

`SelfConsistencyTests.swift` computes events with `rounding: .none`, no minute adjustments and `highLatitudeRule: .disabled`. It then measures the Sun's altitude at each instant with the NOAA model. The grid covers latitudes 60° S to 60° N in steps of 10°, five longitudes from 157.5° W to 106° E, the 1st and 15th of each month of 2026, and three days in 1950, 2000 and 2100. Three parameter sets: Fajr 18°, Isha 17°, Shafi'i; Fajr and Isha 15°, Hanafi; Fajr 19.5°, Isha 17.5°, Maghrib 4.5°, Shafi'i.

| Check | Expected | Largest deviation | Tolerance |
|---|---|---:|---:|
| Fajr, Isha, Maghrib angle | altitude = −angle | 0.0128° | 0.03° |
| Sunrise, sunset, Maghrib at sunset | altitude = −0.8333° | 0.0128° | 0.03° |
| Asr | cot(altitude) = madhab factor + tan(noon zenith distance) | 0.0128° | 0.03° |
| Dhuhr | hour angle = 0 | 0.0131° (3.1 s of time) | 0.03° |

In all, 30,952 crossings were checked. The tolerance comes from the models' known difference: NOAA's equation-of-time series differs from the right-ascension form by up to about 7 seconds of time, which is 0.03° of hour angle. That bounds the altitude error too, because the altitude error is at most the hour-angle error times cos φ cos δ sin H. The measured deviations are under half the tolerance.

## Properties

`PropertyTests.swift`. Every check passes.

- **Order.** The grid covers latitudes 65° S to 65° N in steps of 5° on every day of 2026, with seven presets: Muslim World League, ISNA, Egyptian, Umm al-Qura, Tehran, Moonsighting Committee and Karachi. That's 9,855 days per preset. On every day, Fajr < sunrise < Dhuhr < Asr < sunset ≤ Maghrib ≤ Isha, the middle of the night < the last third, and Isha ≤ the next day's Fajr. Equal Maghrib and Isha is allowed only beyond 48°, and it happens only with the Tehran method, as specified: 278 days at 60° and 65°, north and south (see Known limitations). Interval Isha (Umm al-Qura) never falls after the next Fajr on this grid; the wide scan below finds it from 66°.
- **Continuity.** The same grid and presets, with `rounding: .none`, give 88,938 event changes over 9,882 day pairs per preset (27 latitudes, 366 day pairs, up to 9 events each). An event's day-to-day change minus 24 hours may not exceed the fastest change, over the surrounding three day pairs, among the Sun's own crossings at that place, plus 60 seconds. The test's NOAA model computes those crossings: transit, sunrise, sunset, the method's angles and Asr. The reasoning: every SalahTimes event is a crossing, or a weighted mean of crossings with weights between 0 and 1 (`sunrise − p × night`, the night's middle), or a crossing plus an interval that changes by at most about 20 seconds a day (the committee's seasonal minutes). The 60 seconds cover that and the models' few seconds of disagreement. No event exceeded its bound. The largest change minus 24 hours was 4.0 minutes (4.9 with Tehran's Maghrib angle), at 65°. A further test moves one day's Isha by two minutes and confirms the check reports it.
- **Daylight saving time.** London, New York and Sydney were computed against UTC+0, UTC−5 and UTC+10 for every day of 2026. Instants differ by at most 2.4 × 10⁻⁷ seconds, and reasons for non-occurrence are identical. The comparison uses `rounding: .none`: with rounding, an instant within a millisecond of a half minute could round differently in the two zones. On the transition days (London 29 March and 25 October, New York 8 March and 1 November, Sydney 5 April and 4 October), Dhuhr moves by less than a minute beyond 24 hours, and every event passes the continuity bound.
- **Polar regimes.** Tromsø (69.65° N) and Longyearbyen (78.22° N), Muslim World League, Shafi'i and Hanafi, behave as algorithm.md §9 says. On 21 June, Fajr, sunrise, sunset, Maghrib, Isha and both night divisions don't occur (`sunStaysAbove`), while Dhuhr and Asr occur. On 21 December, sunrise, sunset, Maghrib, Asr and both night divisions don't occur (`sunStaysBelow`), while Dhuhr, Fajr and Isha occur, unbounded, because there's no night to bound them. On 1 May in Tromsø the Sun sets but never reaches 17° below the horizon. The seventh-of-the-night bound supplies Isha and Fajr then; with `.disabled`, both are `sunStaysAbove`. Where the hour-angle iteration can't settle on a crossing (at the edges of seasons, when an event comes within minutes of the transit or antitransit, and near the poles), the engine finds it by bisection between the transit and the antitransit (algorithm.md §6, step 3), so these results don't depend on where an oscillating iteration stops.
- **The equator and the date line.** Kiritimati (UTC+14), Apia, Adak, Quito, Singapore and Pontianak, every day of 2026: Fajr through Maghrib fall on the requested civil day in the place's zone. Dhuhr is within 3.15 seconds of the NOAA model's solar noon; the tolerance is 10 seconds.
- **Southern high latitudes.** Ushuaia (54.80° S) and Punta Arenas (53.16° S), every day of 2026. `recommended` resolves to `seventhOfTheNight` and gives the same results as setting it explicitly. Events are ordered and continuous. Each place was mirrored at the same latitude north on the day whose declination is opposite, interpolated between two days and matched by the declination's trend. Across 3,645 comparisons, each event's distance from Dhuhr matches within 7.6 seconds; the tolerance is 30 seconds.

## Benchmark

`BenchmarkTests.swift` computes three consecutive days at six places, each with its own method: Makkah, London, Jakarta, Istanbul, Tromsø and Ushuaia. That's 3,600 calls per run, on an Apple M2 Pro with Swift 6.4.

| Build | Per day (one `PrayerTimes`) | Per 48 hours (three days) | Range across places |
|---|---:|---:|---|
| Release (`-c release -Xswiftc -enable-testing`) | 10.1 µs | 30.3 µs | 9.0–11.3 µs per day |
| Debug | 24.7 µs | 74.0 µs | 23.2–26.6 µs per day |

Tromsø and London, where bounds and the Moonsighting Committee's rules apply, are the slowest. These runs shared the machine with other work (a load average near 11 on 12 cores, falling from about 40), and a second release run gave 9.8 µs per day, so the figures are upper bounds. Under a load average near 90, release runs took 10.6 to 12.9 µs per day; on a quieter machine, with the engine before commit `f4b7984`, 9.3 µs per day and 27.8 µs per 48 hours. The test's only assertion is a 50 ms ceiling.

## Known limitations

- **Presets and published timetables.** Where an authority documents its rules (Diyanet, Umm al-Qura, Kemenag, JAKIM, the Moonsighting Committee), the preset follows them and the measured differences are reported here. Where it publishes only timetables (MUIS, the UAE), the preset is fitted to them. JAKIM rounds up, which the preset doesn't, and its other zones' reference stations weren't found: PNG01, JHR02 and SBH07 run about 1 to 1.5 minutes later than the preset at their city centres. An app that needs WLY01's exact minutes can apply the fit described above.
- **Tehran at high latitudes.** Algorithm.md §8.1 bounds every angle-based evening time by the same `p`, and `seventhOfTheNight` gives 1/7 whatever the angle. So when both the 4.5° Maghrib and the 14° Isha pass the bound, they're clamped to the same instant, sunset plus a seventh of the night. This is the specified behaviour: it follows PrayTimes.org's high-latitude semantics, which bound both by the same portion of the night. They coincide but never invert: each is the earlier of its own angle's time and the shared bound, and the 4.5° time always comes before the 14° time. The order test found the tie on 278 days at 60° and 65°, and on none at 55°.
- **Interval Isha isn't bounded** (algorithm.md §8.4). On the order grid, which stops at 65°, it never falls after the next Fajr; the wide scan below finds it from 66°.
- **Beyond the order grid.** `WideScanTests.swift` scans every preset, and Umm al-Qura with the Ramadan rule's 120 minutes and `middleOfTheNight`, at every whole latitude from 66° S to 70° N, on every day of 2026. It uses two places: longitude 0 in UTC, and longitude 31.1° E in Europe/Oslo, whose clock runs behind the Sun. Its output is in `Validation/wide-scan.md`; "latitude-days" there count one latitude on one day. With times rounded as shipped, it finds these departures from strict order, all at 58° or beyond and all but Tehran's at 64° or beyond:
  - **Interval Isha after the next Fajr.** `ummAlQura` and `qatar` (90 minutes): at 66° to 70° and at 66° S (49 latitude-days at each place). With the Ramadan rule's 120 minutes and `middleOfTheNight`: from 64° in both hemispheres (190).
  - **Precautionary minutes larger than a very short night.** `diyanet`'s Fajr falls after its sunrise (sunrise −7 minutes) and its Maghrib after its Isha (Maghrib +7) at 66° to 69° and at 66° S (10 or 11 latitude-days), and they tie on a few more days. `kemenag`'s Fajr falls after its sunrise at 66°, 67°, 69° and 66° S (5 to 8). `dubai` shows both at 67° on one day. `moonsightingCommittee`'s Maghrib (+3) falls after its Isha at 67° on one day.
  - **Dhuhr and Asr before polar night.** In the last days before polar night, Asr comes only seconds to minutes after the transit, so the two can share a minute after rounding, and Dhuhr's minutes can carry it past Asr. All of it is in the northern hemisphere, except the committee's ties at 66° S. The presets without Dhuhr minutes (`muslimWorldLeague`, `isna`, `egyptian`, `ummAlQura`, `karachi`, `tehran`, `kuwait`, `qatar`, and the Umm al-Qura Ramadan setup), and `dubai` (+3), only tie: at 67° to 70° N on 5 latitude-days at longitude 0, and at 68° to 69° N on 2 at the Oslo place. `diyanet` (+5) and `jakim` (+1) tie at 67° to 69° N (4) at longitude 0 and 67° to 70° N (8) at the Oslo place, and put Dhuhr after Asr at 67° to 70° N (5) and 68° to 69° N (2), in the same order. `muis` (+1, rounding up) and `kemenag` (+3) tie at 67° to 68° N (5) at longitude 0 and 67° to 69° N (5) at the Oslo place, and put Dhuhr after Asr at 67° to 70° N (4) and at 67° and 69° to 70° N (4). `moonsightingCommittee` (+5) ties at 66° S and 66° to 68° and 70° N (17) at longitude 0, and at 66° S, 66° and 69° N (14) at the Oslo place, and puts Dhuhr after Asr at 67° to 70° N on 23 and 27 latitude-days.
  - **Maghrib and Isha tie** when both are bounded by the same portion of the night (see Tehran above): `tehran` from 58° in both hemispheres (about 1,330 latitude-days at each place), `kemenag`'s 1° Maghrib from 66° and at 66° S (33), and isolated days for `diyanet`, `dubai` and `moonsightingCommittee` between 66° and 70° and at 66° S.

  SalahTimes applies each rule as specified and never reorders events, so an app that needs strict order should check it and treat the later event of an out-of-order pair as unavailable.
- **Events before their day.** Where a place's clock runs behind its solar time, an event near solar midnight belongs to the next civil day but falls before it begins. At 31.1° E, Europe/Oslo's standard-time clock runs about an hour behind the Sun, and it keeps standard time during the southern summer, so most findings at the Oslo place are in the southern hemisphere. The wide scan finds:
  - **A Fajr near solar midnight at 45° to 48°,** where the Sun barely reaches the Fajr angle and the recommended rule's middle-of-the-night bound takes over. At the Oslo place: 47° to 48° S for `muslimWorldLeague`, `ummAlQura`, `karachi`, `diyanet`, `dubai`, `kuwait`, `qatar` and `jakim`; 48° S for `tehran`; 46° to 48° S and 48° N for `egyptian`; 46° to 48° S and 47° to 48° N for `kemenag`; 45° to 48° S and 47° to 48° N for `muis`; never for `isna` or `moonsightingCommittee`. At longitude 0 in UTC, where only the equation of time separates the clock from the Sun: 48° N and 48° S for `egyptian`, 47° to 48° S and 48° N for `muis`, and 47° to 48° S for `kemenag`; no other preset.
  - **A Fajr bounded by `middleOfTheNight` beyond 48°,** where the recommended rule wouldn't use it. In the Umm al-Qura Ramadan setup: 47° to 66° S and 49° to 70° N at the Oslo place (3,483 latitude-days), and 49° to 66° S and 49° to 70° N at longitude 0 (1,869).
  - **A bounded Fajr at 64° to 66° S and sunrise itself at 65° to 66° S,** for every preset at the Oslo place, and at neither latitude at longitude 0.
  - **`diyanet`'s sunrise,** moved 7 minutes earlier, at 67° and 69° N at the Oslo place and at 67° N at longitude 0.

  RFC 0001, decision 2, describes these events: they keep their owning day and are never moved.
- **Reference points.** Diyanet, MUIS, Kemenag, Egypt's Survey Authority and Banuri Town don't say which point their province, zone or national timetables are computed for, and JAKIM's stations were found only for WLY01. City-centre coordinates explain the means well, but part of each offset can come from the reference point.
- **Within about a degree of a pole,** the model's premise that the Sun is highest at the transit and lowest at the antitransit fails, and crossings can go unreported (algorithm.md §6). The Sun can rise and set again within one half day while SalahTimes reports `sunStaysBelow` (89.9° N, 100° E, 18 March 2026), or dip below the Asr altitude for minutes while it reports `sunStaysAbove` (89° N, 0° E, 16 April 2026), and once a year the first rise or last fall can fall in neither half of any solar day. Treat events within a degree of a pole as unreliable.
- **Elevation is ignored.** SalahTimes uses a −0.8333° horizon everywhere, as RFC 0001 decides. Authorities that correct sunrise and sunset for elevation differ at elevated places: at Van's 1,700 m, a correction for the horizon's dip would move sunrise and sunset by about 7 to 8 minutes. Diyanet's Van timetable shows no such correction.
- **adhan-swift's data was adjusted** by its authors to fit their library, so parity with it is a comparison with adhan-swift as much as with the original timetables.
- **The NOAA solar cross-check shares the Sun's longitude series** with the engine. The dated
  JPL DE441 comparison above independently checks solar theory on 48 site-days. Polar
  transitions, elevation and the near-pole limitations remain outside that evidence.
- **Linux.** The tests use only Foundation APIs available on Linux, but this validation ran on macOS only. Linux runs in CI.

## Reproducing

From the package root:

```sh
# Everything that runs without network data: parity, MUIS, self-consistency, properties,
# benchmark (debug).
swift test -j 4

# One group.
swift test -j 4 --filter AdhanParity
swift test -j 4 --filter SelfConsistency
swift test -j 4 --filter Properties

# The wide scan behind "Beyond the order grid" and "Events before their day" (under a minute).
SALAHTIMES_WIDE_SCAN=1 SALAHTIMES_WIDE_SCAN_RESULTS=$PWD/Validation/wide-scan.md \
  swift test -j 4 --filter WideScan

# Benchmark in release.
swift test -c release -Xswiftc -enable-testing -j 4 --filter Benchmark

# Official timetables: fetch the automated sources, optionally import the Awqaf exports as
# documented in Validation/official-timetables/README.md, then compare. Use a new output
# path because the serialized tests append to it. This also reports the WLY01/UAE fits.
python3 Validation/official-timetables/fetch.py
SALAHTIMES_OFFICIAL_TIMETABLES=$PWD/Validation/official-timetables/cache \
SALAHTIMES_OFFICIAL_RESULTS=$PWD/Validation/official-timetables/results-$(date +%Y%m%d-%H%M%S).md \
  swift test -j 4 --filter OfficialTimetable
```

Each test prints its numbers (parity maxima, self-consistency maxima, order and continuity counts, DST differences, mirror differences, benchmark times), and those printed numbers are the source of this document's figures. Official sites change: a later fetch may return revised timetables. `fetch.py` reports, for Diyanet, whether the archived 2026 table still matches the live page.
