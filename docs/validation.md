# Validating SalahTimes

How SalahTimes' results were checked, what the checks found, and how to repeat them. The numbers are from 2026-10-13, Swift 6.4 on an Apple M2 Pro (macOS), with the engine of commit `f4b7984` and the final method presets.

## Summary

- **Astronomy.** At every computed event, an independent solar model (NOAA's equation-of-time formulation) puts the Sun within 0.013° of the altitude that defines the event, and within 0.013° of hour angle (3.1 seconds of time) of the meridian at Dhuhr. That covers 30,952 crossings at latitudes from 60° S to 60° N.
- **adhan-swift.** All eight of adhan-swift's timetables agree within one minute for every prayer, except three prayer columns in two files, on three days in all. adhan-swift's own tests allow two minutes for those two files. Every exception is explained below.
- **Official timetables.** Nine 2026 timetables from six authorities, 365 days each. moonsighting.com's London times agree with the `moonsightingCommittee` preset to the minute on 91–97% of days for every prayer but Asr (74–78%), with mean offsets under 0.05 minutes. Diyanet (Istanbul, Ankara) and Umm al-Qura (Makkah, Riyadh) agree within a minute on 90–100% of days, and all their mean offsets are 0 or ±0.5 minutes, which is rounding. Kemenag (Jakarta) and MUIS (Singapore) agree within a minute on 99–100% of days. JAKIM's zone WLY01 runs 1 to 3 minutes later than the `jakim` preset, which follows JAKIM's documented method; precautionary minutes and the zone's unpublished reference point explain the difference.
- **Properties.** Events stay in order, change smoothly from day to day, give the same instants with or without daylight saving time, behave as algorithm.md §9 says in polar day and polar night, stay on their civil day at the equator and the date line, and mirror between the hemispheres within 8 seconds. In the Tehran method at 60° and beyond, Maghrib and Isha can be the same instant, as specified (see Known limitations).
- **Speed.** A day's events take about 9 to 11 µs in a release build and 22 to 26 µs in a debug build, depending on the machine's load. 48 hours (three days) take about 28 to 32 µs in release.

No engine bugs were found. An earlier run, against the presets before their research was final, found that the `jakim` preset's Fajr angle was outdated (20° instead of 18°) and that the `muis` and `kemenag` presets lacked their authorities' precautionary minutes and upward rounding. The final presets fix all three, and every number below is from them.

## Astronomy cross-checks

`SelfConsistencyTests.swift` has its own solar model, written from NOAA's "General Solar Position Calculations" and the NOAA Solar Calculator spreadsheet (https://gml.noaa.gov/grad/solcalc/calcdetails.html). Its formulation differs from the engine's:

| | Engine (algorithm.md §4) | Test model (NOAA) |
|---|---|---|
| Time scale | UT for sidereal time, TT (with ΔT) for the Sun | UT throughout |
| Hour angle | Apparent sidereal time minus right ascension, plus longitude | True solar time from the equation of time |
| Root finding | Newton-style iteration on the hour angle | Bisection on the altitude |

The model reproduces Meeus's worked examples: the apparent declination of example 25.a (−7.78507° on 1992-10-13) within 0.002°, and the equation of time of example 28.b (13 min 42.6 s) within 6 seconds.

Both models use the same series for the Sun's longitude (Meeus chapter 25), so this check is independent in the hour angle, the time scale and the root finding, not in the solar theory. No committed test compares with an independent ephemeris. The USNO API refused connections when this report was prepared, so a comparison with it is still to do. A one-off comparison of 50 site-days with JPL Horizons, made during review and not part of the tests, found sunrise and sunset within 5.3 seconds and the transit within 2.2 seconds, away from the polar transitions. Near those transitions the differences grew to 30–82 seconds, where the Sun climbs only about 0.2″ a second and a tiny altitude difference moves the crossing by many seconds.

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

**Sources.** Six authorities, nine timetables, every day of 2026, retrieved on 2026-10-13. `Validation/official-timetables/README.md` and `sources.json` give the URLs, the reference coordinates and why they were chosen, and the licences.

| Timetable | Where the data came from | Reference coordinates |
|---|---|---|
| Diyanet, Istanbul and Ankara | namazvakitleri.diyanet.gov.tr. The 2026 yearly table comes from the Internet Archive's copy of 2 January 2026, because the live page now shows 2027. Its 31 days that overlap the live 30-day table are identical. | City centres; Diyanet doesn't publish its reference points |
| JAKIM, zone WLY01 | e-solat.gov.my API | Central Kuala Lumpur; JAKIM doesn't publish zone reference points |
| MUIS, Singapore | data.gov.sg, "Muslim Prayer Timetable 2026" | Island centre; not published |
| Umm al-Qura, Makkah and Riyadh | The service behind ummulqura.org.sa/prayer-times | Exact: the site's own city list |
| Kemenag, Kota Jakarta | bimasislam.kemenag.go.id/jadwalshalat | Central Jakarta; not shown |
| moonsighting.com, London | praytable.php, methods 0 (Hanafi, shafaq general) and 2 (Shafi'i, shafaq ahmer) | Exact: the coordinates requested |

Only MUIS's data may be redistributed (Singapore Open Data Licence 1.0). It's committed with attribution, and its comparison runs in every test run. The others stay in a gitignored cache, and their comparison runs when `SALAHTIMES_OFFICIAL_TIMETABLES` points at it. UAE, Qatar and Kuwait were tried without success; the README records what was tried.

**Results.** These are the official time minus SalahTimes' unrounded time, in minutes. "Exact" and "≤ 1 min" compare the preset as it ships, with its own minute adjustments and rounding, against the published minute; their ranges run over the six prayers. Full tables: `Validation/official-timetables/results.md`.

| Timetable | Fajr | Sunrise | Dhuhr | Asr | Maghrib | Isha | Exact | ≤ 1 min |
|---|---|---|---|---|---|---|---|---|
| moonsighting.com London, Hanafi | −0.01 | +0.03 | −0.03 | +0.02 | −0.01 | −0.02 | 74–97% | 100% |
| moonsighting.com London, Shafi'i | −0.01 | +0.03 | −0.03 | −0.02 | −0.01 | −0.01 | 78–97% | 100% |
| Diyanet Istanbul | +0.04 | +0.04 | +0.03 | +0.07 | +0.02 | +0.06 | 25–90% | 90–100% |
| Diyanet Ankara | +0.10 | +0.06 | +0.02 | +0.08 | +0.04 | +0.07 | 27–92% | 93–100% |
| Umm al-Qura Makkah | +0.52 | −0.50 | +0.52 | +0.51 | +0.50 | +0.50 | 44–51% | 100% |
| Umm al-Qura Riyadh | +0.49 | −0.47 | +0.48 | +0.53 | +0.49 | +0.49 | 41–54% | 98–100% |
| MUIS Singapore | +0.49 | +0.50 | +0.58 | +0.51 | +0.60 | +0.53 | 62–80% | 99–100% |
| Kemenag Jakarta | +0.43 | −0.23 | +0.50 | +0.45 | +0.47 | +0.44 | 25–97% | 100% |
| JAKIM WLY01 | +1.88 | −0.80 | +1.77 | +1.75 | +1.93 | +1.97 | 0–20% | 24–100% |

The table gives the mean offset for each prayer, measured from SalahTimes' time with the preset's minute adjustments but before rounding; the minimum and maximum are in `results.md`. A mean near +0.5 with a spread of about a minute is an authority that rounds up.

**Interpretation.**

- **moonsighting.com** computes for the coordinates given, so this is a pure method comparison: the committee's seasonal Fajr and Isha (shafaq general and ahmer), Hanafi and Shafi'i Asr, and its +5 minutes for Dhuhr and +3 for Maghrib. Every offset lies within ±0.84 minutes, the spread that rounding gives. SalahTimes reproduces the committee's own calculator. The committee's rule as finally specified (algorithm.md §8.2 and §8.4: the seasonal bound always applies, and from 55° the seventh of the night is an extra bound) changes nothing here, because London is below 55°.
- **Diyanet.** Mean offsets are under 0.1 minutes, so Diyanet rounds to the nearest minute and the `diyanet` preset's precautionary minutes (sunrise −7, Dhuhr +5, Asr +4, Maghrib +7) are right. Fajr, sunrise and Dhuhr stay within ±0.85 minutes. Maghrib and Isha spread to about ±1.9 minutes around zero, a seasonal wave rather than an offset: Diyanet's own definitions for those two aren't exactly a constant angle plus constant minutes. Within one minute: 97–99% for Maghrib and 90–93% for Isha.
- **Umm al-Qura** also computes for the coordinates given. Every prayer averages +0.5 minutes and sunrise −0.5: Umm al-Qura rounds prayers up and sunrise down, the cautious direction for each. The Isha statistics equal Maghrib's exactly, so the published Ramadan Isha (120 minutes in the Umm al-Qura month of Ramadan, 18 February to 19 March 2026) matches `ramadanIsha: .interval(minutes: 120, hijriDayOffset: 0)` on every day. With its default nearest rounding, the `ummAlQura` preset is within a minute on 98–100% of days. `rounding: .up` for prayers would match more days exactly, but SalahTimes has no setting that rounds sunrise down while it rounds the prayers up.
- **MUIS** publishes only timetables, so the `muis` preset is fitted to them: Fajr 20°, Isha 18°, one Dhuhr minute and `rounding: .up`. Every prayer then averages +0.5 to +0.6 minutes before rounding, as upward rounding gives, and the preset matches the published minute exactly on 62–80% of days, within a minute on every day for every prayer but Asr (361 of 365 days). Before the fit (no Dhuhr minute, nearest rounding) only 41% of Dhuhrs were within a minute.
- **Kemenag** documents its rules, and the `kemenag` preset follows them: Fajr 20°, Isha 18°, Maghrib with the Sun 1° below the horizon, ihtiyat (precautionary minutes) of Fajr +2, sunrise −3, Dhuhr +3, Asr +2, Maghrib +2 and Isha +2, and rounding up. Every prayer is within a minute on all 365 days. Fajr, Dhuhr, Maghrib and Isha match exactly on 95–97% of days and Asr on 85%. Sunrise matches exactly on only 25%: its mean is −0.23 minutes, so Kemenag's sunrise sits about a quarter minute earlier than the preset's before rounding, and rounding up then gives the later minute on most days.
- **JAKIM** documents its method, and the `jakim` preset follows it: Fajr 18° (Malaysia moved Subuh from 20° in 2019; Selangor announced it on 28 November 2019 and the other states followed: https://www.bharian.com.my/amp/rencana/komentar/2020/05/691723/bhplus), Isha 18°, and Dhuhr one minute after the transit (the Selangor Mufti's transit plus 1 min 4 s). Zone WLY01's published times still run about 1.8 to 2.0 minutes later than the preset before rounding, with sunrise 0.8 minutes earlier, so the preset is within a minute on only 24–35% of days for Fajr, Dhuhr, Asr, Maghrib and Isha (sunrise: every day). This is an explained difference. Part of it is JAKIM's precautionary minutes and rounding. Part is the zone's reference point, which JAKIM doesn't publish: the offsets for Fajr, Asr, Maghrib and Isha drift over about 2.5 minutes through the year (Fajr +0.72 to +3.28), more than rounding explains, which a reference point away from central Kuala Lumpur would cause. A WLY01-specific fit closes most of it. On top of the preset (which already has Dhuhr +1 and nearest rounding), it sets `rounding: .up` and user adjustments (`adjustments`) of Fajr +1, sunrise −1, Dhuhr +1, Asr +1, Maghrib +1 and Isha +1, so Dhuhr ends up 2 minutes after the transit. The cached comparison runs this fit next to the preset and writes it to `results.md` ("jakim-wly01 … place-specific fit"): Dhuhr and sunrise are within a minute on all 365 days, and Fajr, Asr, Maghrib and Isha on 347, 353, 352 and 347 days (95–97%), never more than 2 minutes off. Exact matches: Fajr 192, sunrise 258, Dhuhr 266, Asr 247, Maghrib 194, Isha 180 days (49–73%). The fit belongs to that zone, not to the method, so it isn't in the preset.

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
- **Polar regimes.** Tromsø (69.65° N) and Longyearbyen (78.22° N), Muslim World League, Shafi'i and Hanafi, behave as algorithm.md §9 says. On 21 June, Fajr, sunrise, sunset, Maghrib, Isha and both night divisions don't occur (`sunStaysAbove`), while Dhuhr and Asr occur. On 21 December, sunrise, sunset, Maghrib, Asr and both night divisions don't occur (`sunStaysBelow`), while Dhuhr, Fajr and Isha occur, unbounded, because there's no night to bound them. On 1 May in Tromsø the Sun sets but never reaches 17° below the horizon. The seventh-of-the-night bound supplies Isha and Fajr then; with `.disabled`, both are `sunStaysAbove`.
- **The equator and the date line.** Kiritimati (UTC+14), Apia, Adak, Quito, Singapore and Pontianak, every day of 2026: Fajr through Maghrib fall on the requested civil day in the place's zone. Dhuhr is within 3.15 seconds of the NOAA model's solar noon; the tolerance is 10 seconds.
- **Southern high latitudes.** Ushuaia (54.80° S) and Punta Arenas (53.16° S), every day of 2026. `recommended` resolves to `seventhOfTheNight` and gives the same results as setting it explicitly. Events are ordered and continuous. Each place was mirrored at the same latitude north on the day whose declination is opposite, interpolated between two days and matched by the declination's trend. Across 3,645 comparisons, each event's distance from Dhuhr matches within 7.6 seconds; the tolerance is 30 seconds.

## Benchmark

`BenchmarkTests.swift` computes three consecutive days at six places, each with its own method: Makkah, London, Jakarta, Istanbul, Tromsø and Ushuaia. That's 3,600 calls per run, on an Apple M2 Pro with Swift 6.4.

| Build | Per day (one `PrayerTimes`) | Per 48 hours (three days) | Range across places |
|---|---:|---:|---|
| Release (`-c release -Xswiftc -enable-testing`) | 10.6 µs | 31.8 µs | 9.6–11.6 µs per day |
| Debug | 25.8 µs | 77.4 µs | 23.6–27.9 µs per day |

Tromsø and London, where bounds and the Moonsighting Committee's rules apply, are the slowest. These runs shared the machine with other heavy work (a load average near 90 on 12 cores), and three more release runs gave 10.9, 11.0 and 12.9 µs per day, so the figures are upper bounds. On a quieter machine, with the engine before commit `f4b7984`, the release build took 9.3 µs per day and 27.8 µs per 48 hours. The test's only assertion is a 50 ms ceiling.

## Known limitations

- **Presets and published timetables.** Where an authority documents its rules (Diyanet, Umm al-Qura, Kemenag, JAKIM, the Moonsighting Committee), the preset follows them and the measured differences are reported here. Where it publishes only timetables (MUIS, the UAE), the preset is fitted to them. JAKIM's zone WLY01 still runs 1 to 3 minutes later than its documented method; an app that needs that zone's exact minutes can apply the fit described above as user adjustments.
- **Tehran at high latitudes.** Algorithm.md §8.1 bounds every angle-based evening time by the same `p`, and `seventhOfTheNight` gives 1/7 whatever the angle. So when both the 4.5° Maghrib and the 14° Isha pass the bound, they're clamped to the same instant, sunset plus a seventh of the night. This is the specified behaviour: it follows PrayTimes.org's high-latitude semantics, which bound both by the same portion of the night. They coincide but never invert: each is the earlier of its own angle's time and the shared bound, and the 4.5° time always comes before the 14° time. The order test found the tie on 278 days at 60° and 65°, and on none at 55°.
- **Interval Isha isn't bounded** (algorithm.md §8.4). On the order grid, which stops at 65°, it never falls after the next Fajr; the wide scan below finds it from 66°.
- **Beyond the order grid.** `WideScanTests.swift` scans every preset, and Umm al-Qura with the Ramadan rule's 120 minutes and `middleOfTheNight`, at every whole latitude from 66° S to 70° N, on every day of 2026. It uses two places: longitude 0 in UTC, and longitude 31.1° E in Europe/Oslo, whose clock runs behind the Sun. Its output is in `Validation/wide-scan.md`; "latitude-days" there count one latitude on one day. With times rounded as shipped, it finds these departures from strict order, all at 58° or beyond and all but Tehran's at 64° or beyond:
  - **Interval Isha after the next Fajr.** `ummAlQura` and `qatar` (90 minutes): at 66° to 70° and at 66° S (49 latitude-days at each place). With the Ramadan rule's 120 minutes and `middleOfTheNight`: from 64° in both hemispheres (190).
  - **Precautionary minutes larger than a very short night.** `diyanet`'s Fajr falls after its sunrise (sunrise −7 minutes) and its Maghrib after its Isha (Maghrib +7) at 66° to 69° and at 66° S (10 or 11 latitude-days), and they tie on a few more days. `kemenag`'s Fajr falls after its sunrise at 66°, 67°, 69° and 66° S (5 to 8). `dubai` shows both at 67° on one day. `moonsightingCommittee`'s Maghrib (+3) falls after its Isha at 67° on one day.
  - **Dhuhr and Asr before polar night.** In the last days before polar night, Asr comes only minutes after the transit. Every preset ties Dhuhr and Asr after rounding on a few days from 67° (68° at the Oslo place; 66° and 66° S for `moonsightingCommittee`). Presets that add minutes to Dhuhr put it strictly after Asr from 67°: `moonsightingCommittee` (+5) on 23 to 27 latitude-days, and `diyanet` (+5), `jakim` (+1), `muis` (+1, rounding up) and `kemenag` (+3) on 3 to 5. `dubai` (+3) only ties.
  - **Maghrib and Isha tie** when both are bounded by the same portion of the night (see Tehran above): `tehran` from 58° in both hemispheres (about 1,330 latitude-days at each place), `kemenag`'s 1° Maghrib from 66° and at 66° S (33), and isolated days for `diyanet`, `dubai` and `moonsightingCommittee` between 66° and 70° and at 66° S.

  SalahTimes applies each rule as specified and never reorders events, so an app that needs strict order should check it and treat the later event of an out-of-order pair as unavailable.
- **Events before their day.** Where a place's clock runs behind its solar time, as at 31.1° E on Europe/Oslo's clock in winter, an event near solar midnight belongs to the next civil day but falls before it begins. The wide scan finds:
  - a Fajr near solar midnight at 45° to 48°, where the Sun barely reaches the Fajr angle and the recommended rule's middle-of-the-night bound takes over: from 45° S for `muis`, from 46° to 48° for most other presets at the Oslo place, and at 47° to 48° for `egyptian`, `muis` and `kemenag` even at longitude 0 in UTC, where the equation of time alone moves solar midnight past the clock's midnight;
  - a Fajr bounded by `middleOfTheNight` beyond 48°, where the recommended rule wouldn't use it: from 49° in the Umm al-Qura Ramadan setup (from 47° S at the Oslo place);
  - a bounded Fajr at 64° to 66° S, and sunrise itself at 65° to 66° S, for every preset at the Oslo place;
  - `diyanet`'s sunrise, moved 7 minutes earlier, at 67° and 69°.

  RFC 0001, decision 2, describes these events: they keep their owning day and are never moved.
- **Reference points.** Diyanet, JAKIM, MUIS and Kemenag don't say which point their province, zone or national timetables are computed for. City-centre coordinates explain the means well, but part of each offset can come from the reference point.
- **Elevation is ignored.** SalahTimes uses a −0.8333° horizon everywhere, as RFC 0001 decides. Authorities that correct sunrise and sunset for elevation differ by up to a minute or two at elevated places; none of the compared cities is high enough to show it.
- **adhan-swift's data was adjusted** by its authors to fit their library, so parity with it is a comparison with adhan-swift as much as with the original timetables.
- **The solar cross-check shares the Sun's longitude series** with the engine (Meeus chapter 25, which NOAA also uses). It checks the hour angle, time scale and root finding independently, but not the solar theory. A comparison with JPL Horizons or USNO is still to do.
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

# The wide scan behind "Beyond the order grid" and "Events before their day" (about a minute).
SALAHTIMES_WIDE_SCAN=1 SALAHTIMES_WIDE_SCAN_RESULTS=$PWD/Validation/wide-scan.md \
  swift test -j 4 --filter WideScan

# Benchmark in release.
swift test -c release -Xswiftc -enable-testing -j 4 --filter Benchmark

# Official timetables: fetch (about 25 requests), compare and write results.md, including
# the WLY01 fit.
python3 Validation/official-timetables/fetch.py
rm -f Validation/official-timetables/results.md
SALAHTIMES_OFFICIAL_TIMETABLES=$PWD/Validation/official-timetables/cache \
SALAHTIMES_OFFICIAL_RESULTS=$PWD/Validation/official-timetables/results.md \
  swift test -j 4 --filter OfficialTimetable
```

Each test prints its numbers (parity maxima, self-consistency maxima, order and continuity counts, DST differences, mirror differences, benchmark times), and those printed numbers are the source of this document's figures. Official sites change: a later fetch may return revised timetables. `fetch.py` reports, for Diyanet, whether the archived 2026 table still matches the live page.
