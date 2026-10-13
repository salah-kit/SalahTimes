"""Regenerates every vector file in Vectors/ from the reference implementation.

Usage, from the repository root:

    python3 Vectors/reference/generate.py

The output is deterministic: running it twice gives identical files. It refuses to write a
fragile vector (see Vectors/README.md, "Fragility"): a vector whose expected value another
correct engine could reasonably compute differently. A vector marked `move` is moved to the next
day that isn't fragile instead; any other fragile vector stops the generator with an error, so
whoever edits the cases picks another day.

Vectors/times/methods.json depends on Vectors/methods.json. When that file is missing, the
generator leaves methods.json alone and says so.
"""

import json
import math
import os
import sys
from datetime import date, datetime, timedelta, timezone
from zoneinfo import ZoneInfo

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import salahtimes_reference as ref  # noqa: E402

VECTORS = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
SCHEMA_VERSION = 1
REFERENCE = "SalahTimes reference implementation (Vectors/reference/salahtimes_reference.py)"

# Fragility thresholds (Vectors/README.md, "Fragility").
C_MARGIN = 1e-4  # no evaluated c within this of ±1
ASR_MARGIN = 1e-4  # no Asr zenith distance within this many degrees of 90
ALTITUDE_MARGIN = 1e-3  # no h* within this many degrees of the Sun's highest or lowest altitude
ROUNDING_MARGIN = 2.0  # no minute-rounded value within this many seconds of a rounding boundary
MAX_MOVE_DAYS = 14

# ---------------------------------------------------------------------------------------------
# Places
# ---------------------------------------------------------------------------------------------

PLACES = {
    "makkah": ("Makkah", 21.4225, 39.8262, "Asia/Riyadh"),
    "cairo": ("Cairo", 30.0444, 31.2357, "Africa/Cairo"),
    "karachi": ("Karachi", 24.8607, 67.0011, "Asia/Karachi"),
    "tehran": ("Tehran", 35.6892, 51.389, "Asia/Tehran"),
    "istanbul": ("Istanbul", 41.0082, 28.9784, "Europe/Istanbul"),
    "dubai": ("Dubai", 25.2048, 55.2708, "Asia/Dubai"),
    "kuwait-city": ("Kuwait City", 29.3759, 47.9774, "Asia/Kuwait"),
    "doha": ("Doha", 25.2854, 51.531, "Asia/Qatar"),
    "singapore": ("Singapore", 1.3521, 103.8198, "Asia/Singapore"),
    "kuala-lumpur": ("Kuala Lumpur", 3.139, 101.6869, "Asia/Kuala_Lumpur"),
    "jakarta": ("Jakarta", -6.2088, 106.8456, "Asia/Jakarta"),
    "new-york": ("New York", 40.7128, -74.006, "America/New_York"),
    "toronto": ("Toronto", 43.6532, -79.3832, "America/Toronto"),
    "london": ("London", 51.5074, -0.1278, "Europe/London"),
    "tokyo": ("Tokyo", 35.6762, 139.6503, "Asia/Tokyo"),
    "sydney": ("Sydney", -33.8688, 151.2093, "Australia/Sydney"),
    "cape-town": ("Cape Town", -33.9249, 18.4241, "Africa/Johannesburg"),
    "buenos-aires": ("Buenos Aires", -34.6037, -58.3816, "America/Argentina/Buenos_Aires"),
    "santiago": ("Santiago", -33.4489, -70.6693, "America/Santiago"),
    "zurich": ("Zurich", 47.3769, 8.5417, "Europe/Zurich"),
    "paris": ("Paris", 48.8566, 2.3522, "Europe/Paris"),
    "oslo": ("Oslo", 59.9139, 10.7522, "Europe/Oslo"),
    "stockholm": ("Stockholm", 59.3293, 18.0686, "Europe/Stockholm"),
    "helsinki": ("Helsinki", 60.1699, 24.9384, "Europe/Helsinki"),
    "reykjavik": ("Reykjavik", 64.1466, -21.9426, "Atlantic/Reykjavik"),
    "ushuaia": ("Ushuaia", -54.8, -68.3, "America/Argentina/Ushuaia"),
    "punta-arenas": ("Punta Arenas", -53.16, -70.91, "America/Punta_Arenas"),
    "tromso": ("Tromsø", 69.65, 18.96, "Europe/Oslo"),
    "longyearbyen": ("Longyearbyen", 78.22, 15.65, "Arctic/Longyearbyen"),
    "mcmurdo": ("McMurdo Station", -77.85, 166.67, "Antarctica/McMurdo"),
    "north-pole": ("the North Pole", 90.0, 0.0, "Etc/UTC"),
    "south-pole": ("the South Pole", -90.0, 0.0, "Etc/UTC"),
    "near-south-pole": ("89.9975°S, 0°E", -89.9975, 0.0, "Etc/UTC"),
    "lat-86-north": ("86°N, 0°E", 86.0, 0.0, "Etc/UTC"),
    "lat-83-south-120w": ("83°S, 120°W", -83.0, -120.0, "Etc/UTC"),
    "kiritimati": ("Kiritimati", 1.87, -157.4, "Pacific/Kiritimati"),
    "apia": ("Apia", -13.8333, -171.7667, "Pacific/Apia"),
    "nukualofa": ("Nuku'alofa", -21.1394, -175.2049, "Pacific/Tongatapu"),
    "suva": ("Suva", -18.1416, 178.4419, "Pacific/Fiji"),
    "adak": ("Adak", 51.88, -176.6581, "America/Adak"),
    "pago-pago": ("Pago Pago", -14.2756, -170.702, "Pacific/Pago_Pago"),
    "quito": ("Quito", -0.1807, -78.4678, "America/Guayaquil"),
    "nairobi": ("Nairobi", -1.2921, 36.8219, "Africa/Nairobi"),
    "pontianak": ("Pontianak", -0.0263, 109.3425, "Asia/Pontianak"),
    "kashgar": ("Kashgar", 39.47, 75.99, "Asia/Shanghai"),
    "urumqi": ("Ürümqi", 43.8256, 87.6168, "Asia/Shanghai"),
    "lat-55-north": ("55°N, 12°E", 55.0, 12.0, "Europe/Copenhagen"),
    "lat-60-north": ("60°N, 0°E", 60.0, 0.0, "Etc/UTC"),
    "makkah-fixed": ("Makkah", 21.4225, 39.8262, "Etc/GMT-3"),
    "london-fixed": ("London", 51.5074, -0.1278, "Etc/GMT"),
    "lon-plus-180": ("16.5°S, 180°E", -16.5, 180.0, "Etc/GMT-12"),
    "lon-minus-180": ("16.5°S, 180°W", -16.5, -180.0, "Etc/GMT+12"),
    "lat-54.99-north": ("54.99°N, 12°E", 54.99, 12.0, "Europe/Copenhagen"),
    "lat-55-south": ("55°S, 67°W", -55.0, -67.0, "America/Argentina/Ushuaia"),
    "lat-54.99-south": ("54.99°S, 67°W", -54.99, -67.0, "America/Argentina/Ushuaia"),
}

EQUINOXES_AND_SOLSTICES = (date(2026, 3, 20), date(2026, 6, 21), date(2026, 9, 23),
                           date(2026, 12, 21))

MWL = {"fajr": {"angle": 18}, "isha": {"angle": 17}}

# ---------------------------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------------------------


class FragileVector(Exception):
    pass


def iso_instant(t):
    seconds = math.floor(t + 0.5)
    return (datetime(1970, 1, 1, tzinfo=timezone.utc) + timedelta(seconds=seconds)).strftime(
        "%Y-%m-%dT%H:%M:%SZ")


def canonical_parameters(raw):
    """The parameters as written in a vector: every key that matters, defaults included for the
    rules and options, and adjustments and the Ramadan rule only when they're set."""
    p = ref.resolve_parameters(raw)
    out = {
        "fajr": p["fajr"],
        "maghrib": p["maghrib"],
        "isha": p["isha"],
        "madhab": p["madhab"],
        "highLatitudeRule": p["highLatitudeRule"],
        "nightSpan": p["nightSpan"],
    }
    for key in ("methodAdjustments", "adjustments"):
        nonzero = {name: value for name, value in p[key].items() if value != 0}
        if nonzero:
            out[key] = nonzero
    out["rounding"] = p["rounding"]
    if p["ramadanIsha"] != "off":
        out["ramadanIsha"] = p["ramadanIsha"]
    return out


def fragility(result, rounding):
    """Reasons a computed vector is fragile, or an empty list."""
    reasons = []
    diag = result.diag
    if diag.min_c_margin < C_MARGIN:
        reasons.append(f"an existence test is {diag.min_c_margin:.2e} from the threshold")
    if diag.min_asr_margin < ASR_MARGIN:
        reasons.append(f"Asr's zenith distance is {diag.min_asr_margin:.2e}° from 90°")
    if diag.min_altitude_margin < ALTITUDE_MARGIN:
        reasons.append(f"an altitude is {diag.min_altitude_margin:.2e}° from the Sun's highest "
                       "or lowest altitude")
    if diag.unconverged:
        reasons.append("an iteration didn't converge: " + ", ".join(diag.unconverged))
    if diag.path_fragile:
        reasons.append("; ".join(diag.path_fragile))
    if rounding in ("nearest", "up"):
        for name, value in result.unrounded.items():
            if not ref.occurs(value):
                continue
            frac = value - 60 * math.floor(value / 60)
            if rounding == "nearest" and abs(frac - 30) < ROUNDING_MARGIN:
                reasons.append(f"{name} is {frac:.2f}s into its minute, near the :30 boundary")
            if rounding == "up" and (frac < ROUNDING_MARGIN or frac > 60 - ROUNDING_MARGIN):
                reasons.append(f"{name} is {frac:.2f}s into its minute, near the boundary")
    return reasons


def local_text(t, tz):
    return datetime.fromtimestamp(math.floor(t + 0.5), ZoneInfo(tz)).strftime("%Y-%m-%d %H:%M")


def auto_notes(result, place_tz, day, raw_params):
    """Short, generated facts about a vector, appended to its description."""
    notes = []
    events = result.events
    missing = [f"{name} ({events[name].reason})" for name in ref.EVENTS
               if not ref.occurs(events[name])]
    if missing:
        notes.append("Doesn't occur: " + ", ".join(missing) + ".")
    trace = result.trace
    params = ref.resolve_parameters(raw_params)
    for prayer, raw_key in (("fajr", "fajrRaw"), ("isha", "ishaRaw")):
        if raw_key not in trace:
            continue
        raw = trace[raw_key]
        final = trace[prayer]
        if not ref.occurs(final):
            continue
        if not ref.occurs(raw):
            notes.append(f"{prayer.capitalize()}'s angle isn't reached ({raw.reason}); the bound "
                         "gives the time.")
        elif abs(raw - final) > 1e-6:
            notes.append(f"{prayer.capitalize()} is bounded (the angle alone gives "
                         f"{local_text(raw, place_tz)} local).")
        elif NOTE_WITHIN_BOUND[0] and rule_has_bound(params, prayer, result):
            notes.append(f"{prayer.capitalize()}'s angle time is within its bound.")
    bisected = [b[0] for b in result.diag.bisected]
    if bisected:
        shown = []
        for name in ref.EVENTS:
            value = trace.get(name, result.unrounded[name]) if name in ("fajr", "maghrib",
                                                                        "isha") else None
            candidates = [result.unrounded[name]] + ([value] if value is not None else [])
            if any(ref.occurs(v) and any(abs(v - b) < 1e-6 for b in bisected)
                   for v in candidates):
                shown.append(name)
        others = len(bisected) - len(shown)
        text = "The hour-angle iteration doesn't settle, so bisection (algorithm section 6, step "
        text += "3) finds "
        parts = []
        if shown:
            parts.append(", ".join(shown))
        if others > 0:
            parts.append(f"{others} other crossing{'s' if others > 1 else ''} behind the bounds "
                         "or the nights")
        notes.append(text + " and ".join(parts) + ".")
    if trace.get("ramadanApplied"):
        notes.append("The Ramadan interval applies.")
    isha = events["isha"]
    if ref.occurs(isha):
        local_day = datetime.fromtimestamp(isha, ZoneInfo(place_tz)).date()
        if local_day > day:
            notes.append(f"Isha falls after local midnight, at {local_text(isha, place_tz)}.")
    fajr = events["fajr"]
    if ref.occurs(fajr):
        local_day = datetime.fromtimestamp(fajr, ZoneInfo(place_tz)).date()
        if local_day < day:
            notes.append(f"Fajr falls before the day begins, at {local_text(fajr, place_tz)}.")
    return notes


# Whether descriptions say that an angle's time stands within its bound. Only the high-latitude
# file says so; elsewhere it's the normal case and would be noise.
NOTE_WITHIN_BOUND = [False]


def rule_has_bound(params, prayer, result):
    """Whether a bound was computed for this prayer (so 'within its bound' is meaningful)."""
    night = result.trace["nightBefore" if prayer == "fajr" else "nightAfter"]
    if night is None:
        return False
    rule = params[prayer]
    if rule == "moonsightingCommittee" or (isinstance(rule, dict)
                                           and "moonsightingCommittee" in rule):
        return True
    return params["highLatitudeRule"] != "disabled"


# ---------------------------------------------------------------------------------------------
# Vector builders
# ---------------------------------------------------------------------------------------------


class VectorFile:
    def __init__(self, path, description, kind="prayerTimes"):
        self.path = path
        self.description = description
        self.kind = kind
        self.vectors = []

    def write(self):
        document = {
            "schemaVersion": SCHEMA_VERSION,
            "kind": self.kind,
            "description": self.description,
            "vectors": self.vectors,
        }
        full = os.path.join(VECTORS, self.path)
        os.makedirs(os.path.dirname(full), exist_ok=True)
        text = json.dumps(document, indent=2, ensure_ascii=False) + "\n"
        with open(full, "w", encoding="utf-8") as handle:
            handle.write(text)
        return len(self.vectors)


IDS = set()


def claim_id(vector_id):
    if vector_id in IDS:
        raise ValueError(f"duplicate vector id {vector_id}")
    IDS.add(vector_id)
    return vector_id


def time_vector(target, vector_id, description, place, day, parameters=None, method=None,
                overrides=None, tz=None, move=False, source_note=None, check=None,
                as_given=False):
    """Computes one prayer-time vector and appends it to `target`.

    `parameters` gives full parameters; or `method` names a key of Vectors/methods.json, with
    optional `overrides`. `tz` replaces the place's time zone. With `move`, a fragile day moves
    to the next good day (the id and description get the actual date). `check(result)` can
    assert what the vector is meant to show. With `as_given`, the vector writes `parameters`
    exactly as given, so omitted keys exercise the decoder's defaults.
    """
    name, latitude, longitude, place_tz = PLACES[place]
    zone = tz or place_tz
    if method is not None:
        resolved = dict(METHODS[method])
        resolved.update(overrides or {})
    else:
        resolved = parameters
    rounding = ref.resolve_parameters(resolved)["rounding"]
    actual = day
    for _ in range(MAX_MOVE_DAYS + 1):
        result = ref.prayer_times(latitude, longitude, actual, zone, resolved)
        reasons = fragility(result, rounding)
        if not reasons:
            break
        if not move:
            raise FragileVector(f"{vector_id}: " + "; ".join(reasons))
        actual += timedelta(days=1)
    else:
        raise FragileVector(f"{vector_id}: no good day within {MAX_MOVE_DAYS} days")
    if check is not None:
        check(result)
    vector_id = vector_id.replace("{date}", actual.isoformat())
    text = description.replace("{date}", actual.isoformat()).replace("{place}", name)
    notes = auto_notes(result, zone, actual, resolved)
    if actual != day:
        notes.append(f"Moved from {day.isoformat()}, which is fragile under minute rounding.")
    source = REFERENCE
    if source_note:
        source += "; " + source_note
    input_ = {
        "date": actual.isoformat(),
        "timeZone": zone,
        "coordinates": {"latitude": latitude, "longitude": longitude},
    }
    if method is not None:
        input_["method"] = method
        if overrides:
            input_["parameters"] = overrides
    else:
        input_["parameters"] = (dict(resolved) if as_given
                                else canonical_parameters(resolved))
    expected = {}
    for event in ref.EVENTS:
        value = result.events[event]
        expected[event] = (iso_instant(value) if ref.occurs(value)
                           else {"doesNotOccur": value.reason})
    target.vectors.append({
        "id": claim_id(vector_id),
        "description": " ".join([text] + notes),
        "source": source,
        "input": input_,
        "expected": expected,
        "toleranceSeconds": 1,
    })
    return result


def slug(day):
    return day.isoformat()


# ---------------------------------------------------------------------------------------------
# methods.json
# ---------------------------------------------------------------------------------------------

METHODS = {}


def load_methods(path):
    """Reads Vectors/methods.json into {key: parameters}.

    Accepts {"methods": {key: {"parameters": {...}, ...}}}, {"methods": [{"key": .., "parameters":
    ..}]} and {key: {"parameters": ...}}.
    """
    with open(path, encoding="utf-8") as handle:
        data = json.load(handle)
    methods = data.get("methods", data)
    out = {}
    if isinstance(methods, list):
        for entry in methods:
            key = entry.get("key") or entry.get("id") or entry.get("name")
            out[key] = entry["parameters"]
    else:
        for key, entry in methods.items():
            if key in ("schemaVersion", "description"):
                continue
            out[key] = entry["parameters"] if "parameters" in entry else entry
    return out


# The region of each method, a place far from it, and a southern-hemisphere place.
METHOD_PLACES = {
    "muslimWorldLeague": ("london", "tokyo", "cape-town"),
    "isna": ("toronto", "istanbul", "buenos-aires"),
    "egyptian": ("cairo", "new-york", "sydney"),
    "ummAlQura": ("makkah", "london", "jakarta"),
    "karachi": ("karachi", "toronto", "cape-town"),
    "tehran": ("tehran", "london", "sydney"),
    "diyanet": ("istanbul", "tokyo", "buenos-aires"),
    "dubai": ("dubai", "new-york", "sydney"),
    "kuwait": ("kuwait-city", "london", "cape-town"),
    "qatar": ("doha", "toronto", "jakarta"),
    "muis": ("singapore", "london", "sydney"),
    "jakim": ("kuala-lumpur", "istanbul", "cape-town"),
    "kemenag": ("jakarta", "tokyo", "sydney"),
    "moonsightingCommittee": ("london", "karachi", "cape-town"),
}
DEFAULT_METHOD_PLACES = ("makkah", "london", "sydney")


def build_methods():
    f = VectorFile("times/methods.json",
                   "Every method in Vectors/methods.json at its region, a place far from it and a "
                   "southern-hemisphere place, on 2026's equinoxes and solstices, with rounding "
                   "turned off. Each day also appears with the preset exactly as published; when "
                   "minute rounding makes that day fragile, it moves to the next day that isn't.")
    for method in sorted(METHODS):
        for place in METHOD_PLACES.get(method, DEFAULT_METHOD_PLACES):
            for day in EQUINOXES_AND_SOLSTICES:
                time_vector(f, f"method-{method}-{place}-{slug(day)}-unrounded",
                            f"The {method} preset at {{place}} on {{date}}, unrounded.",
                            place, day, method=method, overrides={"rounding": "none"})
                time_vector(f, f"method-{method}-{place}-{{date}}",
                            f"The {method} preset at {{place}} on {{date}}, as published.",
                            place, day, method=method, move=True)
    return f


# ---------------------------------------------------------------------------------------------
# madhab.json
# ---------------------------------------------------------------------------------------------


def build_madhab():
    f = VectorFile("times/madhab.json",
                   "Shafi'i and Hanafi Asr from the equator to the Arctic, in both hemispheres, "
                   "with Muslim World League angles.")
    places = ("singapore", "makkah", "karachi", "cairo", "istanbul", "london", "oslo",
              "reykjavik", "tromso", "cape-town", "ushuaia")
    for place in places:
        for day in EQUINOXES_AND_SOLSTICES:
            for madhab in ("shafi", "hanafi"):
                params = dict(MWL, madhab=madhab, rounding="none")
                time_vector(f, f"madhab-{madhab}-{place}-{slug(day)}",
                            f"{madhab.capitalize()} Asr at {{place}} on {{date}}.",
                            place, day, parameters=params)
    # Minute rounding on a few, moved off rounding boundaries.
    for place in ("makkah", "london"):
        for madhab in ("shafi", "hanafi"):
            params = dict(MWL, madhab=madhab, rounding="nearest")
            time_vector(f, f"madhab-{madhab}-{place}-{{date}}-nearest",
                        f"{madhab.capitalize()} Asr at {{place}} on {{date}}, rounded to the "
                        "nearest minute.", place, date(2026, 5, 1), parameters=params, move=True)
    return f


# ---------------------------------------------------------------------------------------------
# high-latitude.json
# ---------------------------------------------------------------------------------------------

HIGH_LATITUDE_RULES = ("middleOfTheNight", "seventhOfTheNight", "twilightAngle", "recommended",
                       "disabled")


def build_high_latitude():
    f = VectorFile("times/high-latitude.json",
                   "Each high-latitude rule from 48° to 65° north and south, in each season, with "
                   "Muslim World League angles (18° and 17°). Descriptions say where a bound "
                   "applies and where the angle's own time stands.")
    places = ("london", "oslo", "stockholm", "helsinki", "reykjavik", "ushuaia", "punta-arenas")
    NOTE_WITHIN_BOUND[0] = True
    for place in places:
        for day in EQUINOXES_AND_SOLSTICES:
            for rule in HIGH_LATITUDE_RULES:
                params = dict(MWL, highLatitudeRule=rule, rounding="none")
                time_vector(f, f"high-latitude-{rule}-{place}-{slug(day)}",
                            f"The {rule} rule at {{place}} on {{date}}.", place, day,
                            parameters=params)
    # `recommended` resolves by absolute latitude: middle of the night at Zurich (47.4°), the
    # seventh of the night at Paris (48.9°).
    for place, equivalent in (("zurich", "middleOfTheNight"), ("paris", "seventhOfTheNight")):
        day = date(2026, 6, 21)
        a = time_vector(f, f"high-latitude-recommended-{place}-{slug(day)}",
                        f"The recommended rule at {{place}} on {{date}} resolves to {equivalent}.",
                        place, day, parameters=dict(MWL, highLatitudeRule="recommended",
                                                    rounding="none"))
        b = time_vector(f, f"high-latitude-{equivalent}-{place}-{slug(day)}",
                        f"The {equivalent} rule at {{place}} on {{date}}, equal to the "
                        "recommended rule there.", place, day,
                        parameters=dict(MWL, highLatitudeRule=equivalent, rounding="none"))
        assert a.events == b.events, place
    NOTE_WITHIN_BOUND[0] = False
    # The first and last nights of the 18° twilight season at 60° N (algorithm section 6):
    # existence is judged at the antitransit, so the evening crossing after one transit and the
    # morning crossing before the next agree about the night between them. On the night of
    # 21-22 August the Sun first reaches about -18.16°: 21 August's Isha and 22 August's Fajr
    # occur, and the night before, neither does. In April the season ends the same way.
    edge = {"fajr": {"angle": 18}, "isha": {"angle": 18}, "highLatitudeRule": "disabled",
            "rounding": "none"}
    edges = (
        (date(2026, 8, 20), "neither Isha nor the next Fajr: the Sun stays above -18° all night"),
        (date(2026, 8, 21), "Isha occurs, on the first night the Sun reaches -18°; Fajr, on the "
                            "night before, doesn't"),
        (date(2026, 8, 22), "Fajr occurs, ending the night that 21 August's Isha began"),
        (date(2026, 4, 20), "Isha and Fajr occur: the last full night of the season"),
        (date(2026, 4, 21), "Fajr occurs, ending 20 April's night; Isha doesn't, the first "
                            "night the Sun stays above -18°"),
        (date(2026, 4, 22), "neither occurs"),
    )
    for day, what in edges:
        time_vector(f, f"high-latitude-season-edge-lat-60-north-{slug(day)}",
                    f"Fajr and Isha at 18° with no bound at {{place}} on {{date}}: {what}.",
                    "lat-60-north", day, parameters=edge)
    # A Maghrib angle is bounded like Isha.
    for place in ("oslo", "reykjavik"):
        day = date(2026, 6, 21)
        params = {"fajr": {"angle": 17.7}, "maghrib": {"angle": 4.5}, "isha": {"angle": 14},
                  "highLatitudeRule": "seventhOfTheNight", "rounding": "none"}
        time_vector(f, f"high-latitude-maghrib-angle-{place}-{slug(day)}",
                    "Tehran's angles with the seventhOfTheNight rule at {place} on {date}: "
                    "Maghrib's 4.5° angle uses the same bound as Isha.", place, day,
                    parameters=params)
    return f


# ---------------------------------------------------------------------------------------------
# polar.json
# ---------------------------------------------------------------------------------------------


def build_polar():
    f = VectorFile("times/polar.json",
                   "Polar day and polar night: Tromsø, Longyearbyen, McMurdo Station and both "
                   "poles, at the solstices and around the days the Sun stops and starts rising "
                   "or setting. Shows which events don't occur and why.")
    rules = (
        ("mwl", dict(MWL, rounding="none")),
        ("mwl-disabled", dict(MWL, highLatitudeRule="disabled", rounding="none")),
        ("interval", {"fajr": {"angle": 18.5}, "isha": {"minutesAfterMaghrib": 90},
                      "rounding": "none"}),
        ("moonsighting", {"fajr": "moonsightingCommittee",
                          "isha": {"moonsightingCommittee": "general"}, "rounding": "none"}),
    )
    days = {
        "tromso": (date(2026, 6, 21), date(2026, 12, 21),
                   # The last sunset before polar day is on 17 May, the last sunrise on 18 May.
                   # The Sun sets again on 25 July and rises again on 26 July. On 26 July Fajr
                   # still has no night before it: 25 July's sunset came after the night.
                   date(2026, 5, 17), date(2026, 5, 18), date(2026, 5, 19), date(2026, 7, 25),
                   date(2026, 7, 26), date(2026, 7, 27),
                   # Polar night: no sunrise from 28 November; sunrise returns 15 January.
                   date(2026, 11, 27), date(2026, 11, 28), date(2026, 1, 14), date(2026, 1, 15)),
        "longyearbyen": (date(2026, 6, 21), date(2026, 12, 21), date(2026, 4, 18),
                         date(2026, 4, 19), date(2026, 8, 24), date(2026, 8, 25),
                         date(2026, 8, 26),
                         date(2026, 10, 26), date(2026, 10, 27), date(2026, 2, 14),
                         date(2026, 2, 15)),
        "mcmurdo": (date(2026, 6, 21), date(2026, 12, 21), date(2026, 10, 22),
                    date(2026, 10, 23), date(2026, 10, 24), date(2026, 2, 19),
                    date(2026, 2, 20), date(2026, 2, 21),
                    date(2026, 4, 24), date(2026, 4, 25)),
        "north-pole": (date(2026, 6, 21), date(2026, 12, 21)),
        "south-pole": (date(2026, 6, 21), date(2026, 12, 21)),
    }
    for place, place_days in days.items():
        for day in place_days:
            for label, params in rules:
                time_vector(f, f"polar-{label}-{place}-{slug(day)}",
                            f"{label_text(label)} at {{place}} on {{date}}.", place, day,
                            parameters=params)
    # Crossings that the hour-angle iteration can't settle, so bisection finds them (algorithm
    # section 6, step 3): near a pole the declination, not the hour angle, carries the Sun
    # across the altitude.
    # Asr comes within minutes of the transit on the days before polar night, where the
    # declination carries it too.
    disabled = dict(MWL, highLatitudeRule="disabled", rounding="none")
    for place, day, event in (("near-south-pole", date(2026, 3, 22), "sunset"),
                              ("near-south-pole", date(2026, 5, 7), "isha"),
                              ("near-south-pole", date(2026, 8, 1), "fajr"),
                              ("north-pole", date(2026, 3, 18), "sunrise"),
                              ("lat-86-north", date(2026, 10, 2), "asr"),
                              ("lat-83-south-120w", date(2026, 4, 6), "asr")):
        def bisected(result, event=event):
            value = result.trace.get(event, result.unrounded[event])
            assert ref.occurs(value)
            assert any(abs(value - b[0]) < 1e-6 for b in result.diag.bisected), event

        time_vector(f, f"polar-bisection-{event}-{place}-{slug(day)}",
                    f"Muslim World League angles with no high-latitude bound at {{place}} on "
                    f"{{date}}: {event} comes from bisection.", place, day,
                    parameters=disabled, check=bisected)
    # Minute rounding leaves non-occurrence alone.
    time_vector(f, "polar-mwl-nearest-tromso-{date}",
                "Muslim World League angles at {place} on {date}, rounded to the nearest minute.",
                "tromso", date(2026, 6, 21), parameters=dict(MWL, rounding="nearest"), move=True)
    time_vector(f, "polar-mwl-nearest-tromso-winter-{date}",
                "Muslim World League angles at {place} on {date}, rounded to the nearest minute.",
                "tromso", date(2026, 12, 21), parameters=dict(MWL, rounding="nearest"), move=True)
    return f


def label_text(label):
    return {
        "mwl": "Muslim World League angles with the recommended rule",
        "mwl-disabled": "Muslim World League angles with no high-latitude bound",
        "interval": "Umm al-Qura's angle and 90-minute interval",
        "moonsighting": "The Moonsighting Committee's rules",
    }[label]


# ---------------------------------------------------------------------------------------------
# date-line-equator.json
# ---------------------------------------------------------------------------------------------


def build_date_line_equator():
    f = VectorFile("times/date-line-equator.json",
                   "Places near the date line, where the civil day and the UTC day differ most, "
                   "and places on the equator. Muslim World League angles.")
    places = ("kiritimati", "apia", "nukualofa", "suva", "adak", "pago-pago", "quito",
              "singapore", "nairobi", "pontianak")
    for place in places:
        for day in EQUINOXES_AND_SOLSTICES:
            params = dict(MWL, rounding="none")

            def check(result, place=place, day=day):
                if place == "kiritimati":
                    transit_day = ref.utc_datetime(result.trace["transit"]).date()
                    assert transit_day == day - timedelta(days=1), "Kiritimati's transit"

            time_vector(f, f"date-line-equator-{place}-{slug(day)}",
                        "Muslim World League angles at {place} on {date}." + (
                            " The day's transit falls on the previous UTC day."
                            if place == "kiritimati" else ""),
                        place, day, parameters=params, check=check)
        time_vector(f, f"date-line-equator-{place}-{{date}}-nearest",
                    "Muslim World League angles at {place} on {date}, rounded to the nearest "
                    "minute.", place, date(2026, 5, 1), parameters=dict(MWL), move=True)
    # The same coordinates on either side of the date line: Apia's day D (UTC+13) and Pago
    # Pago's day D-1 (UTC-11) are the same solar day.
    day = date(2026, 6, 21)
    a = time_vector(f, f"date-line-apia-coordinates-apia-zone-{slug(day)}",
                    "Apia's coordinates in Pacific/Apia (UTC+13) on {date}.", "apia", day,
                    parameters=dict(MWL, rounding="none"))
    b = time_vector(f, f"date-line-apia-coordinates-pago-pago-zone-{slug(day - timedelta(1))}",
                    "Apia's coordinates in Pacific/Pago_Pago (UTC-11) on {date}: the same "
                    "instants as the day after in Pacific/Apia.", "apia", day - timedelta(1),
                    tz="Pacific/Pago_Pago", parameters=dict(MWL, rounding="none"))
    assert_same_instants(a, b)
    # Samoa skipped 2011-12-30 when it moved across the date line. The skipped day gets the
    # next day's events, and its neighbors keep their real nights (algorithm section 5).
    params = dict(MWL, rounding="none")
    results = {}
    for day, what in ((date(2011, 12, 29), "the last day at UTC-10"),
                      (date(2011, 12, 30), "a day the zone skipped: it gets 31 December's "
                                           "events"),
                      (date(2011, 12, 31), "the first day at UTC+14")):
        results[day] = time_vector(f, f"date-line-apia-skipped-day-{slug(day)}",
                                   f"Muslim World League angles at {{place}} on {{date}}, {what}.",
                                   "apia", day, parameters=params)
    assert_same_instants(results[date(2011, 12, 30)], results[date(2011, 12, 31)])
    return f


def assert_same_instants(a, b):
    for event in ref.EVENTS:
        x, y = a.events[event], b.events[event]
        if ref.occurs(x):
            assert ref.occurs(y) and iso_instant(x) == iso_instant(y), event
        else:
            assert x == y, event


# ---------------------------------------------------------------------------------------------
# dst.json
# ---------------------------------------------------------------------------------------------


def transitions(tz, year):
    """The local days in `year` on which `tz`'s UTC offset changes, with the offsets."""
    zone = ZoneInfo(tz)
    start = datetime(year, 1, 1, tzinfo=timezone.utc)
    out = []
    previous = start.astimezone(zone).utcoffset()
    for hour in range(1, 366 * 24 + 1):
        instant = start + timedelta(hours=hour)
        offset = instant.astimezone(zone).utcoffset()
        if offset != previous:
            out.append((instant.astimezone(zone).date(), previous, offset))
            previous = offset
    return out


def fixed_zone(offset):
    hours = int(offset.total_seconds() // 3600)
    assert offset.total_seconds() == hours * 3600
    if hours == 0:
        return "Etc/GMT"
    # The Etc zones' signs are inverted: Etc/GMT-1 is UTC+1.
    return f"Etc/GMT{-hours:+d}"


def build_dst():
    f = VectorFile("times/dst.json",
                   "Daylight saving time changes, the days around them, and the same days in a "
                   "fixed-offset zone. The instants don't depend on whether the zone observes "
                   "daylight saving time.")
    zones = (("london", "Europe/London"), ("new-york", "America/New_York"),
             ("sydney", "Australia/Sydney"), ("santiago", "America/Santiago"))
    for place, tz in zones:
        changes = transitions(tz, 2026)
        assert len(changes) == 2, (tz, changes)
        for change_day, before, after in changes:
            standard = min(before, after)
            for delta in (-1, 0, 1):
                day = change_day + timedelta(days=delta)
                params = dict(MWL, rounding="none")
                when = {-1: "the day before", 0: "the day of", 1: "the day after"}[delta]
                named = time_vector(
                    f, f"dst-{place}-{slug(day)}",
                    f"{{place}} in {tz} on {{date}}, {when} the change from UTC"
                    f"{offset_text(before)} to UTC{offset_text(after)}.", place, day,
                    parameters=params)
                zones_to_pair = [fixed_zone(standard)]
                if delta == 0:
                    zones_to_pair.append(fixed_zone(max(before, after)))
                for fixed in zones_to_pair:
                    other = time_vector(
                        f, f"dst-{place}-{slug(day)}-{fixed.replace('/', '-').lower()}",
                        f"{{place}}'s coordinates in {fixed} on {{date}}: the same instants as "
                        f"in {tz}.", place, day, tz=fixed, parameters=params)
                    assert_same_instants(named, other)
    return f


def offset_text(offset):
    hours = offset.total_seconds() / 3600
    return f"{hours:+g}"


# ---------------------------------------------------------------------------------------------
# isha-after-midnight.json
# ---------------------------------------------------------------------------------------------


def isha_after_midnight(day):
    def check(result):
        tz = result_zone[0]
        isha = result.events["isha"]
        assert ref.occurs(isha)
        assert datetime.fromtimestamp(isha, ZoneInfo(tz)).date() == day + timedelta(days=1)
    return check


result_zone = [None]


def build_isha_after_midnight():
    f = VectorFile("times/isha-after-midnight.json",
                   "Isha that belongs to day D but falls after local midnight, on D+1: places "
                   "whose clock runs far ahead of the Sun, and bounded Isha in high-latitude "
                   "summers.")
    cases = []
    for place in ("kashgar", "urumqi"):
        for day in (date(2026, 6, 14), date(2026, 6, 21), date(2026, 6, 28)):
            cases.append((place, day, "mwl", dict(MWL, rounding="none")))
            cases.append((place, day, "karachi", {"fajr": {"angle": 18}, "isha": {"angle": 18},
                                                   "rounding": "none"}))
    cases.append(("kashgar", date(2026, 6, 21), "isna",
                  {"fajr": {"angle": 15}, "isha": {"angle": 15}, "rounding": "none"}))
    for place, day in (("london", date(2026, 6, 21)), ("oslo", date(2026, 6, 21)),
                       ("helsinki", date(2026, 6, 21)), ("reykjavik", date(2026, 6, 21)),
                       ("oslo", date(2026, 7, 15))):
        cases.append((place, day, "mwl-middle",
                      dict(MWL, highLatitudeRule="middleOfTheNight", rounding="none")))
    cases.append(("reykjavik", date(2026, 6, 21), "mwl-seventh",
                  dict(MWL, highLatitudeRule="seventhOfTheNight", rounding="none")))
    texts = {
        "mwl": "Muslim World League angles",
        "karachi": "Karachi's 18° angles",
        "isna": "ISNA's 15° angles",
        "mwl-middle": "Muslim World League angles with the middleOfTheNight rule",
        "mwl-seventh": "Muslim World League angles with the seventhOfTheNight rule",
    }
    for place, day, label, params in cases:
        result_zone[0] = PLACES[place][3]
        time_vector(f, f"isha-after-midnight-{label}-{place}-{slug(day)}",
                    f"{texts[label]} at {{place}} on {{date}}.", place, day, parameters=params,
                    check=isha_after_midnight(day))
    return f


# ---------------------------------------------------------------------------------------------
# adjustments-rounding.json
# ---------------------------------------------------------------------------------------------


def build_adjustments_rounding():
    f = VectorFile("times/adjustments-rounding.json",
                   "Method and user adjustments, and the three rounding modes. Sunset and the "
                   "night's divisions never move; an interval Isha counts from Maghrib before "
                   "adjustments; adjustments never make a time occur.")
    method_adj = {"sunrise": -7, "dhuhr": 5, "asr": 4, "maghrib": 7}
    user_adj = {"fajr": 2, "sunrise": 1, "dhuhr": -1, "asr": 3, "maghrib": -2, "isha": 10}
    for place in ("istanbul", "london", "sydney"):
        for rounding in ("none", "nearest", "up"):
            for label, extra in (
                ("method", {"methodAdjustments": method_adj}),
                ("user", {"adjustments": user_adj}),
                ("both", {"methodAdjustments": method_adj, "adjustments": user_adj}),
            ):
                params = dict(MWL, rounding=rounding, **extra)
                time_vector(f, f"adjust-{label}-{rounding}-{place}-{{date}}",
                            f"{label.capitalize()} adjustments at {{place}} on {{date}}, "
                            f"rounding {rounding}.", place, date(2026, 4, 10), parameters=params,
                            move=rounding != "none")
        # Rounding alone.
        for rounding in ("none", "nearest", "up"):
            time_vector(f, f"rounding-{rounding}-{place}-{{date}}",
                        f"No adjustments at {{place}} on {{date}}, rounding {rounding}.", place,
                        date(2026, 8, 3), parameters=dict(MWL, rounding=rounding),
                        move=rounding != "none")
    # Interval Isha counts from Maghrib before Maghrib's adjustments.
    params = {"fajr": {"angle": 18.5}, "isha": {"minutesAfterMaghrib": 90},
              "methodAdjustments": {"maghrib": 5}, "adjustments": {"maghrib": 3, "isha": -4},
              "rounding": "none"}
    time_vector(f, "adjust-interval-isha-makkah-2026-04-10",
                "Umm al-Qura's interval at {place} on {date} with Maghrib moved 8 minutes: Isha is "
                "sunset plus 90 minutes, minus its own 4.", "makkah", date(2026, 4, 10),
                parameters=params)
    # Method and user adjustments are checked separately, so together they can pass 1440.
    params = dict(MWL, methodAdjustments={"fajr": -1000, "isha": 1000},
                  adjustments={"fajr": -1000, "isha": 1000}, rounding="none")
    time_vector(f, "adjust-sum-beyond-limit-makkah-2026-04-10",
                "Method and user adjustments of 1000 minutes each at {place} on {date}: each is "
                "within ±1440, so the input is valid, and Fajr and Isha move by 2000 minutes.",
                "makkah", date(2026, 4, 10), parameters=params)
    # Extreme adjustments at the limits.
    params = dict(MWL, adjustments={"fajr": -1440, "isha": 1440}, rounding="none")
    time_vector(f, "adjust-limits-makkah-2026-04-10",
                "Adjustments at their limits, -1440 and +1440 minutes, at {place} on {date}: "
                "they move Fajr and Isha by a whole day.", "makkah", date(2026, 4, 10),
                parameters=params)
    # Adjustments leave events that don't occur alone.
    params = dict(MWL, methodAdjustments={"sunrise": -7, "maghrib": 7},
                  adjustments={"fajr": 5, "isha": 5}, highLatitudeRule="disabled",
                  rounding="nearest")
    time_vector(f, "adjust-polar-day-tromso-{date}",
                "Adjustments during polar day at {place} on {date}: the events that don't occur "
                "stay that way.", "tromso", date(2026, 6, 21), parameters=params, move=True)
    # Rounding with an adjustment and the Moonsighting Committee's unrounded seasonal bound.
    params = {"fajr": "moonsightingCommittee", "isha": {"moonsightingCommittee": "general"},
              "methodAdjustments": {"dhuhr": 5, "maghrib": 3}, "rounding": "up"}
    time_vector(f, "adjust-moonsighting-up-london-{date}",
                "The Moonsighting Committee's rules with rounding up at {place} on {date}.",
                "london", date(2026, 6, 10), parameters=params, move=True)
    return f


# ---------------------------------------------------------------------------------------------
# ramadan.json
# ---------------------------------------------------------------------------------------------


def build_ramadan():
    f = VectorFile("times/ramadan.json",
                   "The opt-in Ramadan Isha rule. Ramadan 1447 runs from 2026-02-18 to "
                   "2026-03-19 in the Umm al-Qura calendar (Foundation's .islamicUmmAlQura and "
                   "Java's HijrahChronology agree). The rule replaces a positive Isha interval "
                   "on days that fall in Ramadan after adding the Hijri day offset, and nothing "
                   "else.")
    base = {"fajr": {"angle": 18.5}, "isha": {"minutesAfterMaghrib": 90}, "rounding": "none"}
    days = (date(2026, 2, 16), date(2026, 2, 17), date(2026, 2, 18), date(2026, 2, 19),
            date(2026, 3, 5), date(2026, 3, 18), date(2026, 3, 19), date(2026, 3, 20),
            date(2026, 3, 21))
    for day in days:
        time_vector(f, f"ramadan-off-makkah-{slug(day)}",
                    "Umm al-Qura's 90-minute interval at {place} on {date}, with the Ramadan rule "
                    "off.", "makkah", day, parameters=dict(base))
        for offset in (-1, 0, 1):
            params = dict(base, ramadanIsha={"interval": {"minutes": 120,
                                                           "hijriDayOffset": offset}})
            shifted = day + timedelta(days=offset)
            inside = ref.in_ramadan(shifted)

            def check(result, inside=inside):
                assert bool(result.trace.get("ramadanApplied")) == inside

            time_vector(f, f"ramadan-offset{offset:+d}-makkah-{slug(day)}",
                        f"The Ramadan rule (120 minutes, offset {offset:+d}) at {{place}} on "
                        f"{{date}}: {shifted.isoformat()} is "
                        f"{'in' if inside else 'outside'} Ramadan.", "makkah", day,
                        parameters=params, check=check)
    # Ramadan 1448 (2027) and 1446 (2025), at their first and last days.
    for first, last in (ref.RAMADAN_UMM_AL_QURA[1446], ref.RAMADAN_UMM_AL_QURA[1448]):
        for day in (first - timedelta(1), first, last, last + timedelta(1)):
            params = dict(base, ramadanIsha={"interval": {"minutes": 120, "hijriDayOffset": 0}})
            time_vector(f, f"ramadan-offset+0-makkah-{slug(day)}",
                        "The Ramadan rule (120 minutes, offset 0) at {place} on {date}.",
                        "makkah", day, parameters=params)
    # Doha's interval method with the rule, in the middle of Ramadan, rounded.
    params = {"fajr": {"angle": 18}, "isha": {"minutesAfterMaghrib": 90},
              "ramadanIsha": {"interval": {"minutes": 120, "hijriDayOffset": 0}}}
    time_vector(f, "ramadan-qatar-doha-{date}",
                "Qatar's interval with the Ramadan rule at {place} on {date}, rounded to the "
                "nearest minute.", "doha", date(2026, 3, 1), parameters=params, move=True)
    # Angle Isha is never changed by the rule.
    day = date(2026, 3, 5)
    a = time_vector(f, f"ramadan-angle-isha-makkah-{slug(day)}",
                    "Muslim World League's angle Isha at {place} on {date}, in Ramadan, with the "
                    "Ramadan rule on: unchanged.", "makkah", day,
                    parameters=dict(MWL, rounding="none",
                                    ramadanIsha={"interval": {"minutes": 120,
                                                              "hijriDayOffset": 0}}))
    b = time_vector(f, f"ramadan-angle-isha-off-makkah-{slug(day)}",
                    "The same day with the rule off.", "makkah", day,
                    parameters=dict(MWL, rounding="none"))
    assert_same_instants(a, b)
    # An interval of zero isn't replaced.
    params = {"fajr": {"angle": 18.5}, "isha": {"minutesAfterMaghrib": 0}, "rounding": "none",
              "ramadanIsha": {"interval": {"minutes": 120, "hijriDayOffset": 0}}}
    time_vector(f, f"ramadan-zero-interval-makkah-{slug(day)}",
                "An Isha interval of 0 at {place} on {date}, in Ramadan, with the Ramadan rule "
                "on: the rule only replaces a positive interval, so Isha is Maghrib.", "makkah",
                day, parameters=params)
    # The Moonsighting Committee's Isha isn't changed either.
    params = {"fajr": "moonsightingCommittee", "isha": {"moonsightingCommittee": "general"},
              "rounding": "none",
              "ramadanIsha": {"interval": {"minutes": 120, "hijriDayOffset": 0}}}
    time_vector(f, f"ramadan-moonsighting-london-{slug(day)}",
                "The Moonsighting Committee's Isha at {place} on {date}, in Ramadan, with the "
                "Ramadan rule on: unchanged.", "london", day, parameters=params)
    return f


# ---------------------------------------------------------------------------------------------
# custom.json
# ---------------------------------------------------------------------------------------------


def build_custom():
    f = VectorFile("times/custom.json",
                   "Fully custom parameters: other angles, intervals, a Maghrib angle, the "
                   "Moonsighting Committee's rules with each shafaq and with Hanafi Asr, and the "
                   "sunset-to-sunrise night.")
    customs = (
        ("angles-12-12", {"fajr": {"angle": 12}, "isha": {"angle": 12}}),
        ("angles-16-15", {"fajr": {"angle": 16}, "isha": {"angle": 15}}),
        ("interval-75", {"fajr": {"angle": 16}, "isha": {"minutesAfterMaghrib": 75}}),
        ("maghrib-4", {"fajr": {"angle": 18}, "maghrib": {"angle": 4}, "isha": {"angle": 14}}),
        ("maghrib-4-interval-60", {"fajr": {"angle": 18}, "maghrib": {"angle": 4},
                                   "isha": {"minutesAfterMaghrib": 60}}),
        ("angles-1-30", {"fajr": {"angle": 1}, "isha": {"angle": 30}}),
        ("sunset-to-sunrise", dict(MWL, nightSpan="sunsetToSunrise")),
        ("twilight-angle-hanafi", dict(MWL, highLatitudeRule="twilightAngle", madhab="hanafi")),
    )
    for label, params in customs:
        for place in ("cairo", "london", "sydney"):
            for day in (date(2026, 1, 20), date(2026, 7, 20)):
                time_vector(f, f"custom-{label}-{place}-{slug(day)}",
                            f"Custom parameters ({label}) at {{place}} on {{date}}.", place, day,
                            parameters=dict(params, rounding="none"))
    # The Moonsighting Committee's rules, each shafaq, both madhabs, both hemispheres, and both
    # sides of 55°.
    for shafaq in ("general", "ahmer", "abyad"):
        for madhab in ("shafi", "hanafi"):
            for place in ("london", "toronto", "karachi", "cape-town", "oslo", "ushuaia"):
                for day in (date(2026, 2, 1), date(2026, 5, 1), date(2026, 6, 21),
                            date(2026, 11, 1)):
                    params = {"fajr": "moonsightingCommittee",
                              "isha": {"moonsightingCommittee": shafaq}, "madhab": madhab,
                              "rounding": "none"}
                    time_vector(f, f"custom-moonsighting-{shafaq}-{madhab}-{place}-{slug(day)}",
                                f"The Moonsighting Committee's rules with the {shafaq} shafaq and "
                                f"{madhab.capitalize()} Asr at {{place}} on {{date}}.", place,
                                day, parameters=params)
    # Isha by interval after an angle-based Maghrib that doesn't occur while sunset does: Isha
    # takes Maghrib's reason (algorithm sections 8.4 and 9). At Tromsø in late July and early
    # August the Sun sets but stays above -4.5°.
    tehran_interval = {"fajr": {"angle": 17.7}, "maghrib": {"angle": 4.5},
                       "isha": {"minutesAfterMaghrib": 90}, "rounding": "none"}
    for day in (date(2026, 7, 30), date(2026, 8, 3)):
        def unreachable_maghrib(result):
            assert ref.occurs(result.events["sunset"])
            assert result.events["maghrib"] == ref.NotOccur(ref.SUN_STAYS_ABOVE)
            assert result.events["isha"] == ref.NotOccur(ref.SUN_STAYS_ABOVE)

        time_vector(f, f"custom-maghrib-angle-unreached-interval-tromso-{slug(day)}",
                    "Maghrib at 4.5° and Isha 90 minutes after it, with no high-latitude bound, "
                    "at {place} on {date}: the Sun sets but never reaches -4.5°, so Maghrib "
                    "doesn't occur, and Isha takes Maghrib's reason.", "tromso", day,
                    parameters=dict(tehran_interval, highLatitudeRule="disabled"),
                    check=unreachable_maghrib)
        time_vector(f, f"custom-maghrib-angle-bounded-interval-tromso-{slug(day)}",
                    "The same angles with the recommended rule at {place} on {date}: Maghrib is "
                    "bounded by the night's first seventh, and Isha is 90 minutes after that.",
                    "tromso", day, parameters=dict(tehran_interval))
    # The committee's seventh-of-the-night bound starts at 55°, inclusive, in both hemispheres.
    for place, day, seventh_decides in (
        ("lat-55-north", date(2026, 6, 21), True),
        ("lat-54.99-north", date(2026, 6, 21), False),
        ("lat-55-south", date(2026, 12, 21), True),
        ("lat-54.99-south", date(2026, 12, 21), False),
        ("oslo", date(2026, 12, 21), False),
    ):
        for shafaq in ("general", "abyad"):
            params = {"fajr": "moonsightingCommittee", "isha": {"moonsightingCommittee": shafaq},
                      "rounding": "none"}

            def decided_by(result, seventh_decides=seventh_decides, shafaq=shafaq, day=day,
                           place=place):
                latitude = PLACES[place][1]
                trace = result.trace
                sunrise = result.events["sunrise"]
                sunset = result.events["sunset"]
                seasonal_fajr = sunrise - 60 * ref.mc_seasonal_minutes("fajr", day, latitude)
                seasonal_isha = sunset + 60 * ref.mc_seasonal_minutes(shafaq, day, latitude)
                if seventh_decides:
                    assert trace["fajr"] == sunrise - trace["nightBefore"] / 7
                    assert trace["isha"] == sunset + trace["nightAfter"] / 7
                else:
                    assert trace["fajr"] == seasonal_fajr
                    assert trace["isha"] == seasonal_isha

            which = ("the night's seventh decides both Fajr and Isha" if seventh_decides
                     else "the seasonal bounds decide both Fajr and Isha")
            time_vector(f, f"custom-moonsighting-threshold-{shafaq}-{place}-{slug(day)}",
                        f"The Moonsighting Committee's rules with the {shafaq} shafaq at {{place}} "
                        f"on {{date}}: {which}.", place, day, parameters=params,
                        check=decided_by)
    # Vectors that leave out defaulted keys, so a decoder with a wrong default fails. Each is
    # chosen so that any other value of an omitted key changes an expected time: at London in
    # June the recommended rule resolves to the seventh of the night and the bound applies.
    for place, day in (("london", date(2026, 6, 21)), ("oslo", date(2026, 12, 21)),
                       ("cape-town", date(2026, 3, 20))):
        time_vector(f, f"custom-defaults-all-{place}-{{date}}",
                    "Only fajr and isha given at {place} on {date}: maghrib, madhab, "
                    "highLatitudeRule, nightSpan, adjustments, rounding and ramadanIsha take "
                    "their defaults.", place, day, parameters=dict(MWL), as_given=True,
                    move=True)
    explicit = dict(MWL, maghrib="sunset", madhab="shafi", highLatitudeRule="recommended",
                    nightSpan="sunsetToFajr", rounding="none")
    # London (51.5°) resolves `recommended` to the seventh of the night; Zurich (47.4°) to the
    # middle, where a seventh bound would cut Isha short. Between them, every other rule
    # changes an expected time.
    omissions = [(key, "london") for key in ("maghrib", "madhab", "highLatitudeRule",
                                              "nightSpan", "rounding")]
    omissions.insert(3, ("highLatitudeRule", "zurich"))
    written = {}
    for key, place in omissions:
        params = {name: value for name, value in explicit.items() if name != key}
        time_vector(f, f"custom-defaults-omit-{key}-{place}-{{date}}",
                    f"Every key but {key} given at {{place}} on {{date}}: {key} takes its "
                    "default.", place, date(2026, 6, 21), parameters=params, as_given=True,
                    move=key == "rounding")
        written.setdefault(key, []).append(
            (place, date.fromisoformat(f.vectors[-1]["input"]["date"]), params,
             f.vectors[-1]["expected"]))
    # Check the claim: any other value of an omitted key changes an expected time in at least
    # one of the vectors that omit it. Enumerations are checked in full; for `maghrib`, an
    # angle stands for the other case.
    alternatives = {
        "maghrib": [{"angle": 4.5}, {"angle": 1}],
        "madhab": ["hanafi"],
        "highLatitudeRule": ["middleOfTheNight", "seventhOfTheNight", "twilightAngle",
                             "disabled"],
        "nightSpan": ["sunsetToSunrise"],
        "rounding": ["none", "up"],
    }
    for key, values in alternatives.items():
        for value in values:
            changed = False
            for place, day, params, expected in written[key]:
                _, latitude, longitude, zone = PLACES[place]
                other = ref.prayer_times(latitude, longitude, day, zone, dict(params, **{key: value}))
                for event in ref.EVENTS:
                    got = other.events[event]
                    text = (iso_instant(got) if ref.occurs(got)
                            else {"doesNotOccur": got.reason})
                    changed = changed or text != expected[event]
            assert changed, f"{key} = {value} doesn't change any omit-{key} vector"
    # The Moonsighting Committee in a leap year, after 29 February (day-of-year counting).
    for place in ("london", "cape-town"):
        params = {"fajr": "moonsightingCommittee", "isha": {"moonsightingCommittee": "general"},
                  "rounding": "none"}
        for day in (date(2028, 3, 1), date(2028, 12, 31)):
            time_vector(f, f"custom-moonsighting-leap-{place}-{slug(day)}",
                        "The Moonsighting Committee's rules at {place} on {date}, in a leap "
                        "year.", place, day, parameters=params)
    # Both night spans, side by side.
    for span in ("sunsetToFajr", "sunsetToSunrise"):
        for place in ("makkah", "oslo"):
            day = date(2026, 6, 21)
            time_vector(f, f"custom-night-{span}-{place}-{slug(day)}",
                        f"The night from sunset to {'Fajr' if span == 'sunsetToFajr' else 'sunrise'}"
                        " at {place} on {date}.", place, day,
                        parameters=dict(MWL, nightSpan=span, rounding="none"))
    return f


# ---------------------------------------------------------------------------------------------
# ranges.json
# ---------------------------------------------------------------------------------------------


def build_ranges():
    f = VectorFile("times/ranges.json",
                   "The supported range: its first and last days, 1000-01-01 and 3000-12-31, "
                   "proleptic Gregorian dates before 1582, years in several of section 3's ΔT "
                   "polynomials, and the boundary values that section 2 accepts. At the 1 s "
                   "tolerance, only the years 1000, 1300 and 3000 here are sensitive to ΔT.")
    params = dict(MWL, rounding="none")
    years = (
        (date(1000, 1, 1), "makkah-fixed", "the first supported day; ΔT from the 500-1600 "
                                           "polynomial, about 26 minutes"),
        (date(1300, 6, 15), "makkah-fixed", "ΔT from the 500-1600 polynomial"),
        (date(1650, 6, 15), "makkah-fixed", "ΔT from the 1600-1700 polynomial"),
        (date(1750, 6, 15), "london-fixed", "ΔT from the 1700-1800 polynomial"),
        (date(1830, 6, 15), "makkah-fixed", "ΔT from the 1800-1860 polynomial"),
        (date(1880, 6, 15), "london", "ΔT from the 1860-1900 polynomial, in Europe/London"),
        (date(1950, 6, 15), "makkah", "ΔT from the 1941-1961 polynomial, in Asia/Riyadh"),
        (date(2100, 6, 15), "makkah-fixed", "ΔT from the 2050-2150 expression"),
        (date(3000, 12, 31), "makkah-fixed", "the last supported day; ΔT from the parabola"),
    )
    for day, place, what in years:
        time_vector(f, f"range-year-{place.replace('-fixed', '')}-{slug(day)}",
                    f"Muslim World League angles at {{place}} on {{date}}: {what}.", place, day,
                    parameters=params)
    # Longitude ±180 is the same meridian: day D at UTC+12 is the same solar day as D-1 at
    # UTC-12.
    day = date(2026, 3, 20)
    a = time_vector(f, f"range-longitude-plus-180-{slug(day)}",
                    "Longitude 180, the accepted maximum, at {place} in Etc/GMT-12 on {date}.",
                    "lon-plus-180", day, parameters=params)
    b = time_vector(f, f"range-longitude-minus-180-{slug(day - timedelta(1))}",
                    "Longitude -180, the accepted minimum, at {place} in Etc/GMT+12 on {date}: "
                    "the same instants as longitude 180 a day later at UTC+12.", "lon-minus-180",
                    day - timedelta(1), parameters=params)
    assert_same_instants(a, b)
    ramadan_day = date(2026, 3, 5)
    boundaries = (
        ("isha-interval-1440", "An Isha interval of 1440 minutes, the maximum: Isha is a day "
                               "after Maghrib.", date(2026, 4, 10),
         {"fajr": {"angle": 18.5}, "isha": {"minutesAfterMaghrib": 1440}}),
        ("maghrib-angle-30", "A Maghrib angle of 30°, the maximum.", date(2026, 4, 10),
         {"fajr": {"angle": 18}, "maghrib": {"angle": 30}, "isha": {"angle": 17}}),
        ("ramadan-interval-1", "A Ramadan interval of 1 minute, the minimum, in Ramadan.",
         ramadan_day, {"fajr": {"angle": 18.5}, "isha": {"minutesAfterMaghrib": 90},
                       "ramadanIsha": {"interval": {"minutes": 1, "hijriDayOffset": 0}}}),
        ("ramadan-offset-plus-30", "A Hijri day offset of +30, the maximum: 2026-01-20 plus 30 "
                                   "days is 2026-02-19, in Ramadan.", date(2026, 1, 20),
         {"fajr": {"angle": 18.5}, "isha": {"minutesAfterMaghrib": 90},
          "ramadanIsha": {"interval": {"minutes": 120, "hijriDayOffset": 30}}}),
        ("ramadan-offset-minus-30", "A Hijri day offset of -30, the minimum: 2026-04-15 minus 30 "
                                    "days is 2026-03-16, in Ramadan.", date(2026, 4, 15),
         {"fajr": {"angle": 18.5}, "isha": {"minutesAfterMaghrib": 90},
          "ramadanIsha": {"interval": {"minutes": 120, "hijriDayOffset": -30}}}),
    )
    for key, text, day, boundary in boundaries:
        time_vector(f, f"range-{key}-makkah-{slug(day)}", text + " At {place} on {date}.",
                    "makkah", day, parameters=dict(boundary, rounding="none"))
    return f


# ---------------------------------------------------------------------------------------------
# qibla.json
# ---------------------------------------------------------------------------------------------

# Published bearings used as cross-checks (degrees from true north). See the README.
QIBLA_PLACES = (
    ("madinah", "Madinah", 24.4672, 39.6111, None),
    ("jeddah", "Jeddah", 21.5433, 39.1728, None),
    ("riyadh", "Riyadh", 24.7136, 46.6753, None),
    ("cairo", "Cairo", 30.0444, 31.2357, None),
    ("istanbul", "Istanbul", 41.0082, 28.9784, None),
    ("london", "London", 51.5072, -0.1276, None),
    ("new-york", "New York", 40.7128, -74.006, None),
    ("los-angeles", "Los Angeles", 34.0522, -118.2437, None),
    ("toronto", "Toronto", 43.6532, -79.3832, None),
    ("rio-de-janeiro", "Rio de Janeiro", -22.9068, -43.1729, None),
    ("cape-town", "Cape Town", -33.9249, 18.4241, None),
    ("karachi", "Karachi", 24.8607, 67.0011, None),
    ("jakarta", "Jakarta", -6.2088, 106.8456, None),
    ("tokyo", "Tokyo", 35.6762, 139.6503, None),
    ("sydney", "Sydney", -33.8688, 151.2093, None),
    ("auckland", "Auckland", -36.8485, 174.7633, None),
    ("reykjavik", "Reykjavik", 64.1466, -21.9426, None),
    ("anchorage", "Anchorage", 61.2181, -149.9003, None),
    ("honolulu", "Honolulu", 21.3069, -157.8583, None),
    ("papeete", "Papeete, near the antipode", -17.5516, -149.5585, None),
    ("rikitea", "Rikitea, near the antipode", -23.1203, -134.9692, None),
    ("adamstown", "Adamstown, Pitcairn, near the antipode", -25.066, -130.1015, None),
    ("antipode-north", "0.01° north of the antipode", -21.4125241, -140.1738182, None),
    ("antipode-east", "0.01° east of the antipode", -21.4225241, -140.1638182, None),
    ("antipode-3e-7-north", "3e-7° (about 3 cm, 5.2e-9 rad) north of the antipode, beyond the "
     "1e-9 rad threshold", -21.4225238, -140.1738182, None),
    ("north-pole", "the North Pole (longitude 0)", 90.0, 0.0, None),
    ("south-pole", "the South Pole (longitude 0)", -90.0, 0.0, None),
    ("date-line-east", "the date line, longitude 180", 0.0, 180.0, None),
    ("date-line-west", "the date line, longitude -180", 0.0, -180.0, None),
)

QIBLA_NONE = (
    ("kaaba", "the Kaaba itself", 21.4225241, 39.8261818),
    ("antipode", "the Kaaba's antipode", -21.4225241, -140.1738182),
    ("antipode-1e-11", "1e-11° from the Kaaba's antipode, within the 1e-9 rad threshold",
     -21.42252409999, -140.1738182),
    ("latitude-above-90", "a latitude above 90", 90.5, 0.0),
    ("latitude-below-minus-90", "a latitude below -90", -91.0, 0.0),
    ("longitude-above-180", "a longitude above 180", 0.0, 180.5),
    ("longitude-below-minus-180", "a longitude below -180", 0.0, -200.0),
    ("latitude-nan", "a latitude that isn't a number", "NaN", 0.0),
    ("longitude-infinite", "an infinite longitude", 0.0, "+Infinity"),
)

# Published Qibla bearings for cross-checking (fetched 2026-10-13). See the README.
QIBLA_PUBLISHED = {
    "auckland": ("timesprayer.com/en/direction-qibla-auckland.html, fetched 2026-10-13: 261.2° at "
            "(-36.8484597, 174.7633315); the reference gives 261.197° there"),
    "cairo": ("timesprayer.com/en/direction-qibla-cairo.html, fetched 2026-10-13: 136.21° at "
            "(30.05, 31.25); the reference gives 136.207° there"),
    "cape-town": ("timesprayer.com/en/direction-qibla-cape-town.html, fetched 2026-10-13: 23.35° at "
            "(-33.9248685, 18.4240553); the reference gives 23.353° there"),
    "istanbul": ("timesprayer.com/en/direction-qibla-istanbul.html, fetched 2026-10-13: 151.62° at "
            "(41.0082376, 28.9783589); the reference gives 151.621° there"),
    "jakarta": ("timesprayer.com/en/direction-qibla-jakarta.html, fetched 2026-10-13: 295.15° at "
            "(-6.208763, 106.845599); the reference gives 295.152° there"),
    "karachi": ("timesprayer.com/en/direction-qibla-karachi.html, fetched 2026-10-13: 267.74° at "
            "(24.861462, 67.009939); the reference gives 267.744° there"),
    "london": ("timesprayer.com/en/direction-qibla-london.html, fetched 2026-10-13: 118.99° at "
            "(51.5057508064, -0.119819641113); the reference gives 118.994° there"),
    "los-angeles": ("timesprayer.com/en/direction-qibla-los-angeles.html, fetched 2026-10-13: 23.73° at "
            "(34.0632115, -118.366019); the reference gives 23.731° there"),
    "new-york": ("timesprayer.com/en/direction-qibla-new-york.html, fetched 2026-10-13: 58.49° at "
            "(40.75, -73.9967); the reference gives 58.486° there"),
    "tokyo": ("timesprayer.com/en/direction-qibla-tokyo.html, fetched 2026-10-13: 293.04° at "
            "(35.709026, 139.731993); the reference gives 293.042° there"),
    "toronto": ("timesprayer.com/en/direction-qibla-toronto.html, fetched 2026-10-13: 54.58° at "
            "(43.653226, -79.383184); the reference gives 54.581° there"),
}


def build_qibla():
    f = VectorFile("qibla.json",
                   "The Qibla bearing, in degrees clockwise from true north, at places worldwide, "
                   "near the Kaaba's antipode and at the poles, and the inputs with no result.",
                   kind="qibla")
    for key, name, latitude, longitude, _ in QIBLA_PLACES:
        bearing = ref.qibla(latitude, longitude)
        assert bearing is not None
        source = REFERENCE
        if key in QIBLA_PUBLISHED:
            source += "; " + QIBLA_PUBLISHED[key]
        description = f"The Qibla from {name}."
        tolerance = 1e-6
        if key == "antipode-3e-7-north":
            # Due north of the antipode the exact bearing is 0°. In floating point, sin ΔL isn't
            # exactly 0 for ΔL = 180°, and with the place so close to the antipode that residue
            # leaves about 1e-6° that depends on how an engine forms ΔL. The wider tolerance
            # accepts both.
            description += (" The exact bearing is 0°; the formula in floating point gives about "
                            "1.2e-6°, so the tolerance is 1e-5°.")
            tolerance = 1e-5
        f.vectors.append({
            "id": claim_id(f"qibla-{key}"),
            "description": description,
            "source": source,
            "input": {"coordinates": {"latitude": latitude, "longitude": longitude}},
            "expected": {"bearing": round(bearing, 9)},
            "toleranceDegrees": tolerance,
        })
    for key, name, latitude, longitude in QIBLA_NONE:
        assert ref.qibla(latitude, longitude) is None
        f.vectors.append({
            "id": claim_id(f"qibla-none-{key}"),
            "description": f"No Qibla at {name}.",
            "source": "docs/algorithm.md section 10; " + REFERENCE,
            "input": {"coordinates": {"latitude": latitude, "longitude": longitude}},
            "expected": {"bearing": None},
            "toleranceDegrees": 1e-6,
        })
    return f


# ---------------------------------------------------------------------------------------------
# errors.json
# ---------------------------------------------------------------------------------------------


def build_errors():
    f = VectorFile("errors.json",
                   "Inputs that must fail, with the CalculationError case for each check in "
                   "docs/algorithm.md section 2. Each vector breaks exactly one check.",
                   kind="calculationErrors")
    good = {"date": "2026-03-20", "timeZone": "Asia/Riyadh",
            "coordinates": {"latitude": 21.4225, "longitude": 39.8262}}
    ui = {"fajr": {"angle": 18.5}, "isha": {"minutesAfterMaghrib": 90}}
    cases = [
        ("latitude-above-90", "A latitude above 90.", {"coordinates": {"latitude": 90.0001,
                                                                         "longitude": 0}},
         MWL, "invalidCoordinates"),
        ("latitude-below-minus-90", "A latitude below -90.",
         {"coordinates": {"latitude": -91, "longitude": 0}}, MWL, "invalidCoordinates"),
        ("longitude-above-180", "A longitude above 180.",
         {"coordinates": {"latitude": 0, "longitude": 180.0001}}, MWL, "invalidCoordinates"),
        ("longitude-below-minus-180", "A longitude below -180.",
         {"coordinates": {"latitude": 0, "longitude": -181}}, MWL, "invalidCoordinates"),
        ("latitude-nan", "A latitude that isn't a number.",
         {"coordinates": {"latitude": "NaN", "longitude": 0}}, MWL, "invalidCoordinates"),
        ("longitude-infinite", "An infinite longitude.",
         {"coordinates": {"latitude": 0, "longitude": "-Infinity"}}, MWL, "invalidCoordinates"),
        ("year-999", "The year 999, before the supported range.", {"date": "0999-12-31"}, MWL,
         "unsupportedDate"),
        ("year-3001", "The year 3001, after the supported range.", {"date": "3001-01-01"}, MWL,
         "unsupportedDate"),
        ("fajr-angle-below-1", "A Fajr angle below 1.", {},
         {"fajr": {"angle": 0.99}, "isha": {"angle": 17}}, "invalidParameters"),
        ("fajr-angle-above-30", "A Fajr angle above 30.", {},
         {"fajr": {"angle": 30.5}, "isha": {"angle": 17}}, "invalidParameters"),
        ("fajr-angle-nan", "A Fajr angle that isn't a number.", {},
         {"fajr": {"angle": "NaN"}, "isha": {"angle": 17}}, "invalidParameters"),
        ("isha-angle-below-1", "An Isha angle below 1.", {},
         {"fajr": {"angle": 18}, "isha": {"angle": 0}}, "invalidParameters"),
        ("isha-angle-above-30", "An Isha angle above 30.", {},
         {"fajr": {"angle": 18}, "isha": {"angle": 31}}, "invalidParameters"),
        ("isha-angle-infinite", "An infinite Isha angle.", {},
         {"fajr": {"angle": 18}, "isha": {"angle": "+Infinity"}}, "invalidParameters"),
        ("maghrib-angle-zero", "A Maghrib angle of 0 (the range is (0, 30]).", {},
         {"fajr": {"angle": 18}, "maghrib": {"angle": 0}, "isha": {"angle": 14}},
         "invalidParameters"),
        ("maghrib-angle-negative", "A negative Maghrib angle.", {},
         {"fajr": {"angle": 18}, "maghrib": {"angle": -4}, "isha": {"angle": 14}},
         "invalidParameters"),
        ("maghrib-angle-above-30", "A Maghrib angle above 30.", {},
         {"fajr": {"angle": 18}, "maghrib": {"angle": 30.5}, "isha": {"angle": 14}},
         "invalidParameters"),
        ("maghrib-angle-nan", "A Maghrib angle that isn't a number.", {},
         {"fajr": {"angle": 18}, "maghrib": {"angle": "NaN"}, "isha": {"angle": 14}},
         "invalidParameters"),
        ("isha-interval-negative", "A negative Isha interval.", {},
         {"fajr": {"angle": 18.5}, "isha": {"minutesAfterMaghrib": -1}}, "invalidParameters"),
        ("isha-interval-above-1440", "An Isha interval above 1440 minutes.", {},
         {"fajr": {"angle": 18.5}, "isha": {"minutesAfterMaghrib": 1441}}, "invalidParameters"),
        ("ramadan-interval-zero", "A Ramadan interval of 0 (the range is [1, 1440]).", {},
         dict(ui, ramadanIsha={"interval": {"minutes": 0, "hijriDayOffset": 0}}),
         "invalidParameters"),
        ("ramadan-interval-above-1440", "A Ramadan interval above 1440 minutes.", {},
         dict(ui, ramadanIsha={"interval": {"minutes": 1441, "hijriDayOffset": 0}}),
         "invalidParameters"),
        ("ramadan-offset-below-minus-30", "A Hijri day offset below -30.", {},
         dict(ui, ramadanIsha={"interval": {"minutes": 120, "hijriDayOffset": -31}}),
         "invalidParameters"),
        ("ramadan-offset-above-30", "A Hijri day offset above 30.", {},
         dict(ui, ramadanIsha={"interval": {"minutes": 120, "hijriDayOffset": 31}}),
         "invalidParameters"),
    ]
    for field in ref.ADJUSTABLE:
        cases.append((f"adjustment-{field}-above-1440", f"A user adjustment to {field} above "
                      "1440 minutes.", {}, dict(MWL, adjustments={field: 1441}),
                      "invalidParameters"))
        cases.append((f"method-adjustment-{field}-below-minus-1440", "A method adjustment to "
                      f"{field} below -1440 minutes.", {},
                      dict(MWL, methodAdjustments={field: -1441}), "invalidParameters"))
    for key, description, change, params, error in cases:
        input_ = json.loads(json.dumps(good))
        input_.update(change)
        input_["parameters"] = params
        latitude = input_["coordinates"]["latitude"]
        longitude = input_["coordinates"]["longitude"]
        try:
            ref.prayer_times(latitude, longitude, parse_day(input_["date"]), input_["timeZone"],
                             params)
        except ref.CalculationError as failure:
            assert failure.case == error, (key, failure.case)
        else:
            raise AssertionError(f"{key} didn't fail")
        f.vectors.append({
            "id": claim_id(f"error-{key}"),
            "description": description,
            "source": "docs/algorithm.md section 2; " + REFERENCE,
            "input": input_,
            "expected": {"error": error},
        })
    return f


def parse_day(text):
    year, month, day = (int(x) for x in text.split("-"))
    return ref_date(year, month, day)


def ref_date(year, month, day):
    # datetime.date handles 1..9999, which covers the vectors' years.
    return date(year, month, day)


# ---------------------------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------------------------


def main():
    methods_path = os.path.join(VECTORS, "methods.json")
    builders = [build_madhab, build_high_latitude, build_polar, build_date_line_equator,
                build_dst, build_isha_after_midnight, build_adjustments_rounding, build_ramadan,
                build_custom, build_ranges, build_qibla, build_errors]
    counts = {}
    for builder in builders:
        vector_file = builder()
        counts[vector_file.path] = vector_file.write()
    if os.path.exists(methods_path):
        METHODS.update(load_methods(methods_path))
        vector_file = build_methods()
        counts[vector_file.path] = vector_file.write()
    else:
        print("Vectors/methods.json is missing: times/methods.json wasn't regenerated.")
    for path, count in counts.items():
        print(f"{path}: {count} vectors")
    print(f"total: {sum(counts.values())} vectors")


if __name__ == "__main__":
    main()
