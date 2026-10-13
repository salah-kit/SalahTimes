# Validation

How SalahTimes checks that its times are right.

## Overview

A prayer time is only useful if people can trust it. SalahTimes checks its results in five
ways. The vectors, the parity checks, the self-consistency and property tests, and the
comparison with Singapore's open timetable run in CI on macOS and Linux. The other official
timetables can't be redistributed, so their comparison runs on a local download. The
repository's
[docs/validation.md](https://github.com/salah-kit/SalahTimes/blob/main/docs/validation.md)
gives the current numbers: how many cases each check covers, and the largest differences
found.

### Vectors from an independent reference

The repository's `docs/algorithm.md` specifies the calculation step by step. A separate
reference implementation in Python, written from that document and not from the Swift code,
generates the JSON vectors in `Vectors/`. Each vector names its inputs, the expected times and
where the expectation comes from. The Swift engine must match every vector within its
tolerance.

The vectors cover the methods, both madhabs, the high-latitude rules and adjustments, at
places from the equator to the polar regions in both hemispheres. Each expected time is a UTC
instant, or a reason the event doesn't occur. Engines in other languages can check themselves against the same files.
[Vectors/README.md](https://github.com/salah-kit/SalahTimes/blob/main/Vectors/README.md)
documents the schema.

### Parity with adhan-swift

adhan-swift is the library that many Swift prayer apps use today. SalahTimes runs adhan-swift's
MIT-licensed test data, its expected times for many cities and methods, and compares the
results. Every prayer agrees within one minute, except four published times that are two
minutes off, each for a reason the tests record, such as a timetable row that's late for both
Fajr and sunrise. SalahTimes contains none of adhan-swift's code.

### Official timetables

Authorities such as Diyanet, JAKIM, MUIS, Umm al-Qura and Kemenag publish timetables computed
with their own methods. SalahTimes compares a sample of them with its presets. This checks the
method values and the precautionary minutes, not only the astronomy. Official tables often add
minutes of their own, so the comparison measures them before calling a difference an error.
[METHODS.md](https://github.com/salah-kit/SalahTimes/blob/main/METHODS.md) names each source.

### Self-consistency

The results are checked against the geometry they come from. At each computed Fajr and Isha,
the Sun's altitude equals the method's angle within a stated tolerance. At Asr, an object's
shadow has the length the madhab requires.

### Properties

Property tests check what must always hold:

- Events stay in order.
- Times change continuously from one day to the next.
- Instants don't change across daylight saving transitions.
- Polar day and polar night behave as <doc:HighLatitudes> describes, in Tromsø and Svalbard in
  June and December.
- The equator and places near the date line work.
- Southern high latitudes work, in Ushuaia and Punta Arenas.

### Report a difference

If SalahTimes disagrees with your mosque's timetable, open an issue with the `timetable` label.
Include the place, the date, the method you used and a link to the timetable. If a method's
values are wrong, use the `calculation-method` label.

## See Also

- <doc:ChoosingAMethod>
