# Choosing a method

Pick a published method, then adjust it to what your users' mosques follow.

## Overview

Prayer times depend on choices that scholars and authorities make differently: the Sun's angle
below the horizon at Fajr and Isha, the shadow length for Asr, and the minutes some authorities
add for precaution. A ``CalculationMethod`` packages one authority's choices as
``CalculationParameters``. You can use them as they are, change any value, or build your own.

### Start from a preset

Each case of ``CalculationMethod`` reproduces an authority's published definition. Its
``CalculationMethod/parameters`` property returns the values:

```swift
let mwl = CalculationMethod.muslimWorldLeague.parameters
```

| Method | Fajr | Isha | Notes |
|---|---|---|---|
| ``CalculationMethod/muslimWorldLeague`` | 18° | 17° | |
| ``CalculationMethod/isna`` | 15° | 15° | |
| ``CalculationMethod/egyptian`` | 19.5° | 17.5° | |
| ``CalculationMethod/ummAlQura`` | 18.5° | 90 minutes after Maghrib | |
| ``CalculationMethod/karachi`` | 18° | 18° | |
| ``CalculationMethod/tehran`` | 17.7° | 14° | Maghrib at 4.5° |
| ``CalculationMethod/diyanet`` | 18° | 17° | Precautionary minutes |
| ``CalculationMethod/dubai`` | 18.2° | 18.2° | Precautionary minutes |
| ``CalculationMethod/kuwait`` | 18° | 17.5° | |
| ``CalculationMethod/qatar`` | 18° | 90 minutes after Maghrib | |
| ``CalculationMethod/muis`` | 20° | 18° | |
| ``CalculationMethod/jakim`` | 20° | 18° | |
| ``CalculationMethod/kemenag`` | 20° | 18° | |
| ``CalculationMethod/moonsightingCommittee`` | 18°, seasonal | 18°, seasonal | Its own high-latitude rule |

The repository's
[METHODS.md](https://github.com/salah-kit/SalahTimes/blob/main/METHODS.md) gives every value
with its source. If a value doesn't match what an authority publishes, open an issue with the
`calculation-method` label.

Every preset uses ``HighLatitudeRule/recommended``, ``Madhab/shafi``, no user adjustments,
``Rounding/nearest`` and no Ramadan rule. Change any of them on the returned value.

### Choose the madhab for Asr

``Madhab/shafi`` starts Asr when an object's shadow equals its length plus its noon shadow. This
is the position of the Shafi'i, Maliki, Hanbali and Ja'fari schools. ``Madhab/hanafi`` uses
twice the length, which gives a later Asr:

```swift
var hanafi = CalculationMethod.karachi.parameters
hanafi.madhab = .hanafi
```

The madhab is a user's choice, separate from the method. Many Hanafi users in Pakistan and
India follow Karachi's angles with Hanafi Asr, and many in Turkey follow Diyanet's.

### Add minutes

There are two sets of ``PrayerAdjustments``. ``CalculationParameters/methodAdjustments`` holds
the minutes an authority adds itself, such as Diyanet's and Dubai's precautionary minutes.
``CalculationParameters/adjustments`` holds the user's own. The two add up, and changing one
never erases the other:

```swift
var diyanet = CalculationMethod.diyanet.parameters
diyanet.adjustments.isha = 2
// diyanet.methodAdjustments still holds Diyanet's own minutes.
```

Adjustments move Fajr, sunrise, Dhuhr, Asr, Maghrib and Isha. They don't move sunset or the
night's divisions. A negative value makes a time earlier.

### Choose the rounding

Times are rounded to whole minutes, with ``Rounding/nearest`` by default. ``Rounding/up``
never shows a time earlier than computed, which some timetables prefer. ``Rounding/none``
keeps the seconds, which helps when you compare with another calculation:

```swift
var exact = CalculationMethod.isna.parameters
exact.rounding = .none
```

### Build custom parameters

When no preset fits, give the rules for Fajr and Isha and take the defaults for everything
else:

```swift
let custom = CalculationParameters(
  fajr: .angle(16), isha: .minutesAfterMaghrib(75), madhab: .hanafi)
```

Fajr is a ``FajrRule``, Maghrib a ``MaghribRule`` and Isha an ``IshaRule``. The rules can't
express combinations that mean nothing, such as an Isha angle and an interval at the same time.

The parameters are `Codable`. Their JSON is the form SalahTimes' vectors use. Decoding requires
only `fajr` and `isha`, so settings saved by an older version still decode after a field is
added:

```swift
let json = Data(#"{"fajr": {"angle": 16}, "isha": {"minutesAfterMaghrib": 75}}"#.utf8)
let decoded = try JSONDecoder().decode(CalculationParameters.self, from: json)
```

Parameters don't remember which preset they came from. If your app shows "Muslim World League,
customized", store that choice yourself.

### Suggest a method for a country

``CalculationMethod/suggested(forCountryCode:)`` gives a sourced starting point for a country,
or `nil` when SalahTimes has none:

```swift
let method = CalculationMethod.suggested(forCountryCode: "tr") ?? .muslimWorldLeague
```

A suggestion isn't a ruling. Mosques and communities in one country often follow different
methods, so let users change it. ``CalculationMethod/suggestionsByCountryCode`` lists every
suggestion, and METHODS.md gives the source for each.

### Lengthen Isha in Ramadan

Umm al-Qura's timetables put Isha 120 minutes after Maghrib during Ramadan instead of 90. Some
mosques that follow other interval methods do the same, and others don't. Ramadan's start can
also differ from the calendar by a day. So the rule is off by default, and you opt in:

```swift
var ummAlQura = CalculationMethod.ummAlQura.parameters
ummAlQura.ramadanIsha = .interval(minutes: 120, hijriDayOffset: 0)
```

``RamadanIshaRule/interval(minutes:hijriDayOffset:)`` changes only an Isha that's a positive
interval after Maghrib, on days in Ramadan in the Umm al-Qura calendar. An offset of 1 treats
Ramadan as starting a day earlier than the calendar. Angle-based Isha never changes.

## See Also

- <doc:HighLatitudes>
- ``CalculationParameters``
