# Official timetables: results

Official time minus SalahTimes' unrounded time, in minutes, for every day of 2026. A positive value means the authority publishes later. "Preset exact" and "Preset within 1 min" compare the method's preset as it ships (rounded) with the published minute.

Written by `OfficialTimetableTests.swift`; see README.md to reproduce. docs/validation.md interprets the numbers.

### muis-singapore: Singapore

Majlis Ugama Islam Singapura (MUIS), via data.gov.sg. 365 days. Compared with `muis`, shafi Asr, at 1.3521, 103.8198.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min |
|---|---:|---:|---:|---:|---:|
| fajr | +0.49 | -0.42 | +1.52 | 53% | 100% |
| sunrise | +0.50 | -0.36 | +1.41 | 52% | 100% |
| dhuhr | +1.58 | +0.75 | +2.46 | 0% | 41% |
| asr | +0.51 | -1.13 | +1.49 | 41% | 100% |
| maghrib | +0.60 | -0.29 | +1.86 | 45% | 97% |
| isha | +0.53 | -0.33 | +1.48 | 48% | 100% |

### diyanet-istanbul: Istanbul

Presidency of Religious Affairs of Turkey (Diyanet). 365 days. Compared with `diyanet`, shafi Asr, at 41.0082, 28.9784.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min |
|---|---:|---:|---:|---:|---:|
| fajr | +0.04 | -0.57 | +0.72 | 90% | 100% |
| sunrise | +0.04 | -0.66 | +0.83 | 84% | 100% |
| dhuhr | +0.03 | -0.65 | +0.63 | 88% | 100% |
| asr | +0.07 | -1.01 | +1.31 | 59% | 100% |
| maghrib | +0.02 | -1.23 | +1.66 | 33% | 97% |
| isha | +0.06 | -1.60 | +1.92 | 25% | 90% |

### diyanet-ankara: Ankara

Presidency of Religious Affairs of Turkey (Diyanet). 365 days. Compared with `diyanet`, shafi Asr, at 39.9334, 32.8597.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min |
|---|---:|---:|---:|---:|---:|
| fajr | +0.10 | -0.53 | +0.71 | 92% | 100% |
| sunrise | +0.06 | -0.59 | +0.84 | 86% | 100% |
| dhuhr | +0.02 | -0.64 | +0.66 | 90% | 100% |
| asr | +0.08 | -1.00 | +1.33 | 56% | 100% |
| maghrib | +0.04 | -1.20 | +1.63 | 31% | 99% |
| isha | +0.07 | -1.47 | +1.93 | 27% | 93% |

### jakim-wly01: Zone WLY01 (Kuala Lumpur, Putrajaya)

Jabatan Kemajuan Islam Malaysia (JAKIM), e-Solat. 365 days. Compared with `jakim`, shafi Asr, at 3.139, 101.6869.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min |
|---|---:|---:|---:|---:|---:|
| fajr | +10.29 | +8.87 | +12.01 | 0% | 0% |
| sunrise | -0.80 | -1.37 | -0.18 | 20% | 100% |
| dhuhr | +2.77 | +2.26 | +3.28 | 0% | 0% |
| asr | +1.75 | +0.70 | +3.28 | 0% | 35% |
| maghrib | +1.93 | +0.77 | +3.17 | 0% | 28% |
| isha | +1.97 | +0.73 | +3.25 | 0% | 26% |

### ummalqura-makkah: Makkah

Umm al-Qura calendar (King Abdulaziz City for Science and Technology). 365 days. Compared with `ummAlQura`, shafi Asr, Ramadan Isha 120 minutes, at 21.426666, 39.831666.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min |
|---|---:|---:|---:|---:|---:|
| fajr | +0.52 | -0.59 | +1.50 | 44% | 100% |
| sunrise | -0.50 | -1.36 | +0.80 | 47% | 100% |
| dhuhr | +0.52 | -0.32 | +1.21 | 47% | 100% |
| asr | +0.51 | -0.30 | +1.33 | 47% | 100% |
| maghrib | +0.50 | -0.36 | +1.67 | 51% | 100% |
| isha | +0.50 | -0.36 | +1.67 | 51% | 100% |

### ummalqura-riyadh: Riyadh

Umm al-Qura calendar (King Abdulaziz City for Science and Technology). 365 days. Compared with `ummAlQura`, shafi Asr, Ramadan Isha 120 minutes, at 24.67, 46.69.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min |
|---|---:|---:|---:|---:|---:|
| fajr | +0.49 | -0.79 | +1.59 | 41% | 98% |
| sunrise | -0.47 | -1.46 | +0.81 | 53% | 100% |
| dhuhr | +0.48 | -0.35 | +1.16 | 54% | 100% |
| asr | +0.53 | -0.59 | +1.15 | 48% | 100% |
| maghrib | +0.49 | -0.42 | +1.73 | 51% | 99% |
| isha | +0.49 | -0.42 | +1.73 | 51% | 99% |

### kemenag-jakarta: Kota Jakarta (DKI Jakarta)

Indonesia's Ministry of Religious Affairs (Kemenag), Bimas Islam. 365 days. Compared with `kemenag`, shafi Asr, at -6.1754, 106.8272.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min |
|---|---:|---:|---:|---:|---:|
| fajr | +2.43 | +1.96 | +2.97 | 0% | 0% |
| sunrise | -3.23 | -3.78 | -2.60 | 0% | 0% |
| dhuhr | +3.50 | +2.95 | +4.06 | 0% | 0% |
| asr | +2.45 | +1.85 | +3.29 | 0% | 0% |
| maghrib | +3.17 | +2.66 | +3.93 | 0% | 0% |
| isha | +2.44 | +1.96 | +3.35 | 0% | 0% |

### moonsighting-london-hanafi: London

Moonsighting Committee Worldwide (moonsighting.com). 365 days. Compared with `moonsightingCommittee`, hanafi Asr, shafaq general, at 51.507194, -0.116711.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min |
|---|---:|---:|---:|---:|---:|
| fajr | -0.01 | -0.62 | +0.58 | 91% | 100% |
| sunrise | +0.03 | -0.59 | +0.60 | 95% | 100% |
| dhuhr | -0.03 | -0.53 | +0.48 | 97% | 100% |
| asr | +0.02 | -0.75 | +0.84 | 74% | 100% |
| maghrib | -0.01 | -0.57 | +0.61 | 95% | 100% |
| isha | -0.02 | -0.61 | +0.60 | 92% | 100% |

### moonsighting-london-shafi: London

Moonsighting Committee Worldwide (moonsighting.com). 365 days. Compared with `moonsightingCommittee`, shafi Asr, shafaq ahmer, at 51.507194, -0.116711.

| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min |
|---|---:|---:|---:|---:|---:|
| fajr | -0.01 | -0.62 | +0.58 | 91% | 100% |
| sunrise | +0.03 | -0.59 | +0.60 | 95% | 100% |
| dhuhr | -0.03 | -0.53 | +0.48 | 97% | 100% |
| asr | -0.02 | -0.77 | +0.81 | 78% | 100% |
| maghrib | -0.01 | -0.57 | +0.61 | 95% | 100% |
| isha | -0.01 | -0.67 | +0.59 | 92% | 100% |

