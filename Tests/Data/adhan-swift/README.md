# adhan-swift test data

These eight JSON files are copied unchanged from adhan-swift's `Tests/Resources/Times/` directory:

- Repository: https://github.com/batoulapps/adhan-swift
- Commit: `a6fa2deee80c5abb0b9ad04466f8ab12b53144e7` (2026-06-11)
- License: MIT, Copyright (c) 2016 Batoul Apps. The license text is in `LICENSE` next to this file.

Only the data is used. No adhan-swift code is copied or read.

Each file lists a place, a calculation method, a madhab and a high-latitude rule (`params`), the published timetable it was taken from (`source`), and local times for a set of days (`times`). Several files say "adjusted +/- 1 minute" or "+/- 2 minutes": adhan-swift's authors moved some published times by a minute or two so the data agrees with their library. The data therefore describes adhan-swift's output more closely than the original timetables.

`Tests/SalahTimesTests/AdhanParityTests.swift` reads these files; `docs/validation.md` reports the results.
