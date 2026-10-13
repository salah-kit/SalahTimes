# ``SalahTimes``

Compute prayer times, high-latitude adjustments and the Qibla, with no dependencies.

## Overview

SalahTimes computes the five daily prayers, sunrise, sunset, and the night's middle and last
third for one civil day at one place. You give it coordinates, a day, the location's time zone
and a calculation method. It gives you instants, as `Date` values, and you format them however
your app needs.

SalahTimes is written from published astronomy and from each method's published definition.
The repository's `docs/algorithm.md` specifies every step, and JSON vectors from an independent
reference implementation check the results, so engines in other languages can reproduce them.

A few principles shape the API:

- **The owning day is the day you asked for.** An Isha after midnight still belongs to the
  evening before. See ``PrayerTimes``.
- **Nothing is invented.** An event that doesn't happen, such as sunset during polar day, is
  ``EventTime/doesNotOccur(_:)`` with a ``NonOccurrence`` reason.
- **Methods are presets.** A ``CalculationMethod`` gives ``CalculationParameters`` that you can
  change, or you can build your own.
- **High latitudes are handled by default.** ``HighLatitudeRule/recommended`` bounds Fajr and
  Isha where twilight lasts all night, in both hemispheres.
- **Everything is a value.** Every type is `Sendable`, and the engine has no shared state, so
  widgets and background tasks can compute concurrently.

SalahTimes doesn't find the user's location, format times, convert to Hijri dates or play
audio. The [salah-kit](https://github.com/salah-kit) ecosystem's SalahKit does the app work on
top of it.

## Topics

### Essentials

- <doc:GettingStarted>
- ``PrayerTimes``
- ``Coordinates``
- ``GregorianDay``

### Results

- ``EventTime``
- ``NonOccurrence``
- ``CalculationError``

### Methods and parameters

- <doc:ChoosingAMethod>
- ``CalculationMethod``
- ``CalculationParameters``
- ``FajrRule``
- ``MaghribRule``
- ``IshaRule``
- ``Shafaq``
- ``Madhab``
- ``PrayerAdjustments``
- ``Rounding``
- ``NightSpan``
- ``RamadanIshaRule``

### High latitudes

- <doc:HighLatitudes>
- ``HighLatitudeRule``

### Qibla

- ``Qibla``

### Accuracy

- <doc:Validation>
