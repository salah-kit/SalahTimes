# Wide scan

Written by `WideScanTests.swift` (`SALAHTIMES_WIDE_SCAN=1 swift test -j 4 --filter WideScan`). Every preset at every whole latitude from 66° S to 70° N, every day of 2026, with times rounded as each preset ships. Ties and inversions compare consecutive prayers that occur (Fajr, sunrise, Dhuhr, Asr, Maghrib, Isha). "Before its day" is an event whose instant precedes the start of its civil day in the place's zone. "Days" counts latitude-days.

| Setup | Place | Finding | Events | Latitudes | Days |
|---|---|---|---|---|---|
| `muslimWorldLeague` | Europe/Oslo, 31.1° E | before its day | Fajr | -66° to -64°, -48° to -47° | 112 |
| `muslimWorldLeague` | Europe/Oslo, 31.1° E | before its day | sunrise | -66° to -65° | 32 |
| `muslimWorldLeague` | Europe/Oslo, 31.1° E | tie | Dhuhr = Asr | 68° to 70° | 3 |
| `muslimWorldLeague` | UTC, 0° | tie | Dhuhr = Asr | 67° to 70° | 5 |
| `isna` | Europe/Oslo, 31.1° E | before its day | Fajr | -66° to -64° | 76 |
| `isna` | Europe/Oslo, 31.1° E | before its day | sunrise | -66° to -65° | 32 |
| `isna` | Europe/Oslo, 31.1° E | tie | Dhuhr = Asr | 68° to 70° | 3 |
| `isna` | UTC, 0° | tie | Dhuhr = Asr | 67° to 70° | 5 |
| `egyptian` | Europe/Oslo, 31.1° E | before its day | Fajr | -66° to -64°, -48° to -46°, 48° | 218 |
| `egyptian` | Europe/Oslo, 31.1° E | before its day | sunrise | -66° to -65° | 32 |
| `egyptian` | Europe/Oslo, 31.1° E | tie | Dhuhr = Asr | 68° to 70° | 3 |
| `egyptian` | UTC, 0° | before its day | Fajr | -48°, 48° | 24 |
| `egyptian` | UTC, 0° | tie | Dhuhr = Asr | 67° to 70° | 5 |
| `ummAlQura` | Europe/Oslo, 31.1° E | before its day | Fajr | -66° to -64°, -48° to -47° | 138 |
| `ummAlQura` | Europe/Oslo, 31.1° E | before its day | sunrise | -66° to -65° | 32 |
| `ummAlQura` | Europe/Oslo, 31.1° E | inversion across days | Isha after the next Fajr | -66°, 66° to 70° | 49 |
| `ummAlQura` | Europe/Oslo, 31.1° E | tie | Dhuhr = Asr | 68° to 70° | 3 |
| `ummAlQura` | UTC, 0° | inversion across days | Isha after the next Fajr | -66°, 66° to 70° | 49 |
| `ummAlQura` | UTC, 0° | tie | Dhuhr = Asr | 67° to 70° | 5 |
| `karachi` | Europe/Oslo, 31.1° E | before its day | Fajr | -66° to -64°, -48° to -47° | 112 |
| `karachi` | Europe/Oslo, 31.1° E | before its day | sunrise | -66° to -65° | 32 |
| `karachi` | Europe/Oslo, 31.1° E | tie | Dhuhr = Asr | 68° to 70° | 3 |
| `karachi` | UTC, 0° | tie | Dhuhr = Asr | 67° to 70° | 5 |
| `tehran` | Europe/Oslo, 31.1° E | before its day | Fajr | -66° to -64°, -48° | 103 |
| `tehran` | Europe/Oslo, 31.1° E | before its day | sunrise | -66° to -65° | 32 |
| `tehran` | Europe/Oslo, 31.1° E | tie | Dhuhr = Asr | 68° to 70° | 3 |
| `tehran` | Europe/Oslo, 31.1° E | tie | Maghrib = Isha | -66° to -58°, 58° to 70° | 1333 |
| `tehran` | UTC, 0° | tie | Dhuhr = Asr | 67° to 70° | 5 |
| `tehran` | UTC, 0° | tie | Maghrib = Isha | -66° to -58°, 58° to 70° | 1329 |
| `diyanet` | Europe/Oslo, 31.1° E | before its day | Fajr | -66° to -64°, -48° to -47° | 112 |
| `diyanet` | Europe/Oslo, 31.1° E | before its day | sunrise | -66° to -65°, 67°, 69° | 43 |
| `diyanet` | Europe/Oslo, 31.1° E | inversion within the day | Dhuhr after Asr | 68° to 70° | 3 |
| `diyanet` | Europe/Oslo, 31.1° E | inversion within the day | Fajr after sunrise | -66°, 66° to 69° | 10 |
| `diyanet` | Europe/Oslo, 31.1° E | inversion within the day | Maghrib after Isha | -66°, 66° to 69° | 10 |
| `diyanet` | Europe/Oslo, 31.1° E | tie | Dhuhr = Asr | 67° to 69° | 7 |
| `diyanet` | Europe/Oslo, 31.1° E | tie | Fajr = sunrise | -66°, 66°, 68°, 70° | 5 |
| `diyanet` | Europe/Oslo, 31.1° E | tie | Maghrib = Isha | -66°, 66°, 68° | 4 |
| `diyanet` | UTC, 0° | before its day | sunrise | 67° | 1 |
| `diyanet` | UTC, 0° | inversion within the day | Dhuhr after Asr | 67° to 70° | 5 |
| `diyanet` | UTC, 0° | inversion within the day | Fajr after sunrise | -66°, 66° to 69° | 11 |
| `diyanet` | UTC, 0° | inversion within the day | Maghrib after Isha | -66°, 66° to 69° | 10 |
| `diyanet` | UTC, 0° | tie | Dhuhr = Asr | 67° to 69° | 4 |
| `diyanet` | UTC, 0° | tie | Fajr = sunrise | 66° to 68°, 70° | 4 |
| `diyanet` | UTC, 0° | tie | Maghrib = Isha | -66°, 66°, 68°, 70° | 5 |
| `dubai` | Europe/Oslo, 31.1° E | before its day | Fajr | -66° to -64°, -48° to -47° | 126 |
| `dubai` | Europe/Oslo, 31.1° E | before its day | sunrise | -66° to -65° | 35 |
| `dubai` | Europe/Oslo, 31.1° E | tie | Dhuhr = Asr | 68° to 70° | 3 |
| `dubai` | Europe/Oslo, 31.1° E | tie | Fajr = sunrise | 66° to 67° | 3 |
| `dubai` | Europe/Oslo, 31.1° E | tie | Maghrib = Isha | 67° | 1 |
| `dubai` | UTC, 0° | inversion within the day | Fajr after sunrise | 67° | 1 |
| `dubai` | UTC, 0° | inversion within the day | Maghrib after Isha | 67° | 1 |
| `dubai` | UTC, 0° | tie | Dhuhr = Asr | 67° to 70° | 5 |
| `dubai` | UTC, 0° | tie | Fajr = sunrise | 69° | 1 |
| `dubai` | UTC, 0° | tie | Maghrib = Isha | -66°, 66°, 69° | 3 |
| `kuwait` | Europe/Oslo, 31.1° E | before its day | Fajr | -66° to -64°, -48° to -47° | 112 |
| `kuwait` | Europe/Oslo, 31.1° E | before its day | sunrise | -66° to -65° | 32 |
| `kuwait` | Europe/Oslo, 31.1° E | tie | Dhuhr = Asr | 68° to 70° | 3 |
| `kuwait` | UTC, 0° | tie | Dhuhr = Asr | 67° to 70° | 5 |
| `qatar` | Europe/Oslo, 31.1° E | before its day | Fajr | -66° to -64°, -48° to -47° | 112 |
| `qatar` | Europe/Oslo, 31.1° E | before its day | sunrise | -66° to -65° | 32 |
| `qatar` | Europe/Oslo, 31.1° E | inversion across days | Isha after the next Fajr | -66°, 66° to 70° | 49 |
| `qatar` | Europe/Oslo, 31.1° E | tie | Dhuhr = Asr | 68° to 70° | 3 |
| `qatar` | UTC, 0° | inversion across days | Isha after the next Fajr | -66°, 66° to 70° | 49 |
| `qatar` | UTC, 0° | tie | Dhuhr = Asr | 67° to 70° | 5 |
| `muis` | Europe/Oslo, 31.1° E | before its day | Fajr | -66° to -64°, -48° to -45°, 47° to 48° | 264 |
| `muis` | Europe/Oslo, 31.1° E | before its day | sunrise | -66° to -65° | 31 |
| `muis` | Europe/Oslo, 31.1° E | inversion within the day | Dhuhr after Asr | 67° to 70° | 5 |
| `muis` | Europe/Oslo, 31.1° E | tie | Dhuhr = Asr | 67° to 69° | 4 |
| `muis` | UTC, 0° | before its day | Fajr | -48° to -47°, 48° | 41 |
| `muis` | UTC, 0° | inversion within the day | Dhuhr after Asr | 67° to 70° | 4 |
| `muis` | UTC, 0° | tie | Dhuhr = Asr | 67° to 68° | 5 |
| `jakim` | Europe/Oslo, 31.1° E | before its day | Fajr | -66° to -64°, -48° to -47° | 112 |
| `jakim` | Europe/Oslo, 31.1° E | before its day | sunrise | -66° to -65° | 32 |
| `jakim` | Europe/Oslo, 31.1° E | inversion within the day | Dhuhr after Asr | 68° to 70° | 3 |
| `jakim` | Europe/Oslo, 31.1° E | tie | Dhuhr = Asr | 67° to 69° | 7 |
| `jakim` | UTC, 0° | inversion within the day | Dhuhr after Asr | 67° to 70° | 5 |
| `jakim` | UTC, 0° | tie | Dhuhr = Asr | 67° to 69° | 4 |
| `kemenag` | Europe/Oslo, 31.1° E | before its day | Fajr | -66° to -64°, -48° to -46°, 47° to 48° | 222 |
| `kemenag` | Europe/Oslo, 31.1° E | before its day | sunrise | -66° to -65° | 35 |
| `kemenag` | Europe/Oslo, 31.1° E | inversion within the day | Dhuhr after Asr | 67° to 70° | 5 |
| `kemenag` | Europe/Oslo, 31.1° E | inversion within the day | Fajr after sunrise | -66°, 66° to 67°, 69° | 8 |
| `kemenag` | Europe/Oslo, 31.1° E | tie | Dhuhr = Asr | 67° to 69° | 4 |
| `kemenag` | Europe/Oslo, 31.1° E | tie | Maghrib = Isha | -66°, 66° to 70° | 33 |
| `kemenag` | UTC, 0° | before its day | Fajr | -48° to -47° | 25 |
| `kemenag` | UTC, 0° | inversion within the day | Dhuhr after Asr | 67° to 70° | 4 |
| `kemenag` | UTC, 0° | inversion within the day | Fajr after sunrise | -66°, 66° to 67°, 69° | 5 |
| `kemenag` | UTC, 0° | tie | Dhuhr = Asr | 67° to 68° | 5 |
| `kemenag` | UTC, 0° | tie | Fajr = sunrise | -66°, 66°, 69° | 3 |
| `kemenag` | UTC, 0° | tie | Maghrib = Isha | -66°, 66° to 70° | 33 |
| `moonsightingCommittee` | Europe/Oslo, 31.1° E | before its day | Fajr | -66° to -64° | 76 |
| `moonsightingCommittee` | Europe/Oslo, 31.1° E | before its day | sunrise | -66° to -65° | 32 |
| `moonsightingCommittee` | Europe/Oslo, 31.1° E | inversion within the day | Dhuhr after Asr | 67° to 70° | 27 |
| `moonsightingCommittee` | Europe/Oslo, 31.1° E | tie | Dhuhr = Asr | -66°, 66°, 69° | 14 |
| `moonsightingCommittee` | Europe/Oslo, 31.1° E | tie | Maghrib = Isha | 67° | 1 |
| `moonsightingCommittee` | UTC, 0° | inversion within the day | Dhuhr after Asr | 67° to 70° | 23 |
| `moonsightingCommittee` | UTC, 0° | inversion within the day | Maghrib after Isha | 67° | 1 |
| `moonsightingCommittee` | UTC, 0° | tie | Dhuhr = Asr | -66°, 66° to 68°, 70° | 17 |
| `moonsightingCommittee` | UTC, 0° | tie | Maghrib = Isha | -66°, 66°, 69° | 3 |
| `ummAlQura`, Ramadan 120 min, `middleOfTheNight` | Europe/Oslo, 31.1° E | before its day | Fajr | -66° to -47°, 49° to 70° | 3483 |
| `ummAlQura`, Ramadan 120 min, `middleOfTheNight` | Europe/Oslo, 31.1° E | before its day | sunrise | -66° to -65° | 32 |
| `ummAlQura`, Ramadan 120 min, `middleOfTheNight` | Europe/Oslo, 31.1° E | inversion across days | Isha after the next Fajr | -66° to -64°, 64° to 70° | 190 |
| `ummAlQura`, Ramadan 120 min, `middleOfTheNight` | Europe/Oslo, 31.1° E | tie | Dhuhr = Asr | 68° to 70° | 3 |
| `ummAlQura`, Ramadan 120 min, `middleOfTheNight` | UTC, 0° | before its day | Fajr | -66° to -49°, 49° to 70° | 1869 |
| `ummAlQura`, Ramadan 120 min, `middleOfTheNight` | UTC, 0° | inversion across days | Isha after the next Fajr | -66° to -64°, 64° to 70° | 190 |
| `ummAlQura`, Ramadan 120 min, `middleOfTheNight` | UTC, 0° | tie | Dhuhr = Asr | 67° to 70° | 5 |
