# The SalahTimes algorithm

This is the normative description of how SalahTimes computes prayer times. The Swift engine follows it, the JSON vectors in `Vectors/` are generated from an independent implementation of it, and engines in other languages implement it to pass those vectors. When the engine and this document disagree, one of them has a bug.

Method values (angles, intervals, precautionary minutes) aren't defined here; `METHODS.md` and `Vectors/methods.json` give them with their sources.

## 1. Conventions

- Angles are in degrees unless a formula says radians. `normalize360(x)` maps an angle into `[0, 360)`, and `normalize180(x)` into `(-180, 180]`.
- Latitude `φ` is positive north. Longitude `L` is positive east.
- An instant is a count of seconds since 1970-01-01T00:00:00Z on the UTC time scale, ignoring leap seconds (POSIX time). Results are instants; formatting them is the caller's business.
- `D` is the civil day being computed, a proleptic Gregorian date, and `Z` is the IANA time zone that gives it meaning. `D-1` and `D+1` are the neighboring civil days.
- "Doesn't occur" is written `NOT(reason)`. The reasons are `sunStaysAbove` and `sunStaysBelow` (section 9).

## 2. Inputs and validation

A calculation takes coordinates, a civil day, a time zone and parameters. It fails, without producing any times, when:

| Check | Error |
|---|---|
| Latitude or longitude not finite, latitude outside [-90, 90], or longitude outside [-180, 180] | `invalidCoordinates` |
| The year of `D` outside [1000, 3000] | `unsupportedDate` |
| A Fajr or Isha angle not finite or outside [1, 30] | `invalidParameters` |
| A Maghrib angle not finite or outside (0, 30] | `invalidParameters` |
| An Isha interval outside [0, 1440] minutes | `invalidParameters` |
| A Ramadan interval outside [1, 1440] minutes, or its Hijri day offset outside [-30, 30] | `invalidParameters` |
| Any minute adjustment outside [-1440, 1440] | `invalidParameters` |

`methodAdjustments` and `adjustments` are checked separately. Their sum isn't checked, so together they can move an event by up to 2880 minutes.

## 3. Time scales

The Julian Day of an instant `t` (UT) is

    JD = t / 86400 + 2440587.5

The Sun's position uses Terrestrial Time: `JDE = JD + ΔT / 86400`. ΔT, in seconds, comes from the polynomial expressions of Espenak and Meeus (NASA, *Five Millennium Canon of Solar Eclipses*, 2006), evaluated at the decimal year `y = year + (month - 0.5) / 12` of the instant's UTC calendar date:

| Range of `y` | ΔT |
|---|---|
| y < -500 or y ≥ 2150 | `u = (y - 1820) / 100`; `-20 + 32 u²` |
| -500 ≤ y < 500 | `u = y / 100`; `10583.6 - 1014.41 u + 33.78311 u² - 5.952053 u³ - 0.1798452 u⁴ + 0.022174192 u⁵ + 0.0090316521 u⁶` |
| 500 ≤ y < 1600 | `u = (y - 1000) / 100`; `1574.2 - 556.01 u + 71.23472 u² + 0.319781 u³ - 0.8503463 u⁴ - 0.005050998 u⁵ + 0.0083572073 u⁶` |
| 1600 ≤ y < 1700 | `t = y - 1600`; `120 - 0.9808 t - 0.01532 t² + t³ / 7129` |
| 1700 ≤ y < 1800 | `t = y - 1700`; `8.83 + 0.1603 t - 0.0059285 t² + 0.00013336 t³ - t⁴ / 1174000` |
| 1800 ≤ y < 1860 | `t = y - 1800`; `13.72 - 0.332447 t + 0.0068612 t² + 0.0041116 t³ - 0.00037436 t⁴ + 0.0000121272 t⁵ - 0.0000001699 t⁶ + 0.000000000875 t⁷` |
| 1860 ≤ y < 1900 | `t = y - 1860`; `7.62 + 0.5737 t - 0.251754 t² + 0.01680668 t³ - 0.0004473624 t⁴ + t⁵ / 233174` |
| 1900 ≤ y < 1920 | `t = y - 1900`; `-2.79 + 1.494119 t - 0.0598939 t² + 0.0061966 t³ - 0.000197 t⁴` |
| 1920 ≤ y < 1941 | `t = y - 1920`; `21.20 + 0.84493 t - 0.076100 t² + 0.0020936 t³` |
| 1941 ≤ y < 1961 | `t = y - 1950`; `29.07 + 0.407 t - t² / 233 + t³ / 2547` |
| 1961 ≤ y < 1986 | `t = y - 1975`; `45.45 + 1.067 t - t² / 260 - t³ / 718` |
| 1986 ≤ y < 2005 | `t = y - 2000`; `63.86 + 0.3345 t - 0.060374 t² + 0.0017275 t³ + 0.000651814 t⁴ + 0.00002373599 t⁵` |
| 2005 ≤ y < 2050 | `t = y - 2000`; `62.92 + 0.32217 t + 0.005589 t²` |
| 2050 ≤ y < 2150 | `-20 + 32 ((y - 1820) / 100)² - 0.5628 (2150 - y)` |

This is the table of polynomials published with the *Five Millennium Canon* (https://eclipse.gsfc.nasa.gov/SEcat5/deltatpoly.html), without the Canon's lunar correction, which applies to its eclipse computations only. ΔT moves an event by about ΔT / 365 seconds when the hour angle carries the Sun across the altitude, since the Sun moves about a degree a day against the stars: a quarter of a second in 2026, about 5 seconds in the year 1000 and 14 seconds in 3000. Where the declination carries it, near the poles and at the edges of seasons, ΔT can move an event by up to about ΔT itself.

## 4. The Sun's position

From Jean Meeus, *Astronomical Algorithms*, 2nd edition (1998): chapter 25's lower-accuracy solar coordinates with the apparent-place correction, the obliquity of chapter 22, and the sidereal time of chapter 12. NOAA's solar calculator uses the same series. For an instant with Julian Day `JD` and `JDE`:

    T  = (JDE - 2451545.0) / 36525            Julian centuries of TT
    L0 = 280.46646 + 36000.76983 T + 0.0003032 T²          mean longitude
    M  = 357.52911 + 35999.05029 T - 0.0001537 T²          mean anomaly
    C  = (1.914602 - 0.004817 T - 0.000014 T²) sin M
       + (0.019993 - 0.000101 T) sin 2M
       + 0.000289 sin 3M                                   equation of the center
    Θ  = L0 + C                                            true longitude
    Ω  = 125.04 - 1934.136 T
    λ  = Θ - 0.00569 - 0.00478 sin Ω                       apparent longitude
    ε0 = 23 + 26/60 + 21.448/3600 - (46.8150 T + 0.00059 T² - 0.001813 T³) / 3600
    ε  = ε0 + 0.00256 cos Ω                                true obliquity
    α  = atan2(cos ε sin λ, cos λ)                          apparent right ascension
    δ  = asin(sin ε sin λ)                                  apparent declination

Sidereal time uses UT:

    Tu = (JD - 2451545.0) / 36525
    θ0 = 280.46061837 + 360.98564736629 (JD - 2451545.0) + 0.000387933 Tu² - Tu³ / 38710000
    Δψ = -0.00478 sin Ω                                    nutation in longitude, as in λ
    θ  = θ0 + Δψ cos ε                                     apparent sidereal time at Greenwich

The local hour angle is `H = normalize180(θ + L - α)`, and the Sun's geometric altitude `h` satisfies

    sin h = sin φ sin δ + cos φ cos δ cos H

## 5. The solar day of a civil day

The events of `D` are computed around one solar transit, `T_D`:

1. Let `U` be the instant `D` 12:00:00 read as UTC. Let `o1` be `Z`'s UTC offset at `U`, and `o2` be `Z`'s offset at `U - o1`. Local noon is `n = U - o2`.
2. `T_D` is the transit nearest `n`. Start from `t = n` and repeat `t = t - H(t) / 360 × 86400` until the step is below 1 ms (at most 20 times).

Transits are about 24 hours apart and every real time zone keeps local noon within a few hours of the Sun's transit, so the nearest transit is the one inside `D`. This choice is what makes the date line work: at Kiritimati (UTC+14, 157° W), `D`'s transit falls on `D - 1` in UTC.

The neighboring solar days come from `T_D`, not from the neighboring civil days: `T_{D-1}` is the transit nearest `T_D - 86400` and `T_{D+1}` the transit nearest `T_D + 86400`, by the same iteration. So they're always the adjacent solar days, even where `Z` skips or repeats a calendar day. Pacific/Apia skipped 2011-12-30: for that day the lookups of step 1 find 2011-12-31's transit, so a skipped day gets the next day's events, and the days around it keep their real nights.

Where a rule needs a neighbor's date, it uses the civil date `D - 1` or `D + 1`. Only the Moonsighting Committee's day of the year for Fajr of `D+1` does (sections 8.5 and 8.6). So on Apia's skipped 2011-12-30, Fajr of `D+1` uses 2011-12-31's seasonal minutes with the solar day of 2012-01-01, a difference of a fraction of a minute.

Daylight saving time moves `n` by an hour or two at most, which never changes the nearest transit, so the instants don't depend on whether `Z` observes DST.

## 6. Altitude crossings

`crossing(T, h*, side)` finds when the Sun reaches altitude `h*` before the transit `T` (`side = -1`, morning) or after it (`side = +1`, evening). Let

    c(t) = (sin h* - sin φ sin δ(t)) / (cos φ cos δ(t))

with `δ(t)` the declination at instant `t`, and let `A = T + side × 43200` be the antitransit on that side, 12 hours away.

1. The Sun is highest at the transit and lowest at the antitransit, so the event's existence is decided there. If `c(T) > 1`, the Sun stays below `h*` even at the transit: the result is `NOT(sunStaysBelow)`. If `c(A) < -1`, it stays above `h*` even at the antitransit: the result is `NOT(sunStaysAbove)`.
2. Otherwise the crossing exists. Start from the first estimate

       t = T + side × acos(max(-1, c(T))) / 360 × 86400 seconds

   which is `A` when `c(T) ≤ -1`, since the Sun then only reaches `h*` near the antitransit. Then iterate:

       repeat at most 20 times:
           compute δ, α and θ at t
           H0 = acos(min(1, max(-1, c(t))))           in [0, 180]
           step = normalize180(side × H0 - H(t)) / 360 × 86400 seconds
           t = t + step
           stop when |step| < 0.001 s

   If the loop stopped on a step below 1 ms and `t` lies strictly between `T` and `A`, that is, `0 < side × (t - T) < 43200`, `t` is the crossing.
3. Otherwise, bisect. The Sun is at or above `h*` at `T` and at or below it at `A`, so the crossing lies between them. Let `p = T` and `q = A`, and repeat 26 times:

       m = (p + q) / 2
       if sin φ sin δ(m) + cos φ cos δ(m) cos H(m) ≥ sin h*:  p = m
       else:                                                  q = m

   The crossing is `(p + q) / 2`. Twenty-six halvings take 12 hours below 0.7 ms.

The evening crossing after `T_D` and the morning crossing before `T_{D+1}` are tested at antitransits less than half a minute apart (`T_D + 43200` and `T_{D+1} - 43200`; an apparent solar day isn't exactly 24 hours). So they agree on whether the Sun reaches `h*` that night, even on the first or last night of a season, when the declination at the transits would say otherwise. They can disagree only when the Sun's lowest altitude that night is within about 0.0002° of `h*`.

Starting from the estimate keeps every step small. Starting from `T` instead, a crossing near the antitransit would need a first step of nearly 180° of hour angle, and the transit's residual hour angle, however small, could make `normalize180` send that step half a day the wrong way. The clamp in `H0` only matters while the iterate is far from the crossing.

The iteration assumes that the hour angle carries the Sun across `h*`. When an event comes within minutes of the transit or the antitransit, the changing declination can carry it instead, and the iteration can then swing between two instants without settling, or settle on a neighboring day's transit. So step 3 bisects, which needs nothing but the two ends. That happens at the edges of seasons: on the last or first days of polar night or polar day, of a twilight season (from about 48° of latitude for 18°), and for an Asr that comes just after the transit before polar night or just before the antitransit in polar day. Near the poles it happens more often. Each place sees it on a few days a year at most, and below about 60° of latitude it's very rare.

`cos φ` is never exactly zero in floating point, so the poles need no special case: there `c` is very large, the tests report the right reason, and bisection finds the crossings that occur. But the model's premise, that the Sun is highest at `T` and lowest at `A`, fails within about a degree of a pole, where the declination changes the Sun's altitude in half a day as much as the hour angle does. There crossings can go unreported. The Sun can rise above `h*` and set again within one half day while the tests report `NOT(sunStaysBelow)` (89.9° N, 100° E, on 18 March 2026: the Sun is above the horizon for four and a half hours that evening). It can dip below an Asr altitude for minutes while the tests report `NOT(sunStaysAbove)` (89° N on 16 April 2026). And once a year the first rise above `h*`, or the last fall below it, can fall in neither half of any solar day, so one day says `NOT(sunStaysBelow)` and the next `NOT(sunStaysAbove)`. Every implementation of this section gives the same answers there, but they don't describe the sky; treat events within a degree of a pole as unreliable.

When `c(T)` is within about 1e-4 of 1, or `c(A)` within about 1e-4 of -1, the Sun only just reaches `h*`, and implementations can decide either way; the vectors avoid such days.

## 7. Astronomical events

For the solar day with transit `T`:

| Event | Definition |
|---|---|
| transit | `T` |
| sunrise | `crossing(T, -50/60, -1)` (the Sun's upper limb on the horizon, with 34′ of refraction and a 16′ semidiameter) |
| sunset | `crossing(T, -50/60, +1)` |
| twilight before sunrise at angle `a` | `crossing(T, -a, -1)` |
| twilight after sunset at angle `a` | `crossing(T, -a, +1)` |
| Asr for shadow factor `k` | see below |

**Asr.** Let `δT` be the declination at `T`, and `z = |φ - δT|` the Sun's zenith distance at transit. If `z ≥ 90`, the Sun is below the horizon at transit and Asr is `NOT(sunStaysBelow)`. Otherwise the Asr altitude is

    hAsr = atan(1 / (k + tan z))

so an object's shadow is `k` times its length plus its noon shadow, and Asr is `crossing(T, hAsr, +1)`. `k` is 1 for `shafi` and 2 for `hanafi`.

As `z` approaches 90, `hAsr` approaches the noon altitude `90 - z`, so in the last days before polar night the crossing's existence test is close to `c = 1` and can decide either way (section 6). The vectors avoid those days.

## 8. Prayer times for D

Compute the transits `T_{D-1}`, `T_D` and `T_{D+1}`, then:

    sunrise   = sunrise of D
    sunset    = sunset of D
    sunsetPrev = sunset of D-1
    sunriseNext = sunrise of D+1
    nightBefore = sunrise - sunsetPrev        when both occur
    nightAfter  = sunriseNext - sunset        when both occur
    dhuhr     = T_D
    asr       = Asr of D

The two nights are measured from sunset to sunrise. Fajr uses the night that ends at its own sunrise; Isha and Maghrib use the night that starts at their own sunset. Measuring both from the same night can put a bounded Fajr before the previous day's bounded Isha in seasons when nights lengthen quickly.

### 8.1 Bounds

A bound keeps a morning time no earlier than `sunrise - p × nightBefore`, or an evening time no later than `sunset + p × nightAfter`, for a portion `p`:

    boundMorning(raw, p):
        if nightBefore is undefined: return raw
        b = sunrise - p × nightBefore
        if raw is NOT, or raw < b: return b
        return raw

    boundEvening(raw, p):
        if nightAfter is undefined: return raw
        b = sunset + p × nightAfter
        if raw is NOT, or raw > b: return b
        return raw

The high-latitude rule gives `p`. `recommended` first resolves to `seventhOfTheNight` when `|φ| > 48` and to `middleOfTheNight` otherwise.

| Rule | `p` for an angle `a` |
|---|---|
| `middleOfTheNight` | 1/2 |
| `seventhOfTheNight` | 1/7 |
| `twilightAngle` | `a / 60` |
| `disabled` | no bound: the raw time stands |

### 8.2 Fajr

- `angle(a)`: `boundMorning(crossing(T_D, -a, -1), p(a))`.
- `moonsightingCommittee`: the raw time is `crossing(T_D, -18, -1)`. The committee's bounds are:
  - the seasonal bound `sunrise - 60 × S_fajr` seconds, where `S_fajr` is the value of section 8.6, when sunrise occurs;
  - when `|φ| ≥ 55`, also the seventh bound `sunrise - nightBefore / 7`, when `nightBefore` is defined.

  Fajr is the latest of the raw time, if it occurs, and the bounds that exist. If none of them exists, the raw time's `NOT` stands. The high-latitude rule isn't used.

### 8.3 Maghrib

- `sunset`: Maghrib is `sunset`.
- `angle(a)`: `boundEvening(crossing(T_D, -a, +1), p(a))`.

### 8.4 Isha

- `angle(a)`: `boundEvening(crossing(T_D, -a, +1), p(a))`.
- `minutesAfterMaghrib(m)`: Maghrib (section 8.3, before adjustments) plus `m` minutes. It takes Maghrib's reason when Maghrib doesn't occur, and no high-latitude bound applies. The Ramadan rule (section 8.7) can replace `m`.
- `moonsightingCommittee(shafaq)`: the raw time is `crossing(T_D, -18, +1)`. The committee's bounds are:
  - the seasonal bound `sunset + 60 × S_isha(shafaq)` seconds (section 8.6), when sunset occurs;
  - when `|φ| ≥ 55`, also the seventh bound `sunset + nightAfter / 7`, when `nightAfter` is defined.

  Isha is the earliest of the raw time, if it occurs, and the bounds that exist. If none of them exists, the raw time's `NOT` stands. The high-latitude rule isn't used.

The committee's booklet compares the 18° time with the seasonal value everywhere, and from 55° adds the seventh of the night as a further limit: "Fajr time is later of the two … Isha time is earlier of the two." Its timetable generator applies the seventh at exactly 55° and -55°.

### 8.5 The night's middle and last third

With `nightSpan = sunsetToFajr`, the night runs from `sunset` (of `D`) to Fajr of `D+1`, computed by sections 8.2 and 8.6 for `D+1` and taken before adjustments and rounding. With `sunsetToSunrise`, it ends at `sunriseNext`, the unadjusted sunrise of `D+1`. Then, with `N` the night's length:

    middleOfTheNight    = sunset + N / 2
    lastThirdOfTheNight = sunset + 2N / 3

If sunset doesn't occur, both take sunset's reason; otherwise, if the night's end doesn't occur, both take its reason.

### 8.6 The Moonsighting Committee's seasonal values

From Khalid Shaukat's method for the Moonsighting Committee Worldwide, as cited in METHODS.md. For `D`, let `n` be its day of the year (January 1 is 1) and `Y` the number of days in its year. Count the days since the winter solstice:

    if φ ≥ 0: s = n + 10;               if s ≥ Y: s = s - Y
    else:     s = n - (Y == 366 ? 173 : 172); if s < 0: s = s + Y

With `A = |φ|`, four coefficients `a, b, c, d` (below) give the value in minutes:

    if s < 91:  a + (b - a) / 91 × s
    elif s < 137: b + (c - b) / 46 × (s - 91)
    elif s < 183: c + (d - c) / 46 × (s - 137)
    elif s < 229: d + (c - d) / 46 × (s - 183)
    elif s < 275: c + (b - c) / 46 × (s - 229)
    else:         b + (a - b) / 91 × (s - 275)

| Value | a | b | c | d |
|---|---|---|---|---|
| `S_fajr` | 75 + 28.65 A / 55 | 75 + 19.44 A / 55 | 75 + 32.74 A / 55 | 75 + 48.10 A / 55 |
| `S_isha(general)` | 75 + 25.60 A / 55 | 75 + 2.050 A / 55 | 75 - 9.21 A / 55 | 75 + 6.14 A / 55 |
| `S_isha(ahmer)` | 62 + 17.40 A / 55 | 62 - 7.16 A / 55 | 62 + 5.12 A / 55 | 62 + 19.44 A / 55 |
| `S_isha(abyad)` | 75 + 25.60 A / 55 | 75 + 7.16 A / 55 | 75 + 36.84 A / 55 | 75 + 81.84 A / 55 |

The value is used unrounded, and `A` isn't capped at 55: the bound is `sunrise - 60 × S_fajr` or `sunset + 60 × S_isha` seconds.

### 8.7 The Ramadan Isha rule

With `ramadanIsha = interval(minutes: m', hijriDayOffset: k)` and Isha `minutesAfterMaghrib(m)` with `m > 0`: if the civil day `D + k` (adding `k` days) falls in month 9 of the Umm al-Qura calendar, Isha for `D` uses `m'` instead of `m`. Nothing else changes, and the rule has no effect on any other Isha rule. The Umm al-Qura calendar is Saudi Arabia's official calendar, which ICU calls `islamic-umalqura` and Foundation `.islamicUmmAlQura`. From 1 Muharram 1300 AH (1882-11-12) to the end of 1600 AH (2174-11-25) it follows its published month table, which Java's `HijrahChronology` also implements. Outside that range it is the arithmetic civil calendar, ICU's `islamic-civil`: an epoch of Friday 16 July 622 (Julian) and leap years 2, 5, 7, 10, 13, 16, 18, 21, 24, 26 and 29 of each 30-year cycle. ICU falls back to it there; `HijrahChronology` rejects those dates, so an engine built on it supplies the civil calendar itself. The other arithmetic variant, `islamic-tbla` (a Thursday epoch), differs: it starts Ramadan 1447 a day earlier.

### 8.8 Adjustments

After sections 8.1 to 8.7, each of Fajr, sunrise, Dhuhr, Asr, Maghrib and Isha that occurs moves by `60 × (methodAdjustment + adjustment)` seconds for that event. Sunset, the middle of the night and the last third don't move.

### 8.9 Rounding

Then every event that occurs is rounded, with `t` in seconds:

| Rounding | Result |
|---|---|
| `nearest` | `60 × floor(t / 60 + 0.5)` |
| `up` | `60 × ceil(t / 60)` |
| `none` | `t` |

## 9. When events don't occur

`crossing` reports `sunStaysBelow` when the Sun doesn't climb to the altitude even at the transit, and `sunStaysAbove` when it doesn't descend to it even at the antitransit (section 6). Every other non-occurrence takes the reason of the event it depends on:

- Maghrib by `sunset` takes sunset's reason. Isha by interval takes Maghrib's reason (section 8.4), which is sunset's when Maghrib is `sunset`.
- A bound needs its night. When the night is undefined, the raw angle time stands, including its reason if it doesn't occur.
- The night's middle and last third take sunset's reason, or failing that, the reason of the night's end.

So during polar day sunrise, sunset, Maghrib, Isha and the night's divisions are `NOT(sunStaysAbove)`, while Dhuhr occurs and Asr usually does. During polar night sunrise, sunset, Maghrib and Asr are `NOT(sunStaysBelow)`, while Dhuhr occurs and Fajr and Isha occur whenever the Sun still climbs past their angles.

## 10. Qibla

Coordinates that fail section 2's check give no result. Otherwise the Qibla is the initial bearing of the great circle from the place `(φ1, L1)` to the Kaaba `(φ2, L2) = (21.4225241, 39.8261818)` on a spherical Earth, clockwise from true north:

    ΔL = L2 - L1
    bearing = normalize360(atan2(sin ΔL cos φ2, cos φ1 sin φ2 - sin φ1 cos φ2 cos ΔL))

There's no single direction at the Kaaba itself or at its antipode. The central angle `σ` between the two places is computed from their unit vectors, which keeps its precision near 0 and near π (the haversine formula loses it near π):

    v(φ, L) = (cos φ cos L, cos φ sin L, sin φ)
    σ = atan2(|v1 × v2|, v1 · v2)

When `σ` is below 1e-9 radians or above π - 1e-9 radians, there's no result.

Close to the antipode both arguments of the bearing's `atan2` are tiny, so rounding in `ΔL` shows: due north of the antipode the exact bearing is 0°, but because `sin ΔL` isn't exactly 0 when `ΔL` is 180°, an engine gets about 1e-6° at 3e-7° from the antipode, depending on how it forms `ΔL`. Engines agree there only to about 1e-5°.

## References

- Jean Meeus, *Astronomical Algorithms*, 2nd edition, Willmann-Bell, 1998: chapters 7 (Julian Day), 12 (sidereal time), 15 (rising, transit and setting), 22 (nutation and obliquity) and 25 (solar coordinates).
- NOAA Global Monitoring Laboratory, *Solar Calculation Details* and the NOAA Solar Calculator, which implement the same chapter 25 series: https://gml.noaa.gov/grad/solcalc/calcdetails.html
- Fred Espenak and Jean Meeus, *Polynomial Expressions for Delta T*, NASA: https://eclipse.gsfc.nasa.gov/SEcat5/deltatpoly.html
- Hamid Zarrabi-Zadeh, *Prayer Times Calculation*, PrayTimes.org, for the high-latitude rules: http://praytimes.org/calculation
- Khalid Shaukat, the Moonsighting Committee Worldwide's Fajr and Isha method: cited in METHODS.md.
