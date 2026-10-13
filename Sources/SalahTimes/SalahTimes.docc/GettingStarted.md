# Getting started

Add SalahTimes to a project, compute a day's prayer times and read them.

## Overview

This article walks through a complete calculation: the package, the inputs, the results, the
events that don't occur, and the Qibla.

### Add the package

Add SalahTimes to your `Package.swift`, then add `import SalahTimes` to the files that use it:

```swift
dependencies: [
  .package(url: "https://github.com/salah-kit/SalahTimes.git", from: "0.1.0")
],
targets: [
  .target(name: "MyApp", dependencies: ["SalahTimes"])
]
```

In Xcode, choose File > Add Package Dependencies and enter the same URL.

### Compute a day's times

A calculation takes four inputs: the place's ``Coordinates``, the ``GregorianDay`` you want, the
time zone that defines that day, and the ``CalculationParameters``. This computes Istanbul's
times for 20 March 2026 with Diyanet's method:

```swift
let istanbul = TimeZone(identifier: "Europe/Istanbul")!
let times = try PrayerTimes(
  coordinates: Coordinates(latitude: 41.0082, longitude: 28.9784),
  day: GregorianDay(year: 2026, month: 3, day: 20)!,
  timeZone: istanbul,
  parameters: CalculationMethod.diyanet.parameters)
```

Use the location's time zone, not the device's. A traveller in London looking at Istanbul's
times wants Istanbul's 20 March. The time zone picks the right solar day, which matters most
near the date line.

To compute for today, ask for the day that contains now in that time zone:

```swift
let today = GregorianDay(containing: Date(), in: istanbul)
```

The initializer throws ``CalculationError`` when the coordinates or the parameters are out of
range, or the year is outside 1000 to 3000. It never throws because of the season or the
latitude.

### Read the results

Each event is an ``EventTime``. Its ``EventTime/date`` is the instant, or `nil` when the event
doesn't occur. The instant is a `Date`, so you format it in whatever time zone and calendar
your app shows:

```swift
if let maghrib = times.maghrib.date {
  let formatter = DateFormatter()
  formatter.timeStyle = .short
  formatter.timeZone = istanbul
  print("Maghrib", formatter.string(from: maghrib))
}
```

You can also read events by ``PrayerTimes/Event``, through the subscript, in the order they
normally occur: `for event in PrayerTimes.Event.allCases { print(times[event]) }`.

### Handle events that don't occur

Some events don't happen on some days. On the June solstice in Tromsø, the Sun doesn't set, so
there's no sunset, no Maghrib and no Isha. SalahTimes doesn't invent a time. It returns
``EventTime/doesNotOccur(_:)`` with the reason:

```swift
let tromso = try PrayerTimes(
  coordinates: Coordinates(latitude: 69.6492, longitude: 18.9553),
  day: GregorianDay(year: 2026, month: 6, day: 21)!,
  timeZone: TimeZone(identifier: "Europe/Oslo")!,
  parameters: CalculationMethod.muslimWorldLeague.parameters)

switch tromso.isha {
case .occurs(let date):
  print("Isha", date)
case .doesNotOccur(.sunStaysAbove):
  print("The Sun doesn't set tonight, so there's no Isha.")
case .doesNotOccur(.sunStaysBelow):
  print("The Sun doesn't rise high enough for Isha.")
}
```

``NonOccurrence/sunStaysAbove`` means the Sun never descends to the event's altitude, and
``NonOccurrence/sunStaysBelow`` means it never climbs to it. Decide what your app shows in
each case. <doc:HighLatitudes> explains when this happens and how the high-latitude rules
reduce it.

### Know which day an event belongs to

Every event in a ``PrayerTimes`` value belongs to its ``PrayerTimes/day``, even when its instant
falls on the next or previous civil day. The middle of the night and its last third usually
fall after midnight. Isha can too: Kashgar keeps China Standard Time, about three hours ahead
of its Sun, so its summer Isha comes after midnight:

```swift
let kashgarZone = TimeZone(identifier: "Asia/Shanghai")!
let kashgar = try PrayerTimes(
  coordinates: Coordinates(latitude: 39.4704, longitude: 75.9898),
  day: GregorianDay(year: 2026, month: 6, day: 21)!,
  timeZone: kashgarZone,
  parameters: CalculationMethod.muslimWorldLeague.parameters)

if let isha = kashgar.isha.date {
  let civilDay = GregorianDay(containing: isha, in: kashgarZone)
  print(kashgar.day, civilDay)  // 2026-06-21 2026-06-22
}
```

That Isha is the Isha of 21 June. A list of the day's prayers should show it last, and a
countdown after midnight should still count down to it. SalahTimes never moves an event to
another day or reorders events.

### Find the Qibla

``Qibla/direction(from:)`` gives the direction of the Kaaba in degrees clockwise from true
north:

```swift
let london = Coordinates(latitude: 51.5072, longitude: -0.1276)
if let bearing = Qibla.direction(from: london) {
  print("Qibla: \(Int(bearing.rounded()))° from true north")  // 119°
}
```

The bearing is relative to true north. A compass shows magnetic north, so correct for the
magnetic declination before you point a compass needle. The result is `nil` for invalid
coordinates, and at the Kaaba itself.

## See Also

- <doc:ChoosingAMethod>
- <doc:HighLatitudes>
