# Official timetables: results

Official time minus SalahTimes' unrounded time, in minutes, for every day of 2026. A positive value means the authority publishes later. "Preset exact", "Preset within 1 min" and "Preset largest difference" compare the method's preset as it ships (with its own adjustments and rounding) with the published minute, in days of the year. A place-specific fit replaces the preset in every column.

Written by `OfficialTimetableTests.swift`; see README.md to reproduce. docs/validation.md interprets the numbers.

### muis-singapore: Singapore

Majlis Ugama Islam Singapura (MUIS), via data.gov.sg. 365 days. Compared with `muis`, shafi Asr, at 1.3521, 103.8198.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min | Preset largest difference |
|---|---:|---:|---:|---:|---:|---:|
| fajr | +0.49 | -0.42 | +1.52 | 245 (67%) | 365 (100%) | 1 min |
| sunrise | +0.50 | -0.36 | +1.41 | 267 (73%) | 365 (100%) | 1 min |
| dhuhr | +0.58 | -0.25 | +1.46 | 283 (78%) | 365 (100%) | 1 min |
| asr | +0.51 | -1.13 | +1.49 | 227 (62%) | 361 (99%) | 2 min |
| maghrib | +0.60 | -0.29 | +1.86 | 265 (73%) | 365 (100%) | 1 min |
| isha | +0.53 | -0.33 | +1.48 | 292 (80%) | 365 (100%) | 1 min |

### diyanet-istanbul: Istanbul

Presidency of Religious Affairs of Turkey (Diyanet). 365 days. Compared with `diyanet`, shafi Asr, at 41.0082, 28.9784.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min | Preset largest difference |
|---|---:|---:|---:|---:|---:|---:|
| fajr | +0.04 | -0.57 | +0.72 | 328 (90%) | 365 (100%) | 1 min |
| sunrise | +0.04 | -0.66 | +0.83 | 305 (84%) | 365 (100%) | 1 min |
| dhuhr | +0.03 | -0.65 | +0.63 | 321 (88%) | 365 (100%) | 1 min |
| asr | +0.07 | -1.01 | +1.31 | 216 (59%) | 365 (100%) | 1 min |
| maghrib | +0.02 | -1.23 | +1.66 | 120 (33%) | 354 (97%) | 2 min |
| isha | +0.06 | -1.60 | +1.92 | 93 (25%) | 328 (90%) | 2 min |

### diyanet-ankara: Ankara

Presidency of Religious Affairs of Turkey (Diyanet). 365 days. Compared with `diyanet`, shafi Asr, at 39.9334, 32.8597.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min | Preset largest difference |
|---|---:|---:|---:|---:|---:|---:|
| fajr | +0.10 | -0.53 | +0.71 | 337 (92%) | 365 (100%) | 1 min |
| sunrise | +0.06 | -0.59 | +0.84 | 313 (86%) | 365 (100%) | 1 min |
| dhuhr | +0.02 | -0.64 | +0.66 | 327 (90%) | 365 (100%) | 1 min |
| asr | +0.08 | -1.00 | +1.33 | 205 (56%) | 365 (100%) | 1 min |
| maghrib | +0.04 | -1.20 | +1.63 | 114 (31%) | 360 (99%) | 2 min |
| isha | +0.07 | -1.47 | +1.93 | 99 (27%) | 339 (93%) | 2 min |

### diyanet-izmir: Izmir

Presidency of Religious Affairs of Turkey (Diyanet). 365 days. Compared with `diyanet`, shafi Asr, at 38.4192, 27.1287.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min | Preset largest difference |
|---|---:|---:|---:|---:|---:|---:|
| fajr | -0.02 | -0.62 | +0.67 | 320 (88%) | 365 (100%) | 1 min |
| sunrise | -0.05 | -0.69 | +0.73 | 313 (86%) | 365 (100%) | 1 min |
| dhuhr | -0.03 | -0.68 | +0.56 | 332 (91%) | 365 (100%) | 1 min |
| asr | +0.00 | -1.13 | +1.20 | 225 (62%) | 365 (100%) | 1 min |
| maghrib | -0.03 | -1.22 | +1.52 | 146 (40%) | 362 (99%) | 2 min |
| isha | -0.02 | -1.47 | +1.71 | 112 (31%) | 349 (96%) | 2 min |

### diyanet-van: Van

Presidency of Religious Affairs of Turkey (Diyanet). 365 days. Compared with `diyanet`, shafi Asr, at 38.4942, 43.3803.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min | Preset largest difference |
|---|---:|---:|---:|---:|---:|---:|
| fajr | +0.02 | -0.58 | +0.62 | 347 (95%) | 365 (100%) | 1 min |
| sunrise | -0.01 | -0.64 | +0.68 | 323 (88%) | 365 (100%) | 1 min |
| dhuhr | -0.02 | -0.66 | +0.58 | 340 (93%) | 365 (100%) | 1 min |
| asr | +0.06 | -1.02 | +1.20 | 236 (65%) | 365 (100%) | 1 min |
| maghrib | +0.02 | -1.15 | +1.46 | 172 (47%) | 365 (100%) | 1 min |
| isha | +0.01 | -1.45 | +1.71 | 130 (36%) | 355 (97%) | 2 min |

### jakim-wly01: Zone WLY01 (Kuala Lumpur, Putrajaya)

Jabatan Kemajuan Islam Malaysia (JAKIM), e-Solat. 365 days. Compared with `jakim`, shafi Asr, at 3.733333, 101.383333 (sunrise at 3.19, 101.758333).

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min | Preset largest difference |
|---|---:|---:|---:|---:|---:|---:|
| fajr | +0.74 | -0.09 | +2.22 | 139 (38%) | 326 (89%) | 2 min |
| sunrise | -0.51 | -1.06 | +0.03 | 179 (49%) | 365 (100%) | 1 min |
| dhuhr | +0.55 | +0.04 | +1.07 | 166 (45%) | 365 (100%) | 1 min |
| asr | +0.56 | -0.11 | +2.05 | 171 (47%) | 355 (97%) | 2 min |
| maghrib | +0.70 | -0.06 | +1.83 | 126 (35%) | 346 (95%) | 2 min |
| isha | +0.69 | -0.04 | +1.78 | 130 (36%) | 353 (97%) | 2 min |

### jakim-wly01: Zone WLY01 (Kuala Lumpur, Putrajaya), place-specific fit

Jabatan Kemajuan Islam Malaysia (JAKIM), e-Solat. 365 days. Compared with `jakim`, shafi Asr, at 3.733333, 101.383333 (sunrise at 3.19, 101.758333).

WLY01 fit: rounding up, user adjustment sunrise -1. The columns below use these parameters in place of the preset.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min | Preset largest difference |
|---|---:|---:|---:|---:|---:|---:|
| fajr | +0.74 | -0.09 | +2.22 | 264 (72%) | 358 (98%) | 2 min |
| sunrise | +0.49 | -0.06 | +1.03 | 350 (96%) | 365 (100%) | 1 min |
| dhuhr | +0.55 | +0.04 | +1.07 | 346 (95%) | 365 (100%) | 1 min |
| asr | +0.56 | -0.11 | +2.05 | 321 (88%) | 363 (99%) | 2 min |
| maghrib | +0.70 | -0.06 | +1.83 | 288 (79%) | 365 (100%) | 1 min |
| isha | +0.69 | -0.04 | +1.78 | 295 (81%) | 365 (100%) | 1 min |

### jakim-png01: Zone PNG01 (all of Pulau Pinang)

Jabatan Kemajuan Islam Malaysia (JAKIM), e-Solat. 365 days. Compared with `jakim`, shafi Asr, at 5.4141, 100.3288.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min | Preset largest difference |
|---|---:|---:|---:|---:|---:|---:|
| fajr | +1.22 | +0.59 | +1.84 | 0 (0%) | 285 (78%) | 2 min |
| sunrise | -1.57 | -2.31 | -0.88 | 0 (0%) | 159 (44%) | 2 min |
| dhuhr | +1.14 | +0.65 | +1.67 | 0 (0%) | 315 (86%) | 2 min |
| asr | +1.15 | +0.02 | +2.07 | 23 (6%) | 283 (78%) | 2 min |
| maghrib | +1.16 | +0.61 | +1.82 | 0 (0%) | 306 (84%) | 2 min |
| isha | +1.17 | +0.61 | +1.77 | 0 (0%) | 299 (82%) | 2 min |

### jakim-jhr02: Zone JHR02 (Johor Bahru, Kota Tinggi, Mersing, Kulai)

Jabatan Kemajuan Islam Malaysia (JAKIM), e-Solat. 365 days. Compared with `jakim`, shafi Asr, at 1.4927, 103.7414.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min | Preset largest difference |
|---|---:|---:|---:|---:|---:|---:|
| fajr | +1.31 | +0.40 | +2.21 | 7 (2%) | 247 (68%) | 2 min |
| sunrise | +0.33 | -0.55 | +1.22 | 244 (67%) | 365 (100%) | 1 min |
| dhuhr | +1.43 | +0.71 | +2.23 | 0 (0%) | 208 (57%) | 2 min |
| asr | +1.30 | +0.23 | +2.39 | 5 (1%) | 251 (69%) | 2 min |
| maghrib | +1.32 | +0.44 | +2.14 | 4 (1%) | 247 (68%) | 2 min |
| isha | +1.33 | +0.43 | +2.19 | 4 (1%) | 248 (68%) | 2 min |

### jakim-sbh07: Zone SBH07 (Kota Kinabalu, Ranau, Kota Belud, Tuaran, Penampang, Papar, Putatan, West Coast Division)

Jabatan Kemajuan Islam Malaysia (JAKIM), e-Solat. 365 days. Compared with `jakim`, shafi Asr, at 5.9804, 116.0735.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min | Preset largest difference |
|---|---:|---:|---:|---:|---:|---:|
| fajr | +1.12 | +0.36 | +2.10 | 23 (6%) | 298 (82%) | 2 min |
| sunrise | +0.04 | -0.73 | +1.07 | 272 (75%) | 365 (100%) | 1 min |
| dhuhr | +1.12 | +0.58 | +1.72 | 0 (0%) | 322 (88%) | 2 min |
| asr | +1.06 | -0.27 | +2.00 | 29 (8%) | 312 (85%) | 2 min |
| maghrib | +1.07 | +0.07 | +1.91 | 43 (12%) | 303 (83%) | 2 min |
| isha | +1.05 | -0.01 | +1.91 | 41 (11%) | 304 (83%) | 2 min |

### ummalqura-makkah: Makkah

Umm al-Qura calendar (King Abdulaziz City for Science and Technology). 365 days. Compared with `ummAlQura`, shafi Asr, Ramadan Isha 120 minutes, at 21.426666, 39.831666.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min | Preset largest difference |
|---|---:|---:|---:|---:|---:|---:|
| fajr | +0.52 | -0.59 | +1.50 | 160 (44%) | 364 (100%) | 2 min |
| sunrise | -0.50 | -1.36 | +0.80 | 173 (47%) | 365 (100%) | 1 min |
| dhuhr | +0.52 | -0.32 | +1.21 | 170 (47%) | 365 (100%) | 1 min |
| asr | +0.51 | -0.30 | +1.33 | 171 (47%) | 365 (100%) | 1 min |
| maghrib | +0.50 | -0.36 | +1.67 | 187 (51%) | 364 (100%) | 2 min |
| isha | +0.50 | -0.36 | +1.67 | 187 (51%) | 364 (100%) | 2 min |

### ummalqura-riyadh: Riyadh

Umm al-Qura calendar (King Abdulaziz City for Science and Technology). 365 days. Compared with `ummAlQura`, shafi Asr, Ramadan Isha 120 minutes, at 24.67, 46.69.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min | Preset largest difference |
|---|---:|---:|---:|---:|---:|---:|
| fajr | +0.49 | -0.79 | +1.59 | 151 (41%) | 357 (98%) | 2 min |
| sunrise | -0.47 | -1.46 | +0.81 | 195 (53%) | 365 (100%) | 1 min |
| dhuhr | +0.48 | -0.35 | +1.16 | 196 (54%) | 365 (100%) | 1 min |
| asr | +0.53 | -0.59 | +1.15 | 175 (48%) | 365 (100%) | 1 min |
| maghrib | +0.49 | -0.42 | +1.73 | 187 (51%) | 363 (99%) | 2 min |
| isha | +0.49 | -0.42 | +1.73 | 187 (51%) | 363 (99%) | 2 min |

### kemenag-jakarta: Kota Jakarta (DKI Jakarta)

Indonesia's Ministry of Religious Affairs (Kemenag), Bimas Islam. 365 days. Compared with `kemenag`, shafi Asr, at -6.1754, 106.8272.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min | Preset largest difference |
|---|---:|---:|---:|---:|---:|---:|
| fajr | +0.43 | -0.04 | +0.97 | 350 (96%) | 365 (100%) | 1 min |
| sunrise | -0.23 | -0.78 | +0.40 | 92 (25%) | 365 (100%) | 1 min |
| dhuhr | +0.50 | -0.05 | +1.06 | 350 (96%) | 365 (100%) | 1 min |
| asr | +0.45 | -0.15 | +1.29 | 310 (85%) | 365 (100%) | 1 min |
| maghrib | +0.47 | -0.04 | +1.26 | 354 (97%) | 365 (100%) | 1 min |
| isha | +0.44 | -0.04 | +1.35 | 347 (95%) | 365 (100%) | 1 min |

### kemenag-surabaya: Kota Surabaya (Jawa Timur)

Indonesia's Ministry of Religious Affairs (Kemenag), Bimas Islam. 365 days. Compared with `kemenag`, shafi Asr, at -7.2575, 112.7521.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min | Preset largest difference |
|---|---:|---:|---:|---:|---:|---:|
| fajr | +0.61 | +0.01 | +1.24 | 326 (89%) | 365 (100%) | 1 min |
| sunrise | -0.05 | -0.72 | +0.53 | 165 (45%) | 365 (100%) | 1 min |
| dhuhr | +0.63 | +0.13 | +1.13 | 318 (87%) | 365 (100%) | 1 min |
| asr | +0.65 | -0.06 | +1.51 | 317 (87%) | 365 (100%) | 1 min |
| maghrib | +0.62 | +0.00 | +1.46 | 328 (90%) | 365 (100%) | 1 min |
| isha | +0.61 | +0.02 | +1.43 | 311 (85%) | 365 (100%) | 1 min |

### kemenag-medan: Kota Medan (Sumatera Utara)

Indonesia's Ministry of Religious Affairs (Kemenag), Bimas Islam. 365 days. Compared with `kemenag`, shafi Asr, at 3.5952, 98.6722.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min | Preset largest difference |
|---|---:|---:|---:|---:|---:|---:|
| fajr | +0.42 | -0.10 | +0.96 | 327 (90%) | 365 (100%) | 1 min |
| sunrise | -0.27 | -0.83 | +0.26 | 72 (20%) | 365 (100%) | 1 min |
| dhuhr | +0.41 | -0.08 | +0.92 | 339 (93%) | 365 (100%) | 1 min |
| asr | +0.42 | -0.21 | +1.22 | 321 (88%) | 365 (100%) | 1 min |
| maghrib | +0.42 | -0.09 | +0.96 | 334 (92%) | 365 (100%) | 1 min |
| isha | +0.42 | -0.12 | +0.95 | 327 (90%) | 365 (100%) | 1 min |

### kemenag-makassar: Kota Makassar (Sulawesi Selatan)

Indonesia's Ministry of Religious Affairs (Kemenag), Bimas Islam. 365 days. Compared with `kemenag`, shafi Asr, at -5.1477, 119.4327.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min | Preset largest difference |
|---|---:|---:|---:|---:|---:|---:|
| fajr | +0.56 | +0.00 | +1.05 | 349 (96%) | 365 (100%) | 1 min |
| sunrise | -0.19 | -0.72 | +0.35 | 120 (33%) | 365 (100%) | 1 min |
| dhuhr | +0.52 | +0.03 | +1.05 | 356 (98%) | 365 (100%) | 1 min |
| asr | +0.52 | -0.09 | +1.21 | 320 (88%) | 365 (100%) | 1 min |
| maghrib | +0.55 | +0.02 | +1.09 | 348 (95%) | 365 (100%) | 1 min |
| isha | +0.52 | +0.02 | +1.39 | 346 (95%) | 365 (100%) | 1 min |

### ut-tehran: Tehran

Calendar Centre, Institute of Geophysics, University of Tehran. 365 days. Compared with `tehran`, shafi Asr, at 35.7, 51.42.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min | Preset largest difference |
|---|---:|---:|---:|---:|---:|---:|
| fajr | -0.02 | -0.51 | +0.51 | 360 (99%) | 365 (100%) | 1 min |
| sunrise | -0.00 | -0.50 | +0.50 | 362 (99%) | 365 (100%) | 1 min |
| dhuhr | -0.01 | -0.52 | +0.50 | 361 (99%) | 365 (100%) | 1 min |
| asr | not published | | | | | |
| maghrib | -0.00 | -0.53 | +0.49 | 359 (98%) | 365 (100%) | 1 min |
| isha | not published | | | | | |

### esa-cairo: Cairo

Egyptian General Authority for Survey (ESA). 365 days. Compared with `egyptian`, shafi Asr, at 30.0444, 31.2357.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min | Preset largest difference |
|---|---:|---:|---:|---:|---:|---:|
| fajr | -0.22 | -0.80 | +0.35 | 281 (77%) | 365 (100%) | 1 min |
| sunrise | -0.22 | -0.76 | +0.35 | 288 (79%) | 365 (100%) | 1 min |
| dhuhr | -0.19 | -0.66 | +0.34 | 293 (80%) | 365 (100%) | 1 min |
| asr | -0.18 | -0.70 | +0.40 | 304 (83%) | 365 (100%) | 1 min |
| maghrib | -0.11 | -0.65 | +0.44 | 332 (91%) | 365 (100%) | 1 min |
| isha | -0.11 | -0.68 | +0.47 | 323 (88%) | 365 (100%) | 1 min |

### banuri-karachi: Karachi

Jamia Uloom-ul-Islamia Allama Banuri Town (University of Islamic Sciences), Karachi. 365 days. Compared with `karachi`, hanafi Asr, at 24.8607, 67.0011.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min | Preset largest difference |
|---|---:|---:|---:|---:|---:|---:|
| fajr | -0.20 | -0.72 | +0.30 | 294 (81%) | 365 (100%) | 1 min |
| sunrise | -0.20 | -0.69 | +0.32 | 300 (82%) | 365 (100%) | 1 min |
| dhuhr | -0.22 | -0.71 | +0.29 | 283 (78%) | 365 (100%) | 1 min |
| asr | -0.21 | -0.83 | +0.46 | 291 (80%) | 365 (100%) | 1 min |
| maghrib | -0.20 | -0.70 | +0.32 | 297 (81%) | 365 (100%) | 1 min |
| isha | -0.20 | -0.71 | +0.37 | 294 (81%) | 365 (100%) | 1 min |

### moonsighting-london-hanafi: London

Moonsighting Committee Worldwide (moonsighting.com). 365 days. Compared with `moonsightingCommittee`, hanafi Asr, shafaq general, at 51.507194, -0.116711.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min | Preset largest difference |
|---|---:|---:|---:|---:|---:|---:|
| fajr | -0.01 | -0.62 | +0.58 | 332 (91%) | 365 (100%) | 1 min |
| sunrise | +0.03 | -0.59 | +0.60 | 348 (95%) | 365 (100%) | 1 min |
| dhuhr | -0.03 | -0.53 | +0.48 | 354 (97%) | 365 (100%) | 1 min |
| asr | +0.02 | -0.75 | +0.84 | 270 (74%) | 365 (100%) | 1 min |
| maghrib | -0.01 | -0.57 | +0.61 | 347 (95%) | 365 (100%) | 1 min |
| isha | -0.02 | -0.61 | +0.60 | 336 (92%) | 365 (100%) | 1 min |

### moonsighting-london-shafi: London

Moonsighting Committee Worldwide (moonsighting.com). 365 days. Compared with `moonsightingCommittee`, shafi Asr, shafaq ahmer, at 51.507194, -0.116711.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min | Preset largest difference |
|---|---:|---:|---:|---:|---:|---:|
| fajr | -0.01 | -0.62 | +0.58 | 332 (91%) | 365 (100%) | 1 min |
| sunrise | +0.03 | -0.59 | +0.60 | 348 (95%) | 365 (100%) | 1 min |
| dhuhr | -0.03 | -0.53 | +0.48 | 354 (97%) | 365 (100%) | 1 min |
| asr | -0.02 | -0.77 | +0.81 | 284 (78%) | 365 (100%) | 1 min |
| maghrib | -0.01 | -0.57 | +0.61 | 347 (95%) | 365 (100%) | 1 min |
| isha | -0.01 | -0.67 | +0.59 | 337 (92%) | 365 (100%) | 1 min |

