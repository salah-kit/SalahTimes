"""An independent reference implementation of SalahTimes' algorithm.

This module implements docs/algorithm.md, sections 2 to 10, in plain Python (standard library
only). It exists to generate the expected values in Vectors/: it was written from the
specification alone, without reading the Swift engine, so the two can catch each other's bugs.

It favors clarity over speed. Every function names the section of docs/algorithm.md it follows.

Parameters use the same JSON form as the vectors and as SalahTimes' `Codable` types, for example

    {"fajr": {"angle": 18}, "isha": {"minutesAfterMaghrib": 90}, "rounding": "none"}

The main entry points are `prayer_times(...)` and `qibla(...)`. Both are deterministic.
"""

import math
from datetime import date, datetime, timedelta, timezone
from zoneinfo import ZoneInfo

# ---------------------------------------------------------------------------------------------
# Section 1: conventions
# ---------------------------------------------------------------------------------------------

SUN_STAYS_ABOVE = "sunStaysAbove"
SUN_STAYS_BELOW = "sunStaysBelow"

EVENTS = (
    "fajr",
    "sunrise",
    "dhuhr",
    "asr",
    "sunset",
    "maghrib",
    "isha",
    "middleOfTheNight",
    "lastThirdOfTheNight",
)

# The six events that adjustments move (section 8.8).
ADJUSTABLE = ("fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha")

_EPOCH = datetime(1970, 1, 1, tzinfo=timezone.utc)


class NotOccur:
    """An event that doesn't occur, with its reason (section 9). Written NOT(reason)."""

    __slots__ = ("reason",)

    def __init__(self, reason):
        assert reason in (SUN_STAYS_ABOVE, SUN_STAYS_BELOW)
        self.reason = reason

    def __eq__(self, other):
        return isinstance(other, NotOccur) and other.reason == self.reason

    def __repr__(self):
        return f"NOT({self.reason})"


def occurs(value):
    return not isinstance(value, NotOccur)


def normalize360(x):
    """Maps an angle into [0, 360)."""
    r = math.fmod(x, 360.0)
    if r < 0:
        r += 360.0
    if r >= 360.0:  # fmod of a tiny negative number plus 360 can round up to 360.
        r -= 360.0
    return r


def normalize180(x):
    """Maps an angle into (-180, 180]."""
    r = normalize360(x)
    if r > 180.0:
        r -= 360.0
    return r


def sind(x):
    return math.sin(math.radians(x))


def cosd(x):
    return math.cos(math.radians(x))


# ---------------------------------------------------------------------------------------------
# Section 2: inputs and validation
# ---------------------------------------------------------------------------------------------


class CalculationError(Exception):
    """A calculation that fails before producing times. `case` is the Swift case name."""

    def __init__(self, case, detail=""):
        super().__init__(f"{case}: {detail}")
        self.case = case
        self.detail = detail


def decode_number(value):
    """Reads a JSON number, or one of the strings the vectors use for non-finite values."""
    if isinstance(value, str):
        return {"NaN": math.nan, "+Infinity": math.inf, "-Infinity": -math.inf}[value]
    return float(value)


def resolve_parameters(raw):
    """Fills in defaults, as the Swift `Codable` decoder does. `fajr` and `isha` are required."""
    p = {
        "fajr": raw["fajr"],
        "isha": raw["isha"],
        "maghrib": raw.get("maghrib", "sunset"),
        "madhab": raw.get("madhab", "shafi"),
        "highLatitudeRule": raw.get("highLatitudeRule", "recommended"),
        "nightSpan": raw.get("nightSpan", "sunsetToFajr"),
        "rounding": raw.get("rounding", "nearest"),
        "ramadanIsha": raw.get("ramadanIsha", "off"),
    }
    for key in ("methodAdjustments", "adjustments"):
        given = raw.get(key, {})
        p[key] = {name: int(given.get(name, 0)) for name in ADJUSTABLE}
    if isinstance(p["ramadanIsha"], dict):
        interval = p["ramadanIsha"]["interval"]
        p["ramadanIsha"] = {
            "interval": {
                "minutes": int(interval["minutes"]),
                "hijriDayOffset": int(interval.get("hijriDayOffset", 0)),
            }
        }
    assert p["madhab"] in ("shafi", "hanafi")
    assert p["highLatitudeRule"] in (
        "recommended",
        "middleOfTheNight",
        "seventhOfTheNight",
        "twilightAngle",
        "disabled",
    )
    assert p["nightSpan"] in ("sunsetToFajr", "sunsetToSunrise")
    assert p["rounding"] in ("nearest", "up", "none")
    return p


def validate(latitude, longitude, day, p):
    """Section 2. Raises CalculationError for the first failing check.

    The vectors never combine two failures, so the order of the checks isn't part of the
    contract.
    """
    if not (math.isfinite(latitude) and math.isfinite(longitude)):
        raise CalculationError("invalidCoordinates", "not finite")
    if not (-90 <= latitude <= 90 and -180 <= longitude <= 180):
        raise CalculationError("invalidCoordinates", "out of range")
    if not (1000 <= day.year <= 3000):
        raise CalculationError("unsupportedDate", str(day.year))

    def angle_ok(a, low_inclusive):
        if not math.isfinite(a):
            return False
        if low_inclusive:
            return 1 <= a <= 30
        return 0 < a <= 30

    fajr = p["fajr"]
    if isinstance(fajr, dict) and not angle_ok(decode_number(fajr["angle"]), True):
        raise CalculationError("invalidParameters", "fajr angle")
    isha = p["isha"]
    if "angle" in isha and not angle_ok(decode_number(isha["angle"]), True):
        raise CalculationError("invalidParameters", "isha angle")
    if "minutesAfterMaghrib" in isha and not (0 <= isha["minutesAfterMaghrib"] <= 1440):
        raise CalculationError("invalidParameters", "isha interval")
    maghrib = p["maghrib"]
    if isinstance(maghrib, dict) and not angle_ok(decode_number(maghrib["angle"]), False):
        raise CalculationError("invalidParameters", "maghrib angle")
    ramadan = p["ramadanIsha"]
    if isinstance(ramadan, dict):
        interval = ramadan["interval"]
        if not (1 <= interval["minutes"] <= 1440):
            raise CalculationError("invalidParameters", "ramadan interval")
        if not (-30 <= interval["hijriDayOffset"] <= 30):
            raise CalculationError("invalidParameters", "ramadan offset")
    # Each set of adjustments is checked on its own; their sum isn't checked, so together they
    # can move an event by up to 2880 minutes.
    for key in ("methodAdjustments", "adjustments"):
        for name, minutes in p[key].items():
            if not (-1440 <= minutes <= 1440):
                raise CalculationError("invalidParameters", f"{key}.{name}")


# ---------------------------------------------------------------------------------------------
# Section 3: time scales
# ---------------------------------------------------------------------------------------------


def utc_datetime(t):
    """The UTC calendar date and time of an instant (seconds since 1970, POSIX)."""
    return _EPOCH + timedelta(seconds=t)


def delta_t(t):
    """ΔT in seconds, from Espenak and Meeus' polynomials at the instant's decimal year."""
    d = utc_datetime(t)
    y = d.year + (d.month - 0.5) / 12
    if y < -500 or y >= 2150:
        u = (y - 1820) / 100
        return -20 + 32 * u * u
    if y < 500:
        u = y / 100
        return (10583.6 - 1014.41 * u + 33.78311 * u**2 - 5.952053 * u**3 - 0.1798452 * u**4
                + 0.022174192 * u**5 + 0.0090316521 * u**6)
    if y < 1600:
        u = (y - 1000) / 100
        return (1574.2 - 556.01 * u + 71.23472 * u**2 + 0.319781 * u**3 - 0.8503463 * u**4
                - 0.005050998 * u**5 + 0.0083572073 * u**6)
    if y < 1700:
        x = y - 1600
        return 120 - 0.9808 * x - 0.01532 * x**2 + x**3 / 7129
    if y < 1800:
        x = y - 1700
        return 8.83 + 0.1603 * x - 0.0059285 * x**2 + 0.00013336 * x**3 - x**4 / 1174000
    if y < 1860:
        x = y - 1800
        return (13.72 - 0.332447 * x + 0.0068612 * x**2 + 0.0041116 * x**3 - 0.00037436 * x**4
                + 0.0000121272 * x**5 - 0.0000001699 * x**6 + 0.000000000875 * x**7)
    if y < 1900:
        x = y - 1860
        return (7.62 + 0.5737 * x - 0.251754 * x**2 + 0.01680668 * x**3 - 0.0004473624 * x**4
                + x**5 / 233174)
    if y < 1920:
        x = y - 1900
        return -2.79 + 1.494119 * x - 0.0598939 * x**2 + 0.0061966 * x**3 - 0.000197 * x**4
    if y < 1941:
        x = y - 1920
        return 21.20 + 0.84493 * x - 0.076100 * x**2 + 0.0020936 * x**3
    if y < 1961:
        x = y - 1950
        return 29.07 + 0.407 * x - x**2 / 233 + x**3 / 2547
    if y < 1986:
        x = y - 1975
        return 45.45 + 1.067 * x - x**2 / 260 - x**3 / 718
    if y < 2005:
        x = y - 2000
        return (
            63.86
            + 0.3345 * x
            - 0.060374 * x**2
            + 0.0017275 * x**3
            + 0.000651814 * x**4
            + 0.00002373599 * x**5
        )
    if y < 2050:
        x = y - 2000
        return 62.92 + 0.32217 * x + 0.005589 * x**2
    return -20 + 32 * ((y - 1820) / 100) ** 2 - 0.5628 * (2150 - y)


# ---------------------------------------------------------------------------------------------
# Section 4: the Sun's position
# ---------------------------------------------------------------------------------------------


def sun(t):
    """Returns (declination δ, right ascension α, apparent sidereal time θ), all in degrees."""
    jd = t / 86400 + 2440587.5
    jde = jd + delta_t(t) / 86400

    T = (jde - 2451545.0) / 36525
    L0 = 280.46646 + 36000.76983 * T + 0.0003032 * T * T
    M = 357.52911 + 35999.05029 * T - 0.0001537 * T * T
    C = (
        (1.914602 - 0.004817 * T - 0.000014 * T * T) * sind(M)
        + (0.019993 - 0.000101 * T) * sind(2 * M)
        + 0.000289 * sind(3 * M)
    )
    true_longitude = L0 + C
    omega = 125.04 - 1934.136 * T
    lam = true_longitude - 0.00569 - 0.00478 * sind(omega)
    eps0 = 23 + 26 / 60 + 21.448 / 3600 - (46.8150 * T + 0.00059 * T * T - 0.001813 * T**3) / 3600
    eps = eps0 + 0.00256 * cosd(omega)
    alpha = math.degrees(math.atan2(cosd(eps) * sind(lam), cosd(lam)))
    delta = math.degrees(math.asin(sind(eps) * sind(lam)))

    Tu = (jd - 2451545.0) / 36525
    theta0 = (
        280.46061837
        + 360.98564736629 * (jd - 2451545.0)
        + 0.000387933 * Tu * Tu
        - Tu**3 / 38710000
    )
    delta_psi = -0.00478 * sind(omega)
    theta = theta0 + delta_psi * cosd(eps)
    return delta, alpha, theta


def hour_angle(t, longitude, position=None):
    """The local hour angle H = normalize180(θ + L - α), in degrees."""
    _, alpha, theta = position if position is not None else sun(t)
    return normalize180(theta + longitude - alpha)


# ---------------------------------------------------------------------------------------------
# Diagnostics: how close a calculation came to a decision another engine might make the other way
# ---------------------------------------------------------------------------------------------


class Diagnostics:
    """Collects the margins the generator uses to reject fragile vectors."""

    def __init__(self):
        # min over every crossing of |c(T) - 1| and |c(A) + 1| (section 6)
        self.min_c_margin = math.inf
        self.min_asr_margin = math.inf  # min of |z - 90| at every Asr computed
        self.unconverged = []  # descriptions of iterations that hit 20 steps

    def note_c(self, c_transit, c_antitransit):
        """Records how close a crossing's existence tests came to deciding the other way.

        Only |c(T) - 1| and |c(A) + 1| decide existence. The starting estimate depends on c(T)
        continuously, so c(T) near -1 isn't a knife edge and isn't tracked.
        """
        self.min_c_margin = min(self.min_c_margin, abs(c_transit - 1), abs(c_antitransit + 1))


# ---------------------------------------------------------------------------------------------
# Section 5: the solar day of a civil day
# ---------------------------------------------------------------------------------------------


def utc_offset(zone, t):
    """The zone's UTC offset in seconds at instant t."""
    return utc_datetime(t).astimezone(zone).utcoffset().total_seconds()


def local_noon(day, zone):
    """Section 5, step 1: n = U - o2."""
    U = (datetime(day.year, day.month, day.day, 12, tzinfo=timezone.utc) - _EPOCH).total_seconds()
    o1 = utc_offset(zone, U)
    o2 = utc_offset(zone, U - o1)
    return U - o2


def transit(day, zone, longitude, diag):
    """Section 5, step 2: the transit nearest local noon."""
    return transit_near(local_noon(day, zone), longitude, diag, f"transit {day}")


def transit_near(start, longitude, diag, label):
    """The transit nearest `start`, by section 5's iteration. Section 5 also uses it for the
    neighboring solar days, from T_D - 86400 and T_D + 86400."""
    t = start
    for _ in range(20):
        step = -hour_angle(t, longitude) / 360 * 86400
        t += step
        if abs(step) < 0.001:
            return t
    diag.unconverged.append(label)
    return t


# ---------------------------------------------------------------------------------------------
# Section 6: altitude crossings
# ---------------------------------------------------------------------------------------------


def crossing(T, altitude, side, latitude, longitude, diag):
    """When the Sun reaches `altitude` before (side -1) or after (side +1) the transit T.

    Existence is decided where the Sun is highest (the transit T) and lowest (the antitransit
    A = T + side × 43200 s), then the iteration finds the instant.
    """
    sin_phi = sind(latitude)
    cos_phi = cosd(latitude)
    sin_h = sind(altitude)

    def c_of(delta):
        return (sin_h - sin_phi * sind(delta)) / (cos_phi * cosd(delta))

    A = T + side * 43200
    c_transit = c_of(sun(T)[0])
    c_antitransit = c_of(sun(A)[0])
    diag.note_c(c_transit, c_antitransit)
    if c_transit > 1:
        return NotOccur(SUN_STAYS_BELOW)  # below the altitude even at the transit
    if c_antitransit < -1:
        return NotOccur(SUN_STAYS_ABOVE)  # above the altitude even at the antitransit

    # The crossing exists. Start from the first estimate, T + side × acos(c(T)): it's A when
    # c(T) <= -1, where the Sun only reaches the altitude near the antitransit. Starting there
    # keeps every step small, so normalize180 never wraps a step half a day the wrong way.
    t = T + side * math.degrees(math.acos(max(-1.0, c_transit))) / 360 * 86400
    for _ in range(20):
        position = sun(t)
        c = min(1.0, max(-1.0, c_of(position[0])))
        H0 = math.degrees(math.acos(c))
        step = normalize180(side * H0 - hour_angle(t, longitude, position)) / 360 * 86400
        t += step
        if abs(step) < 0.001:
            return t
    diag.unconverged.append(f"crossing at {altitude} side {side}")
    return t


# ---------------------------------------------------------------------------------------------
# Section 7: astronomical events
# ---------------------------------------------------------------------------------------------

HORIZON = -50 / 60


def asr_time(T, shadow_factor, latitude, longitude, diag):
    """Asr for shadow factor k (section 7)."""
    delta_T = sun(T)[0]
    z = abs(latitude - delta_T)
    diag.min_asr_margin = min(diag.min_asr_margin, abs(z - 90))
    if z >= 90:
        return NotOccur(SUN_STAYS_BELOW)
    h_asr = math.degrees(math.atan(1 / (shadow_factor + math.tan(math.radians(z)))))
    return crossing(T, h_asr, +1, latitude, longitude, diag)


# ---------------------------------------------------------------------------------------------
# Section 8.6: the Moonsighting Committee's seasonal values
# ---------------------------------------------------------------------------------------------

_MC_COEFFICIENTS = {
    # name: (base, a, b, c, d), each value being base + k * A / 55
    "fajr": (75, 28.65, 19.44, 32.74, 48.10),
    "general": (75, 25.60, 2.050, -9.21, 6.14),
    "ahmer": (62, 17.40, -7.16, 5.12, 19.44),
    "abyad": (75, 25.60, 7.16, 36.84, 81.84),
}


def days_in_year(year):
    return 366 if (year % 4 == 0 and year % 100 != 0) or year % 400 == 0 else 365


def mc_seasonal_minutes(which, day, latitude):
    """S_fajr or S_isha(shafaq) in minutes, unrounded, for civil day `day` (section 8.6)."""
    n = day.timetuple().tm_yday
    Y = days_in_year(day.year)
    if latitude >= 0:
        s = n + 10
        if s >= Y:
            s -= Y
    else:
        s = n - (173 if Y == 366 else 172)
        if s < 0:
            s += Y
    A = abs(latitude)
    base, ka, kb, kc, kd = _MC_COEFFICIENTS[which]
    a = base + ka * A / 55
    b = base + kb * A / 55
    c = base + kc * A / 55
    d = base + kd * A / 55
    if s < 91:
        return a + (b - a) / 91 * s
    if s < 137:
        return b + (c - b) / 46 * (s - 91)
    if s < 183:
        return c + (d - c) / 46 * (s - 137)
    if s < 229:
        return d + (c - d) / 46 * (s - 183)
    if s < 275:
        return c + (b - c) / 46 * (s - 229)
    return b + (a - b) / 91 * (s - 275)


# ---------------------------------------------------------------------------------------------
# Section 8.7: the Umm al-Qura calendar's Ramadan
# ---------------------------------------------------------------------------------------------

# First and last Gregorian days of Ramadan (month 9) in the Umm al-Qura calendar.
#
# Python's standard library has no Umm al-Qura calendar, so this table is embedded. It was
# derived on 2026-10-13 from two independent implementations, which agree on every row:
# - Foundation, `Calendar(identifier: .islamicUmmAlQura)` (Xcode 27.0, macOS 27), scanning
#   every day from 2024-01-01 for month 9;
# - Java 17, `java.time.chrono.HijrahChronology.INSTANCE` (calendar type `islamic-umalqura`,
#   OpenJDK 17.0.20.1), scanning the same days.
# The vectors only use days inside this range. Extend the table (and re-derive it the same way)
# before writing a Ramadan vector for another year.
RAMADAN_UMM_AL_QURA = {
    1445: (date(2024, 3, 11), date(2024, 4, 9)),
    1446: (date(2025, 3, 1), date(2025, 3, 29)),
    1447: (date(2026, 2, 18), date(2026, 3, 19)),
    1448: (date(2027, 2, 8), date(2027, 3, 8)),
    1449: (date(2028, 1, 28), date(2028, 2, 25)),
}
_RAMADAN_TABLE_RANGE = (date(2024, 1, 1), date(2028, 12, 31))


def in_ramadan(day):
    """Whether a civil day falls in month 9 of the Umm al-Qura calendar."""
    if not (_RAMADAN_TABLE_RANGE[0] <= day <= _RAMADAN_TABLE_RANGE[1]):
        raise ValueError(f"{day} is outside the embedded Umm al-Qura table")
    return any(first <= day <= last for first, last in RAMADAN_UMM_AL_QURA.values())


# ---------------------------------------------------------------------------------------------
# Section 8: prayer times for D
# ---------------------------------------------------------------------------------------------


class _SolarDay:
    """The astronomical events of one solar day: its transit, sunrise and sunset.

    `day` is the civil day it stands for (D, D-1 or D+1). That label gives the Moonsighting
    Committee's day of the year (section 8.6) and, for D, the Ramadan rule's day. `T` is given
    for the neighbors, which section 5 finds from T_D rather than from their own local noons.
    """

    def __init__(self, day, latitude, longitude, diag, T):
        self.day = day
        self.T = T
        self.sunrise = crossing(self.T, HORIZON, -1, latitude, longitude, diag)
        self.sunset = crossing(self.T, HORIZON, +1, latitude, longitude, diag)


def _portion(rule, latitude, angle):
    """Section 8.1's table: the portion p of the night for an angle, or None for no bound."""
    if rule == "recommended":
        rule = "seventhOfTheNight" if abs(latitude) > 48 else "middleOfTheNight"
    if rule == "middleOfTheNight":
        return 1 / 2
    if rule == "seventhOfTheNight":
        return 1 / 7
    if rule == "twilightAngle":
        return angle / 60
    return None  # disabled


def _bound_morning(raw, p, sunrise, night_before):
    if p is None or night_before is None:
        return raw
    b = sunrise - p * night_before
    if not occurs(raw) or raw < b:
        return b
    return raw


def _bound_evening(raw, p, sunset, night_after):
    if p is None or night_after is None:
        return raw
    b = sunset + p * night_after
    if not occurs(raw) or raw > b:
        return b
    return raw


def _night(start, end):
    """A night's length, when both its sunset and its sunrise occur."""
    if occurs(start) and occurs(end):
        return end - start
    return None


def _fajr(params, latitude, longitude, solar, sunset_prev, diag, trace=None):
    """Section 8.2. `solar` is the day's solar events; `sunset_prev` the previous sunset.

    A night is defined only when its sunset and sunrise both occur, so the seventh bound exists
    only when sunrise does.
    """
    night_before = _night(sunset_prev, solar.sunrise)
    rule = params["fajr"]
    if rule == "moonsightingCommittee":
        raw = crossing(solar.T, -18, -1, latitude, longitude, diag)
        if trace is not None:
            trace["fajrRaw"] = raw
        # Fajr is the latest of the raw time (if it occurs) and the bounds that exist: the
        # seasonal bound when sunrise occurs, and from 55° (inclusive) the night's last seventh
        # when the night before is defined. With none of them, the raw NOT stands.
        candidates = [raw] if occurs(raw) else []
        if occurs(solar.sunrise):
            candidates.append(
                solar.sunrise - 60 * mc_seasonal_minutes("fajr", solar.day, latitude))
            if abs(latitude) >= 55 and night_before is not None:
                candidates.append(solar.sunrise - night_before / 7)
        return max(candidates) if candidates else raw
    angle = decode_number(rule["angle"])
    raw = crossing(solar.T, -angle, -1, latitude, longitude, diag)
    if trace is not None:
        trace["fajrRaw"] = raw
    p = _portion(params["highLatitudeRule"], latitude, angle)
    return _bound_morning(raw, p, solar.sunrise, night_before)


def _maghrib(params, latitude, longitude, solar, night_after, diag):
    """Section 8.3."""
    rule = params["maghrib"]
    if rule == "sunset":
        return solar.sunset
    angle = decode_number(rule["angle"])
    raw = crossing(solar.T, -angle, +1, latitude, longitude, diag)
    p = _portion(params["highLatitudeRule"], latitude, angle)
    return _bound_evening(raw, p, solar.sunset, night_after)


def _isha(params, latitude, longitude, solar, night_after, maghrib, diag, trace=None):
    """Sections 8.4 and 8.7."""
    rule = params["isha"]
    if "minutesAfterMaghrib" in rule:
        minutes = rule["minutesAfterMaghrib"]
        ramadan = params["ramadanIsha"]
        if isinstance(ramadan, dict) and minutes > 0:
            interval = ramadan["interval"]
            if in_ramadan(solar.day + timedelta(days=interval["hijriDayOffset"])):
                minutes = interval["minutes"]
                if trace is not None:
                    trace["ramadanApplied"] = True
        if not occurs(maghrib):
            return maghrib
        return maghrib + 60 * minutes
    if "moonsightingCommittee" in rule:
        raw = crossing(solar.T, -18, +1, latitude, longitude, diag)
        if trace is not None:
            trace["ishaRaw"] = raw
        # Isha is the earliest of the raw time (if it occurs) and the bounds that exist: the
        # seasonal bound when sunset occurs, and from 55° (inclusive) the end of the night's first
        # seventh when the night after is defined. With none of them, the raw NOT stands.
        shafaq = rule["moonsightingCommittee"]
        candidates = [raw] if occurs(raw) else []
        if occurs(solar.sunset):
            candidates.append(
                solar.sunset + 60 * mc_seasonal_minutes(shafaq, solar.day, latitude))
            if abs(latitude) >= 55 and night_after is not None:
                candidates.append(solar.sunset + night_after / 7)
        return min(candidates) if candidates else raw
    angle = decode_number(rule["angle"])
    raw = crossing(solar.T, -angle, +1, latitude, longitude, diag)
    if trace is not None:
        trace["ishaRaw"] = raw
    p = _portion(params["highLatitudeRule"], latitude, angle)
    return _bound_evening(raw, p, solar.sunset, night_after)


def _round(t, mode):
    """Section 8.9."""
    if mode == "nearest":
        return 60 * math.floor(t / 60 + 0.5)
    if mode == "up":
        return 60 * math.ceil(t / 60)
    return t


class Result:
    """The nine events, plus what the generator needs to judge a vector."""

    def __init__(self):
        self.events = {}  # final values: float instants or NotOccur
        self.unrounded = {}  # values after adjustments, before rounding
        self.trace = {}  # intermediate values worth describing (raw angle times, ...)
        self.diag = Diagnostics()


def prayer_times(latitude, longitude, day, tz_name, raw_params):
    """Computes the nine events of civil day `day` (a datetime.date) in zone `tz_name`.

    Raises CalculationError for invalid input (section 2). Returns a Result.
    """
    latitude = decode_number(latitude)
    longitude = decode_number(longitude)
    params = resolve_parameters(raw_params)
    validate(latitude, longitude, day, params)
    zone = ZoneInfo(tz_name)
    result = Result()
    diag = result.diag
    trace = result.trace

    one = timedelta(days=1)
    T_D = transit(day, zone, longitude, diag)
    # Section 5: the neighboring solar days are the transits nearest T_D -/+ 86400 s.
    T_prev = transit_near(T_D - 86400, longitude, diag, f"transit before {day}")
    T_next = transit_near(T_D + 86400, longitude, diag, f"transit after {day}")
    prev = _SolarDay(day - one, latitude, longitude, diag, T_prev)
    today = _SolarDay(day, latitude, longitude, diag, T_D)
    nxt = _SolarDay(day + one, latitude, longitude, diag, T_next)

    night_after = _night(today.sunset, nxt.sunrise)
    trace["nightBefore"] = _night(prev.sunset, today.sunrise)
    trace["nightAfter"] = night_after

    fajr = _fajr(params, latitude, longitude, today, prev.sunset, diag, trace)
    maghrib = _maghrib(params, latitude, longitude, today, night_after, diag)
    isha = _isha(params, latitude, longitude, today, night_after, maghrib, diag, trace)
    trace["fajr"] = fajr  # before adjustments and rounding
    trace["maghrib"] = maghrib
    trace["isha"] = isha
    trace["transit"] = today.T
    k = 1 if params["madhab"] == "shafi" else 2
    asr = asr_time(today.T, k, latitude, longitude, diag)

    # Section 8.5: the night's end, before adjustments and rounding.
    if params["nightSpan"] == "sunsetToFajr":
        night_end = _fajr(params, latitude, longitude, nxt, today.sunset, diag)
    else:
        night_end = nxt.sunrise
    if not occurs(today.sunset):
        middle = last_third = today.sunset
    elif not occurs(night_end):
        middle = last_third = night_end
    else:
        N = night_end - today.sunset
        middle = today.sunset + N / 2
        last_third = today.sunset + 2 * N / 3

    events = {
        "fajr": fajr,
        "sunrise": today.sunrise,
        "dhuhr": today.T,
        "asr": asr,
        "sunset": today.sunset,
        "maghrib": maghrib,
        "isha": isha,
        "middleOfTheNight": middle,
        "lastThirdOfTheNight": last_third,
    }

    # Section 8.8: adjustments.
    for name in ADJUSTABLE:
        if occurs(events[name]):
            minutes = params["methodAdjustments"][name] + params["adjustments"][name]
            events[name] = events[name] + 60 * minutes

    # Section 8.9: rounding.
    for name in EVENTS:
        result.unrounded[name] = events[name]
        if occurs(events[name]):
            events[name] = _round(events[name], params["rounding"])
    result.events = events
    return result


# ---------------------------------------------------------------------------------------------
# Section 10: Qibla
# ---------------------------------------------------------------------------------------------

KAABA = (21.4225241, 39.8261818)


def central_angle(lat1, lon1, lat2, lon2):
    """The central angle in radians, from unit vectors (accurate near 0 and near π)."""

    def vec(lat, lon):
        return (cosd(lat) * cosd(lon), cosd(lat) * sind(lon), sind(lat))

    a = vec(lat1, lon1)
    b = vec(lat2, lon2)
    cross = (
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
    )
    dot = a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
    return math.atan2(math.sqrt(sum(x * x for x in cross)), dot)


def qibla(latitude, longitude):
    """The Qibla bearing in degrees from true north, or None (section 10)."""
    latitude = decode_number(latitude)
    longitude = decode_number(longitude)
    if not (math.isfinite(latitude) and math.isfinite(longitude)):
        return None
    if not (-90 <= latitude <= 90 and -180 <= longitude <= 180):
        return None
    phi2, L2 = KAABA
    sigma = central_angle(latitude, longitude, phi2, L2)
    if sigma < 1e-9 or abs(math.pi - sigma) < 1e-9:
        return None
    dL = L2 - longitude
    y = sind(dL) * cosd(phi2)
    x = cosd(latitude) * sind(phi2) - sind(latitude) * cosd(phi2) * cosd(dL)
    return normalize360(math.degrees(math.atan2(y, x)))
