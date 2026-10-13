# SalahTimes vectors

These JSON files are the contract for SalahTimes' calculation. The Swift engine passes them, and engines in other languages (TypeScript and Kotlin are planned) pass the same files. Each vector gives an input and the output that [`docs/algorithm.md`](../docs/algorithm.md) defines for it.

The expected values come from an independent reference implementation in Python, [`reference/salahtimes_reference.py`](reference/salahtimes_reference.py), written from `docs/algorithm.md` alone, without reading the Swift engine.

## Layout

| File | What it covers |
|---|---|
| `methods.json` | The method presets: each method's parameters, keyed by name, with their sources. It holds no vectors. |
| `country-methods.json` | The sourced country suggestions: an ISO 3166-1 alpha-2 code to a method name and its source. It holds no vectors. |
| `times/methods.json` | Every preset at its region, a place far from it and a southern-hemisphere place, on 2026's equinoxes and solstices, as published and unrounded. |
| `times/madhab.json` | Shafi'i and Hanafi Asr from the equator to the Arctic, in both hemispheres. |
| `times/high-latitude.json` | Each high-latitude rule from 48° to 65°, north and south, in each season, where the bound applies and where it doesn't, and the first and last nights of the 18° twilight season at 60° N. |
| `times/polar.json` | Polar day and night at Tromsø, Longyearbyen, McMurdo Station and both poles, at the solstices and around the days the Sun stops and starts rising or setting. |
| `times/date-line-equator.json` | Places near the date line (Kiritimati, Apia, Nuku'alofa, Suva, Adak, Pago Pago) and on the equator (Quito, Singapore, Nairobi, Pontianak), and the day Pacific/Apia skipped, 2011-12-30. |
| `times/dst.json` | Daylight saving changes and the days around them, each paired with the same day in a fixed-offset zone, with identical instants. |
| `times/isha-after-midnight.json` | Isha that belongs to day D but falls on D+1: Kashgar and Ürümqi, and bounded Isha in high-latitude summers. |
| `times/adjustments-rounding.json` | Method and user adjustments, and the three rounding modes. |
| `times/ramadan.json` | The opt-in Ramadan Isha rule around Ramadan's first and last days, with Hijri day offsets of -1, 0 and +1. |
| `times/custom.json` | Custom parameters: other angles and intervals, a Maghrib angle, the Moonsighting Committee's rules with each shafaq and with Hanafi Asr, both night spans, and parameters that leave out defaulted keys. |
| `times/ranges.json` | The supported range: the years 1000 and 3000 and years in every ΔT polynomial between them, and the boundary values section 2 accepts. |
| `qibla.json` | Qibla bearings worldwide, near the Kaaba's antipode and at the poles, and the inputs with no bearing. |
| `errors.json` | Inputs that must fail, one for each check in algorithm section 2. |
| `reference/` | The reference implementation, the generator and the cross-check scripts. |

## Format

Every vector file is a JSON object:

```json
{
  "schemaVersion": 1,
  "kind": "prayerTimes",
  "description": "What the file covers.",
  "vectors": [ ... ]
}
```

- `schemaVersion` is the version of this format. A change that an existing runner can't read, such as renaming or removing a field or changing a field's meaning, increases it. Adding vectors, files or optional fields doesn't. A runner should reject a version it doesn't know.
- `kind` is `prayerTimes`, `qibla` or `calculationErrors`, and says how to read `vectors`.

Every vector has:

| Field | Meaning |
|---|---|
| `id` | Unique across all files. Lowercase words joined by hyphens, except that method and rule names keep their camelCase spelling (`method-muslimWorldLeague-...`) and offsets and latitudes keep their sign and decimal point (`ramadan-offset+1-...`, `lat-54.99-north`). Test runners report failures by it. |
| `description` | What the vector shows. Generated notes say which events don't occur, which bounds apply and when Isha falls after midnight. |
| `source` | Where the expectation comes from: the reference implementation, plus any external cross-check. |
| `input` | The calculation's input. |
| `expected` | The expected result. |

### Prayer times (`kind: prayerTimes`)

```json
{
  "id": "polar-mwl-tromso-2026-07-26",
  "description": "...",
  "source": "SalahTimes reference implementation (Vectors/reference/salahtimes_reference.py)",
  "input": {
    "date": "2026-07-26",
    "timeZone": "Europe/Oslo",
    "coordinates": { "latitude": 69.65, "longitude": 18.96 },
    "parameters": {
      "fajr": { "angle": 18 }, "maghrib": "sunset", "isha": { "angle": 17 },
      "madhab": "shafi", "highLatitudeRule": "recommended", "nightSpan": "sunsetToFajr",
      "rounding": "none"
    }
  },
  "expected": {
    "fajr": { "doesNotOccur": "sunStaysAbove" },
    "sunrise": "2026-07-25T23:04:36Z",
    "dhuhr": "2026-07-26T10:50:44Z",
    ...
  },
  "toleranceSeconds": 1
}
```

`input`:
- `date`: the civil day, an ISO 8601 date in the proleptic Gregorian calendar.
- `timeZone`: an IANA time zone identifier. It only selects the solar day (algorithm section 5); the results are instants.
- `coordinates`: `latitude` (positive north) and `longitude` (positive east), in degrees.
- Either `parameters` alone, or `method` with optional `parameters`:
  - `parameters` alone is the full parameter set.
  - `method` names a key of `methods.json`. Its preset's parameters are the starting point, and each top-level key of `parameters` replaces the preset's key of the same name. A replaced key is replaced whole: `{"methodAdjustments": {"isha": 2}}` replaces the preset's method adjustments, it doesn't merge into them.

Parameters use the JSON form of SalahTimes' `CalculationParameters`:

| Key | Values | Default |
|---|---|---|
| `fajr` (required) | `{"angle": 18}` or `"moonsightingCommittee"` | |
| `isha` (required) | `{"angle": 17}`, `{"minutesAfterMaghrib": 90}` or `{"moonsightingCommittee": "general"}` (`general`, `ahmer`, `abyad`) | |
| `maghrib` | `"sunset"` or `{"angle": 4.5}` | `"sunset"` |
| `madhab` | `"shafi"` or `"hanafi"` | `"shafi"` |
| `highLatitudeRule` | `"recommended"`, `"middleOfTheNight"`, `"seventhOfTheNight"`, `"twilightAngle"`, `"disabled"` | `"recommended"` |
| `nightSpan` | `"sunsetToFajr"` or `"sunsetToSunrise"` | `"sunsetToFajr"` |
| `methodAdjustments`, `adjustments` | an object with any of `fajr`, `sunrise`, `dhuhr`, `asr`, `maghrib`, `isha`, in whole minutes; a missing key is 0 | all 0 |
| `rounding` | `"nearest"`, `"up"` or `"none"` | `"nearest"` |
| `ramadanIsha` | `"off"` or `{"interval": {"minutes": 120, "hijriDayOffset": 0}}` | `"off"` |

Most vectors write every key except `methodAdjustments`, `adjustments` and `ramadanIsha`, which appear only when they're set. The `custom-defaults-*` vectors in `times/custom.json` leave out `maghrib`, `madhab`, `highLatitudeRule`, `nightSpan` and `rounding`, one at a time and all together, where any other value of the missing key would change an expected time, so a decoder with a wrong default fails them.

Numbers that aren't finite can't be written in JSON. Where a vector needs one (only in `errors.json` and `qibla.json`), it's a string: `"NaN"`, `"+Infinity"` or `"-Infinity"`. In Swift, `JSONDecoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "+Infinity", negativeInfinity: "-Infinity", nan: "NaN")` reads them.

`expected` has a key for each of the nine events: `fajr`, `sunrise`, `dhuhr`, `asr`, `sunset`, `maghrib`, `isha`, `middleOfTheNight`, `lastThirdOfTheNight`. Each is either:
- a UTC instant written to the second, `"2026-03-20T02:55:12Z"`, in the proleptic Gregorian calendar; or
- `{"doesNotOccur": "sunStaysAbove"}` or `{"doesNotOccur": "sunStaysBelow"}` when the event doesn't occur (algorithm section 9).

An event can fall on a neighboring civil day and still belong to `date`: Isha after midnight, the night's divisions, and at a few places a bounded Fajr before the day begins. The expected instant is the event's instant, wherever it falls.

`toleranceSeconds` is 1. An instant passes when it's within that many seconds of the expected one, and a non-occurrence passes when the reason matches. The reference's value is rounded to the nearest second before it's written, so a correct engine's value lies within 0.5 s plus floating-point noise. With `rounding` `nearest` or `up`, the expected values are whole minutes.

Parse instants and dates in the proleptic Gregorian calendar, as POSIX seconds. Some date libraries switch to the Julian calendar before October 1582 (Foundation's `ISO8601DateFormatter`, Java's `java.util.GregorianCalendar`), which moves the vectors for the years 1000 and 1300 by 5 and 8 days. JavaScript's `Date`, Java's `java.time` and Python's `datetime` are proleptic.

Most prayer-time vectors (973 of 1188) use `"rounding": "none"`, so they check the astronomy to the second. In `times/methods.json`, each day appears twice: unrounded (overriding the preset's `rounding`) and exactly as published.

### Qibla (`kind: qibla`)

```json
{
  "id": "qibla-london",
  "input": { "coordinates": { "latitude": 51.5072, "longitude": -0.1276 } },
  "expected": { "bearing": 118.987253083 },
  "toleranceDegrees": 1e-6
}
```

`bearing` is degrees clockwise from true north, in [0, 360), or `null` when there's no direction (the Kaaba itself, its antipode, invalid coordinates). Compare on the circle: 359.9999999° and 0° are 1e-7° apart. `qibla-antipode-north` expects 0°, where an engine can return a value just below 360°. `qibla-antipode-3e-7-north`, a few centimetres from the antipode, has a wider tolerance (1e-5°) because rounding in the formula leaves about 1e-6° there.

### Errors (`kind: calculationErrors`)

```json
{
  "id": "error-fajr-angle-below-1",
  "input": { "date": "2026-03-20", "timeZone": "Asia/Riyadh", "coordinates": { ... }, "parameters": { ... } },
  "expected": { "error": "invalidParameters" }
}
```

`error` is one of `invalidCoordinates`, `invalidParameters` and `unsupportedDate`. Each vector breaks exactly one check of algorithm section 2, so the order of an engine's checks doesn't matter. Swift's `invalidParameters` carries a message; the vectors don't check it.

## Regenerating

From the repository root, with Python 3.9 or later and nothing but the standard library:

```sh
python3 Vectors/reference/generate.py
```

The output is deterministic: running it twice gives identical files. It prints the number of vectors per file. `times/methods.json` is regenerated only when `methods.json` exists.

Time zones come from Python's `zoneinfo` (the system's tz database). The expected instants don't depend on the tz database's version, because the time zone only picks the transit nearest local noon (algorithm section 5), and a change of an hour or two can't change which transit that is.

## Where the expectations come from

Every expected value comes from the reference implementation. It follows `docs/algorithm.md` section by section and names the section in each function. Its Umm al-Qura Ramadan table (for the Ramadan rule) was derived from Foundation's `Calendar(identifier: .islamicUmmAlQura)` and Java's `HijrahChronology` (`islamic-umalqura`); the two agree on every Ramadan from 1445 to 1449 (2024 to 2028), and the Ramadan vectors use only those years. (Outside 1300 to 1600 AH, algorithm section 8.7 falls back to the arithmetic `islamic-civil` calendar; no vector depends on it.)

The reference was checked against outside sources before its values were trusted. Run on 2026-10-13:

- **NOAA's solar calculator.** [`reference/crosscheck_noaa.py`](reference/crosscheck_noaa.py) runs the calculation functions of NOAA's Solar Calculator (`https://gml.noaa.gov/grad/solcalc/main.js`) in Node.js for every unrounded vector below 65° of latitude. For the years 1900 to 2100, the largest differences are 3.4 s for sunrise (629 compared), 3.7 s for sunset (638) and 3.6 s for the transit (629). NOAA's code ignores ΔT and computes the transit from its equation of time, which explains the few seconds. For the years 1000 to 1880 and 3000 (7 vectors), the differences reach 10.8 s, at the year 3000, where ΔT is about 74 minutes and NOAA leaves it out. (The USNO API, `aa.usno.navy.mil/api/rstt/oneday`, reset every connection from the machine that generated these files, so it wasn't used.)
- **adhan-swift's test data.** adhan-swift (MIT) ships official timetables for eight places as local, minute-rounded times. [`reference/crosscheck_adhan.py`](reference/crosscheck_adhan.py) runs the reference with the matching presets of `methods.json`, each with its own rounding. 2768 of 2772 times agree within one minute, and the other four differ by 2 minutes: two Isha times at Ankara (Diyanet) and Fajr and sunrise on one day at Kuwait City. Dubai (72 of 72) and Singapore (2196 of 2196) agree within a minute. Those two files hold the authorities' times as published. The Doha, Kuwait City, London and Makkah files say adhan-swift's authors adjusted their times by 1 to 2 minutes, so agreement there is weaker evidence than agreement with an unaltered table.
- **Published Qibla bearings.** timesprayer.com's bearings for Auckland, Cairo, Cape Town, Istanbul, Jakarta, Karachi, London, Los Angeles, New York, Tokyo and Toronto, at the coordinates those pages use, agree with the reference within 0.005°, the pages' rounding. Each Qibla vector's `source` cites its page.

## Fragility

A vector is fragile when a correct engine could reasonably compute a different expected value, because the answer sits on a knife edge. The generator refuses to write one:

1. **Existence tests.** For every crossing the calculation makes (algorithm section 6), including the neighboring days' sunsets and sunrises and the next day's Fajr, `|c(T) - 1| ≥ 1e-4` and `|c(A) + 1| ≥ 1e-4`, where `T` is the transit and `A` the antitransit on the crossing's side. Closer than that, the Sun only just reaches the altitude, and engines could decide either way. The generator also keeps `|c(T) + 1| ≥ 1e-4`, which picks where the iteration starts; that shouldn't change the result, but costs nothing to avoid.
2. **Asr.** The zenith distance at transit is at least 1e-4° from 90°.
3. **Convergence.** Every transit and crossing iteration converges within its 20 steps.
4. **Minute rounding.** With `nearest`, no event's unrounded time is within 2 seconds of a half minute; with `up`, none is within 2 seconds of a whole minute.

A case marked `move` (most minute-rounded vectors) moves to the next day that isn't fragile, and its description says so. Any other fragile case stops the generator with an error, so whoever edits the cases picks another day. The preset-as-published vectors in `times/methods.json` move this way too; their unrounded twins stay on the equinoxes and solstices.

## Implementing another engine

1. Implement `docs/algorithm.md`.
2. Load `methods.json` into a map from method name to parameters.
3. For each `.json` file in `Vectors/` and `Vectors/times/`, except the two data files `Vectors/methods.json` and `Vectors/country-methods.json`, check `schemaVersion` is 1, and read `kind`. Match the data files by their full path: `Vectors/times/methods.json` holds vectors.
4. For each `prayerTimes` vector, resolve the parameters: the preset named by `method`, with `parameters`' top-level keys replacing the preset's, or `parameters` alone. Decode them with the defaults above. Run the calculation for `date` in `timeZone` at `coordinates`, and compare each of the nine events: an instant within `toleranceSeconds`, or the same non-occurrence reason.
5. For each `qibla` vector, compare the bearing on the circle within `toleranceDegrees`, or expect no bearing.
6. For each `calculationErrors` vector, expect the calculation to fail with `error`.
7. Report failures by `id`.

`Tests/SalahTimesTests/VectorTests.swift` is the Swift runner, and a working example of each step.

## Settled readings

Some vectors pin down cases that an earlier draft of `docs/algorithm.md` left open or got wrong:

- **Isha by interval after an unreached Maghrib angle.** Isha takes Maghrib's reason (sections 8.4 and 9). `custom-maghrib-angle-unreached-interval-tromso-*` has a Sun that sets but never reaches -4.5°, so Maghrib and Isha are both `sunStaysAbove` while sunset occurs.
- **Adjustments.** `methodAdjustments` and `adjustments` are each checked against ±1440 minutes, and their sum isn't checked (section 2). `adjust-sum-beyond-limit-makkah-2026-04-10` moves Fajr and Isha by 2000 minutes.
- **The Moonsighting Committee's rule.** The seasonal bound applies wherever sunrise or sunset occurs, and from 55° (inclusive) the night's seventh is a further bound; Fajr is the latest of the 18° time and the bounds, and Isha the earliest (sections 8.2 and 8.4). `custom-moonsighting-threshold-*` covers 55.0°, -55.0° and ±54.99° in summer, where the seventh decides at 55° and the seasonal bound just inside it, and Oslo in winter, beyond 55°, where the seasonal bound decides.
- **Neighboring solar days.** `T_{D-1}` and `T_{D+1}` are the transits nearest `T_D ∓ 86400` seconds (section 5). `date-line-apia-skipped-day-*` covers 2011-12-29 to 2011-12-31 in Pacific/Apia: the skipped 30th has the 31st's events, and the 29th keeps its real night.
- **Where a crossing's existence is decided.** At the transit for `sunStaysBelow` and at the antitransit for `sunStaysAbove` (section 6), so the evening crossing and the next morning's agree about the night between them unless the Sun's lowest altitude that night is within about 0.0002° of the angle. `high-latitude-season-edge-lat-60-north-*` pins the first and last nights of the 18° season at 60° N, and the polar vectors around the start and end of polar day do the same for sunrise and sunset.
- **Years and ΔT.** `times/ranges.json` runs the years 1000 and 3000, the ends of the supported range, and a year in each ΔT polynomial of section 3 between them.
- **The Qibla near the antipode.** The central angle comes from unit vectors (section 10). `qibla-antipode-3e-7-north`, 5.2e-9 radians from the antipode, has a bearing; `qibla-none-antipode-1e-11`, inside the 1e-9 radian threshold, doesn't.
