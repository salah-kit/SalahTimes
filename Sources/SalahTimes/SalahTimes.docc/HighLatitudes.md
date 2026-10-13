# High latitudes

Keep Fajr and Isha reasonable where twilight lasts long or all night.

## Overview

Most methods define Fajr and Isha by the Sun's angle below the horizon, such as 18°. Far from
the equator in summer, the Sun sets but never sinks that far. Twilight lasts all night, and the
angle gives no Fajr or Isha at all. Nearby, in the weeks around that period, the angle gives an
Isha close to midnight and a Fajr soon after it.

Around the summer solstice this starts at about 48.6° of latitude for an 18° angle, which
includes Paris, London, Berlin, Edmonton and all of Scandinavia.
In the southern hemisphere it includes Ushuaia and the south of Chile and Argentina.

A high-latitude rule bounds Fajr and Isha by a portion of the night, so they stay usable.

### How the rules work

Each rule takes a portion of the night, measured from sunset to sunrise. Fajr is no earlier
than sunrise minus that portion, and Isha is no later than sunset plus it. A rule replaces the
angle's time only when that time is beyond the bound or doesn't exist. On an ordinary night
the angle's time stands.

| Rule | Portion of the night |
|---|---|
| ``HighLatitudeRule/middleOfTheNight`` | One half. Isha no later, and Fajr no earlier, than the middle of the night. |
| ``HighLatitudeRule/seventhOfTheNight`` | One seventh. |
| ``HighLatitudeRule/twilightAngle`` | The angle divided by 60, so 18° gives 18/60 of the night. |
| ``HighLatitudeRule/disabled`` | No bound. The angle alone decides. |

An Isha defined as minutes after Maghrib is never bounded, because the methods that use it
publish it that way.

### The recommended rule

Every preset uses ``HighLatitudeRule/recommended``. It resolves to
``HighLatitudeRule/seventhOfTheNight`` beyond 48° of latitude and to
``HighLatitudeRule/middleOfTheNight`` elsewhere. It uses the absolute latitude, so southern
places work the same way as northern ones:

```swift
let ushuaia = Coordinates(latitude: -54.8019, longitude: -68.3030)
let rule = HighLatitudeRule.recommended(for: ushuaia)  // .seventhOfTheNight
```

Below 48°, the middle of the night only matters as a safety net: the angle's time almost always
stands.

### Each prayer uses its own night

Fajr uses the night that ends at its own sunrise. Isha uses the night that starts at its own
sunset. In spring and autumn at high latitudes, nights change length quickly. If both prayers
used the same night, a bounded Fajr could fall before the previous evening's bounded Isha. With
each prayer's own night, the middle-of-the-night rule makes Isha and the next Fajr meet at the
same instant instead of crossing.

### Compare a bounded and an unbounded day

In Tromsø in August, the Sun sets but stays within about 5° of the horizon all night. With a
rule, Isha comes a seventh of the night after sunset. With ``HighLatitudeRule/disabled``, there's
no Isha:

```swift
let oslo = TimeZone(identifier: "Europe/Oslo")!
let tromso = Coordinates(latitude: 69.6492, longitude: 18.9553)
let august = GregorianDay(year: 2026, month: 8, day: 10)!

var bounded = CalculationMethod.muslimWorldLeague.parameters
bounded.highLatitudeRule = .seventhOfTheNight
var unbounded = bounded
unbounded.highLatitudeRule = .disabled

let withRule = try PrayerTimes(
  coordinates: tromso, day: august, timeZone: oslo, parameters: bounded)
let withoutRule = try PrayerTimes(
  coordinates: tromso, day: august, timeZone: oslo, parameters: unbounded)
// withRule.isha occurs a seventh of the night after sunset.
// withoutRule.isha is .doesNotOccur(.sunStaysAbove).
```

``HighLatitudeRule/disabled`` is for apps that would rather tell the user "Isha doesn't occur
tonight" and apply their own policy, such as the times of the nearest latitude where it does.

### Polar day and polar night

A bound needs a night, from a sunset to a sunrise. During polar day there's no sunset, so no
rule can help: sunset, Maghrib, Isha and the night's divisions are
``EventTime/doesNotOccur(_:)`` with ``NonOccurrence/sunStaysAbove``. Dhuhr occurs, and Asr
usually does.

During polar night there's no sunrise or sunset. Sunrise, sunset, Maghrib and Asr don't occur,
with ``NonOccurrence/sunStaysBelow``. Dhuhr is still the Sun's transit, below the horizon. Fajr
and Isha occur whenever the Sun still climbs past their angles:

```swift
let december = try PrayerTimes(
  coordinates: tromso, day: GregorianDay(year: 2026, month: 12, day: 21)!,
  timeZone: oslo, parameters: bounded)
// december.sunrise and december.sunset are .doesNotOccur(.sunStaysBelow).
// december.dhuhr occurs: it's the Sun's transit, below the horizon.
```

SalahTimes reports these days as they are. Some scholars recommend following the times of the
nearest day or the nearest latitude where the prayers occur. That's a policy your app can apply
on top of the typed results.

### The Moonsighting Committee's own rule

The Moonsighting Committee's method doesn't use ``CalculationParameters/highLatitudeRule``.
``FajrRule/moonsightingCommittee`` and ``IshaRule/moonsightingCommittee(_:)`` apply the
committee's seasonal limits instead. Below 55° of latitude, Fajr is no earlier, and Isha no
later, than a number of minutes from sunrise or sunset that changes through the year. Beyond
55°, they use a seventh of the night. ``Shafaq`` chooses which twilight ends Isha.

## See Also

- <doc:ChoosingAMethod>
- ``HighLatitudeRule``
- ``NonOccurrence``
