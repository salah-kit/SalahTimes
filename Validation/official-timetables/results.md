# Official timetables: results

Official time minus SalahTimes' unrounded time, in minutes, for every day of 2026. A positive value means the authority publishes later. "Preset exact", "Preset within 1 min" and "Preset largest difference" compare the method's preset as it ships (with its own adjustments and rounding) with the published minute, in days of the year. A place-specific fit replaces the preset in those columns and in the mean.

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

### jakim-wly01: Zone WLY01 (Kuala Lumpur, Putrajaya)

Jabatan Kemajuan Islam Malaysia (JAKIM), e-Solat. 365 days. Compared with `jakim`, shafi Asr, at 3.139, 101.6869.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min | Preset largest difference |
|---|---:|---:|---:|---:|---:|---:|
| fajr | +1.88 | +0.72 | +3.28 | 0 (0%) | 114 (31%) | 3 min |
| sunrise | -0.80 | -1.37 | -0.18 | 74 (20%) | 365 (100%) | 1 min |
| dhuhr | +1.77 | +1.26 | +2.28 | 0 (0%) | 86 (24%) | 2 min |
| asr | +1.75 | +0.70 | +3.28 | 0 (0%) | 126 (35%) | 3 min |
| maghrib | +1.93 | +0.77 | +3.17 | 0 (0%) | 103 (28%) | 3 min |
| isha | +1.97 | +0.73 | +3.25 | 0 (0%) | 95 (26%) | 3 min |

### jakim-wly01: Zone WLY01 (Kuala Lumpur, Putrajaya), place-specific fit

Jabatan Kemajuan Islam Malaysia (JAKIM), e-Solat. 365 days. Compared with `jakim`, shafi Asr, at 3.139, 101.6869.

WLY01 fit: rounding up, user adjustments Fajr +1, sunrise -1, Dhuhr +1, Asr +1, Maghrib +1, Isha +1. The columns below use these parameters in place of the preset.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min | Preset largest difference |
|---|---:|---:|---:|---:|---:|---:|
| fajr | +0.88 | -0.28 | +2.28 | 192 (53%) | 347 (95%) | 2 min |
| sunrise | +0.20 | -0.37 | +0.82 | 258 (71%) | 365 (100%) | 1 min |
| dhuhr | +0.77 | +0.26 | +1.28 | 266 (73%) | 365 (100%) | 1 min |
| asr | +0.75 | -0.30 | +2.28 | 247 (68%) | 353 (97%) | 2 min |
| maghrib | +0.93 | -0.23 | +2.17 | 194 (53%) | 352 (96%) | 2 min |
| isha | +0.97 | -0.27 | +2.25 | 180 (49%) | 347 (95%) | 2 min |

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

