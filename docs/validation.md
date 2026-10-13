# Validating SalahTimes

How SalahTimes' results were checked, what the checks found, and how to repeat them.

## Summary

TODO (phase 2): one paragraph of results once the engine runs.

## Astronomy cross-checks

`SelfConsistencyTests.swift` carries its own solar model, written from NOAA's "General Solar Position Calculations" and the NOAA Solar Calculator spreadsheet. It computes the hour angle from the equation of time, where the engine uses right ascension and sidereal time (algorithm.md §4), and it checks itself against Meeus's worked examples 25.a and 28.b.

TODO (phase 2): results.

## adhan-swift parity

Data: the eight timetables in adhan-swift's `Tests/Resources/Times/` at commit `a6fa2de`, MIT licensed, copied to `Tests/Data/adhan-swift/` with the licence. Several were "adjusted +/- 1 or 2 minutes" by adhan-swift's authors to agree with their library.

Method: `AdhanParityTests.swift` maps each file's method to the SalahTimes preset (UmmAlQura to `ummAlQura`, Turkey to `diyanet`, Singapore to `muis`, MoonsightingCommittee to `moonsightingCommittee`, and so on), takes the file's madhab and high-latitude rule, computes every listed day and checks each prayer within one minute.

TODO (phase 2): per-file results and every known difference.

## Official timetables

Sources, URLs, retrieval dates, reference coordinates and licences: `Validation/official-timetables/README.md` and `sources.json`. Nine timetables cover all of 2026: Diyanet (Istanbul, Ankara), JAKIM (WLY01), MUIS (Singapore), Umm al-Qura (Makkah, Riyadh), Kemenag (Jakarta) and moonsighting.com (London, two methods). Only MUIS's data may be redistributed; it's committed.

TODO (phase 2): offsets per prayer and their interpretation.

## Self-consistency

TODO (phase 2): maxima.

## Properties

`PropertyTests.swift` checks order, continuity, DST independence, polar regimes, the equator and the date line, and southern high latitudes.

TODO (phase 2): results.

## Benchmark

TODO (phase 2): debug and release numbers.

## Known limitations

TODO (phase 2).

## Reproducing

TODO (phase 2): commands.
