# Calculation methods

This page lists every calculation method that SalahTimes ships, what each one contains, and where the values come from. It also covers the high-latitude rules, the Moonsighting Committee's formula, the Ramadan Isha rule, the Kaaba's coordinates for the Qibla, and the country suggestions.

All sources were retrieved between 2026-10-13 and 2026-10-18 unless a section says otherwise. A 2026-10-14
comparison adds complete official UAE timetables; the dated results are in `docs/validation.md`.

## What a preset contains

A method is a preset of `CalculationParameters`. `Vectors/methods.json` holds the same values as the Swift presets, and a test keeps them identical. A preset reproduces its authority's times in one of two ways:

- **The authority documents its rules.** The preset follows them: the astronomical definition (the Sun's angle below the horizon for Fajr and Isha, or Isha as an interval after Maghrib, and for Tehran and Kemenag an angle for Maghrib), the precautionary minutes it documents, in `methodAdjustments`, and the rounding it documents, or rounding to the nearest minute when it documents none. Minutes that its timetables add beyond those rules stay out of the preset; the method's section gives the differences measured.
- **The authority publishes only timetables.** MUIS and the UAE's authority publish timetables but not their methods. Their presets are fitted to those timetables, minutes and rounding included, and their sections give the data and the fit.

Every value is either documented or measured from official timetables. None is guessed.

Every preset also uses Shafi'i Asr (`madhab: shafi`), the `recommended` high-latitude rule, the night measured from sunset to Fajr (`nightSpan: sunsetToFajr`), no user adjustments, and the Ramadan Isha rule off.

`docs/validation.md` compares the presets with a year of official timetables from Diyanet, JAKIM, MUIS, Umm al-Qura, Kemenag, the Moonsighting Committee, the UAE's Awqaf, the University of Tehran's Institute of Geophysics, Egypt's General Authority for Survey and Jamia Uloom-ul-Islamia Banuri Town, and with Qatar Calendar House's 2025 calendar.

Presets are starting points. Mosques and communities in one country often follow different methods, and an authority can change its method. Apps should let users pick another method and change any parameter, including Asr's madhab, the high-latitude rule and per-prayer minutes.

To correct a value or a source, open an issue in [salah-kit/SalahTimes](https://github.com/salah-kit/SalahTimes/issues) with the `calculation-method` label. Include the authority's publication or an official timetable. To check the sources below in their original languages, see [issue #7](https://github.com/salah-kit/SalahTimes/issues/7).

## Summary

| Method | Fajr | Maghrib | Isha | Method minutes | Rounding |
|---|---|---|---|---|---|
| `muslimWorldLeague` | 18° | sunset | 17° | none | nearest |
| `isna` | 15° | sunset | 15° | none | nearest |
| `egyptian` | 19.5° | sunset | 17.5° | none | nearest |
| `ummAlQura` | 18.5° | sunset | 90 min after Maghrib | none | nearest |
| `karachi` | 18° | sunset | 18° | none | nearest |
| `tehran` | 17.7° | 4.5° | 14° | none | nearest |
| `diyanet` | 18° | sunset | 17° | sunrise −7, Dhuhr +5, Asr +4, Maghrib +7 | nearest |
| `dubai` | 18.2° | sunset | 18.2° | sunrise −3, Dhuhr +3, Asr +3, Maghrib +3 (fitted) | nearest |
| `kuwait` | 18° | sunset | 17.5° | none | nearest |
| `qatar` | 18° | sunset | 90 min after Maghrib | none | nearest |
| `muis` | 20° | sunset | 18° | Dhuhr +1 (fitted) | up (fitted) |
| `jakim` | 18° | sunset | 18° | Dhuhr +1 | nearest |
| `kemenag` | 20° | 1° | 18° | Fajr +2, sunrise −3, Dhuhr +3, Asr +2, Maghrib +2, Isha +2 | up |
| `moonsightingCommittee` | 18° with seasonal bound | sunset | 18° with seasonal bound (general shafaq) | Dhuhr +5, Maghrib +3 | nearest |

Sunset and sunrise are the moments the Sun's upper limb touches the horizon, with 34′ of refraction (`docs/algorithm.md` §7). Dhuhr is the Sun's transit plus the method's Dhuhr minutes.

## Muslim World League

`muslimWorldLeague`: Fajr at 18°, Isha at 17°.

The League's Islamic Fiqh Council set these angles in the resolution of its ninth session that also covers high latitudes.

Sources:
- Islamic Fiqh Council of the Muslim World League, ninth session, sixth resolution, 19 Rajab 1406 AH (30 March 1986), *بشأن مواقيت الصلاة والصيام في البلاد ذات خطوط العرض العالية*, as published on the League's site: Fajr "corresponds to an angle of (18) degrees below the eastern horizon", Isha is when "the Sun is at an angle of (17) below the western horizon", sunrise and Maghrib at 50′ below the horizon, Dhuhr at the transit of the Sun's centre, and Asr when a shadow equals its object plus its noon shadow (Shafi'i). The page is gone from themwl.org; the Internet Archive's copy of 6 August 2016: https://web.archive.org/web/20160806121152id_/http://www.themwl.org/Fatwa/default.aspx?d=1&cidi=110&l=AR&cid=11 (primary)
- Hamid Zarrabi-Zadeh, PrayTimes.org, *Prayer Times Calculation*, table of methods: "Muslim World League: 18 / 17". http://praytimes.org/calculation (secondary)
- PrayTimes.org, *Calculation Methods*, which lists its use in "Europe, Far East, parts of US". https://praytimes.org/docs/methods (secondary)

Notes:
- The same resolution says that where precautionary minutes are applied, adding two minutes to Dhuhr, Asr, Maghrib and Isha and taking two from Fajr and sunrise is enough. It doesn't require them, so the preset adds none.
- The resolution's rules for high latitudes are under [High-latitude rules](#high-latitude-rules).

## ISNA

`isna`: Fajr and Isha at 15°.

This is what the Fiqh Council of North America (FCNA), the Islamic Society of North America's fiqh council, now suggests for the United States on its site, and what most software calls "ISNA". FCNA's General Body Meeting in Dallas on 27–29 October 2017 suggested "15° for both Fajr and Isha in the USA" and 13° for both in Canada, throughout the year, and said this corresponds to the "Islamic Society of North America" setting in most apps. No preset has 13°; set both angles to 13° for that page's Canadian suggestion.

The published positions have changed over time. Khalid Shaukat wrote in ISNA's magazine *Islamic Horizons* in 2002 that "ISNA uses a value of 15°". In 2010 FCNA's secretary general said the council followed 18°. On 25 September 2011 it adopted moonsighting.com's functions of latitude and season, the Moonsighting Committee's method, with 17.5° for Fajr and 15° for Isha as the fixed-angle alternative. The 2017 suggestion replaced that, and an FCNA page adopted on 19 September 2020, since removed, said 15° "for all regions". The country suggestions for the United States and Canada still follow the 2011 decision; [issue #8](https://github.com/salah-kit/SalahTimes/issues/8) tracks them.

Sources:
- Fiqh Council of North America, *How should the times of Fajr and Isha be calculated?*, the suggestion of its General Body Meeting of 27–29 October 2017; the page is dated 8 November 2021, updated 13 August 2026, and archived from 4 May 2020. https://fiqhcouncil.org/the-suggested-calculation-method-for-fajr-and-isha/ (primary)
- FCNA, *Fajr and Isha Timings Are Fifteen Degrees*, adopted on 19 September 2020: "one approximate time of 15° for all regions". Removed from the site; the Internet Archive's copy: https://web.archive.org/web/20231201114432/https://fiqhcouncil.org/fajr-and-isha-timings-are-fifteen-degrees/ (primary)
- Khalid Shaukat, *Perfecting Prayer Times*, ISNA's *Islamic Horizons*, 2002: "ISNA uses a value of 15°". https://web.archive.org/web/20020624125039/http://www.isna.net:80/Horizons/article.asp?section=2&fromarticle=1&issueid=14&catid=4&artname=Perfecting+Prayer+Times (primary)
- PrayTimes.org: "Islamic Society of North America (ISNA): 15 / 15". http://praytimes.org/calculation (secondary)
- Statement of Dr. Zulfiqar Ali Shah, Executive Director of the Fiqh Council of North America, 29 July 2012, relayed by the International Astronomical Center: *ISNA Adopts New Angles for Fajer and Isha*. It quotes FCNA's position of 25 September 2011: "For North America Use functions of latitude and seasons for Fajr, and Isha' as determined by Moonsighting.com", and "if one wants to calculate Fajr & Isha based on degrees, one can opt to use 17.5 ° for Fajr and 15 ° for Isha'". https://astronomycenter.net/articles/2012/07/30/81?l=en (secondary host for a primary statement; FCNA's own sites don't have it)
- The same site, December 2010, quoting FCNA's secretary general: "The tentative consensus was on 18 degrees." https://astronomycenter.net/articles/2010/12/26/33?l=en (secondary host for a primary statement)

Notes:
- moonsighting.com's FAQ now says "Since 2018 onwards, ISNA recommends using 15°". https://www.moonsighting.com/faq_pt.html
- ISNA's own site publishes no method. Its Ramadan 2026 timetable for its Plainfield, Indiana headquarters fits 15° and 15° with Shafi'i Asr ([issue #5](https://github.com/salah-kit/SalahTimes/issues/5)).

## Egyptian General Authority of Survey

`egyptian`: Fajr at 19.5°, Isha at 17.5°.

The Egyptian General Authority for Survey (الهيئة المصرية العامة للمساحة) computes Egypt's official prayer times.

Sources:
- Dar al-Ifta al-Misriyyah, fatwa 4021 of 20 March 2017 (page 13816), *فتوى دار الإفتاء المصرية في توقيت الفجر*, in reply to the Survey Authority. It says the Fajr time in force in Egypt, at a solar depression of 19.5°, is correct, and that the Survey Authority is "the official Egyptian body that issues the astronomical calendars" containing the prayer times. Its "17.5° for Isha, 19.5° for Fajr" is a quotation it endorses, from the astronomer Mervat Awad (Majallat al-Azhar, 1997). https://www.dar-alifta.org/ar/fatwa/details/13816 (primary for Egypt's practice)
- PrayTimes.org: "Egyptian General Authority of Survey: 19.5 / 17.5". http://praytimes.org/calculation (secondary)
- The Survey Authority's own 2026 timetable for Cairo, https://www.esa.gov.eg/monthlymwaket.aspx, retrieved on 2026-10-18, all 365 days, compared at central Cairo: with 19.5° and 17.5°, no added minutes and rounding to the nearest minute, every prayer is within a minute on every day and matches to the minute on 77–91% of days (SalahTimes' fit; primary data, `docs/validation.md`).

Notes:
- Egypt's Mufti has defended 19.5° against studies that propose a smaller Fajr angle. The preset follows the official value.

## Umm al-Qura

`ummAlQura`: Fajr at 18.5°, Isha 90 minutes after Maghrib.

This is the method of Saudi Arabia's Umm al-Qura calendar.

Sources:
- PrayTimes.org: "Umm al-Qura University, Makkah: 18.5 / 90 minutes after Maghrib, 120 minutes during Ramadan". http://praytimes.org/calculation (secondary)
- PrayTimes.org's reference code: "fajr was 19 degrees before 1430 hijri". http://praytimes.org/code/v2/js/PrayTimes.js, and its methods page: "Fajr angle was 19 degrees in Umm al-Qura method before Muharram 1430 Hijri (December 2008)". https://praytimes.org/docs/methods (secondary)

Notes:
- The official site, https://ummulqura.org.sa (run by KACST), doesn't state the method in a form we could read. All values here are secondary.
- We found no published precautionary minutes.
- The 120-minute Ramadan interval is the basis of the opt-in `ramadanIsha` rule. See [The Ramadan Isha rule](#the-ramadan-isha-rule).

## University of Islamic Sciences, Karachi

`karachi`: Fajr and Isha at 18°.

Sources:
- PrayTimes.org: "University of Islamic Sciences, Karachi: 18 / 18", used in "Pakistan, Afghanistan, Bangladesh, India". http://praytimes.org/calculation and https://praytimes.org/docs/methods (secondary)
- Jamia Uloom-ul-Islamia Allama Banuri Town (جامعہ علوم اسلامیہ, literally "University of Islamic Sciences"), Karachi, whose prayer-time page offers its own method next to ISNA's, the Muslim World League's, Umm al-Qura's and Egypt's: https://www.banuri.edu.pk/namaz-times. Its 2026 times for Karachi, retrieved on 2026-10-18, all 365 days, compared at the city centre with Hanafi Asr: with 18° and 18°, no added minutes and rounding to the nearest minute, every prayer is within a minute on every day and matches to the minute on 78–82% of days (SalahTimes' fit; primary data, `docs/validation.md`).

Notes:
- The Jamia's Darul Ifta holds 18° below the horizon for true dawn: "١٨ درجہ زیرِ افق والا قول معتبر، راجح، اصح و مفتی بہ و معمول بہ ہے" (the view of 18° below the horizon is the reliable, preferred and followed one), fatwa 144008201183 of 18 May 2019, https://www.banuri.edu.pk/readquestion/144008201183/18-05-2019. A fatwa of 3 October 2018 says timetables based on 18° are correct: https://www.banuri.edu.pk/readquestion/144001200384/03-10-2018. Neither states an Isha angle; its prayer-time page uses 18° for both.
- The Jamia also hosts a permanent printed timetable for Karachi, certified by its ulama and those of Darul Uloom Korangi and Jamia Farooqia, which agrees with its page within a minute and advises giving the Fajr adhan 10 minutes after true dawn as a precaution; its times don't include those minutes. https://cdn.banuri.edu.pk/banuri-panel/cdn/pdf/2020/04/20200427120241_2430.pdf
- Most timetables in South Asia use Hanafi Asr, as Banuri Town's, the Islamic Foundation Bangladesh's and Afghanistan's Ministry's do. The preset keeps Shafi'i Asr like every other preset; apps should offer the madhab setting.

## Institute of Geophysics, University of Tehran

`tehran`: Fajr at 17.7°, Maghrib at 4.5°, Isha at 14°, and the night measured from sunset to Fajr.

The Institute's calendar centre computes Iran's official times. Maghrib is later than sunset because the Ja'fari school waits for the eastern redness to pass, which the Institute models as the Sun 4.5° below the horizon.

Sources:
- Khabaronline, 22 August 2010, by Amir Hassanzadeh, a senior expert at the Institute's calendar centre: "The calendar centre of the University of Tehran's Institute of Geophysics, which is responsible for computing the country's prayer times, uses 17.7° below the horizon for the dawn call to prayer", and "Maghrib is when the sun reaches 4.5° of depression". The article also says sunrise and sunset are taken with the Sun's centre 50′ below the horizon, Dhuhr at the Sun's centre on the meridian, and that "اعداد با دقت دقیقه گرد می‌شوند" (the times are rounded to the minute). https://khabaronline.ir/news/86445 (secondary report of the Institute's practice)
- Bahesab, which publishes times by the University of Tehran's rules, defines the shar'i midnight as "the middle of the interval between today's sunset and tomorrow's dawn". https://www.bahesab.ir/time/prayer/ (formerly `/time/sun`; secondary)
- Mehdi Sohrabi, a member of the Institute's calendar council, in a Hawzah News interview republished by Ijtihad Network on 21 April 2020: the council's observations "arrived at 17.7" for Fajr, and it takes 4.5° of depression as the average criterion for Maghrib. He doesn't mention Isha. http://ijtihadnet.ir/%D8%AA%D8%AC%D8%B1%D8%A8%D9%87%D9%87%D8%A7%DB%8C-%D8%B9%D8%B6%D9%88-%D8%B4%D9%88%D8%B1%D8%A7%DB%8C-%D8%AA%D9%82%D9%88%DB%8C%D9%85-%D9%85%D8%A4%D8%B3%D8%B3%D9%87-%DA%98%D8%A6%D9%88%D9%81%DB%8C/ (secondary report of the council's practice)
- PrayTimes.org: Tehran "17.7 / 14", Maghrib 4.5°, midnight "Jafari" (sunset to Fajr), with the note "Isha angle is not explicitly defined in Tehran method". http://praytimes.org/calculation and http://praytimes.org/code/v2/js/PrayTimes.js (secondary)
- The Institute's own 2026 timetable for Tehran, the PDFs for the Persian years 1404 and 1405 listed on its page of provincial capitals' prayer times, https://calendar.ut.ac.ir/%D8%A7%D9%88%D9%82%D8%A7%D8%AA-%D8%B4%D8%B1%D8%B9%D9%8A-%D9%85%D8%B1%D8%A7%DA%A9%D8%B2-%D8%A7%D8%B3%D8%AA%D8%A7%D9%86%D9%87%D8%A7, retrieved on 2026-10-18, all 365 days, for the coordinates they state (35.70° N, 51.42° E). They give Fajr, sunrise, Dhuhr, sunset, Maghrib and midnight. With Fajr at 17.7°, Maghrib at 4.5°, no added minutes and rounding to the nearest minute, every published prayer is within a minute on every day and matches to the minute on 98–99% of days (SalahTimes' fit; primary data, `docs/validation.md`).

Notes:
- The Institute publishes no Isha angle that we could find, and its timetables give no Isha (or Asr) time. Its page on the basis of its computations (مبانی محاسبه اوقات شرعی) is empty. 14° is PrayTimes.org's value, and Bahesab's optional Isha falls at about 14° too; it is uncertain.

## Turkey (Diyanet)

`diyanet`: Fajr at 18°, Isha at 17°, with Diyanet's precautionary minutes (temkin): sunrise −7, Dhuhr +5, Asr +4, Maghrib +7, Fajr and Isha 0.

Sources:
- Diyanet İşleri Başkanlığı, *Temkin*: "7 minutes of temkin are applied at sunrise and sunset: 7 minutes before sunrise is the end of Fajr, and 7 minutes after sunset is the start of Maghrib"; "a temkin of 4 minutes for Asr"; Dhuhr begins "after 5 minutes have passed" from the Sun's culmination; "no temkin is applied to imsak and yatsı". It also says temkin was moderated by the High Board of Religious Affairs in 1982, applied from 1983. https://vakithesaplama.diyanet.gov.tr/temkin.php (primary)
- Diyanet İşleri Başkanlığı, press release of 17 July 2013: its calendars take "the Sun descending 17° below the horizon" for yatsı and "approaching 18°" for imsak, and in 1982 it adopted 18° "in place of 19°" for imsak. Removed from diyanet.gov.tr; the Internet Archive's copy: https://web.archive.org/web/20221222182141/https://www.diyanet.gov.tr/tr-TR/Kurumsal/Detay/2921/basin-aciklamasi (primary)
- Diyanet's own timetable for Ankara, https://namazvakitleri.diyanet.gov.tr/tr-TR/9206, checked on four dates across a year: imsak falls with the Sun at 17.8° to 17.95° below the horizon and yatsı at 17.0° to 17.3°, which fits 18° and 17° (SalahTimes' fit; primary data).

Notes:
- Diyanet's current site doesn't state the 18° and 17° angles; the 2013 press release above does. A 2022 study quotes the 1982 decision itself as setting 16° with ±4 minutes of temkin, which it says wasn't applied as written (T. Erdoğan and İ. Karagözoğlu, *Dini Araştırmalar* 25/63: https://dergipark.org.tr/en/download/article-file/2671884).
- Asr follows the majority view (Shafi'i shadow): "İkindi vakti cumhurun görüşüne göre … hesaplanmaktadır" (Asr is computed according to the majority view), on the calculation criteria of Diyanet's international platform, https://awqatsalah.com/sub/34/tespit-kriterleri.
- Diyanet's calendars for Europe and North America (https://awqatsalah.com) use Isha at 16°, following the International Prayer Times Congress held in Istanbul on 26–27 September 2021 with the European Council for Fatwa and Research (final declaration: https://awqatsalah.com/sub/12/uluslararasi-namaz-vakitleri-kongresi-sonuc-bildirgesi). Its calendars for Muslim-majority countries and Japan still use 17°: on 2026-10-17, Isha fell with the Sun at about 16.1° to 16.4° below the horizon in Rome, Paris, Sarajevo and New York, and at about 17.0° to 17.1° in Cairo, Tunis, Baku and Tokyo. The `diyanet` preset is Turkey's domestic definition. For Diyanet's calendars in Europe and North America, set Isha to 16°.
- Diyanet's high-latitude rules can't be reproduced by SalahTimes. From 44.5° of latitude its calendars abroad cap Isha at Maghrib plus a third of the shar'i night (sunset to true dawn), floor Fajr at sunrise minus (1/3 + 2/16) of that night, phase the switch in over 20 minutes, and keep day and night at least 5 hours long. These rules are on the platform's calculation criteria page, https://awqatsalah.com/sub/34/tespit-kriterleri. An earlier rule, High Board decision 61 of 10 June 2009, used a third of the night above 45°, capped Isha at Maghrib plus 1 hour 20 minutes, set imsak from March to September at sunrise minus that Maghrib-to-Isha interval and 10 minutes, and used the 62° times above 62°: https://kurul.diyanet.gov.tr/tr/kurul/karar/45-enlemin-otesinde-namaz-vakitleri/d681fdc5-924c-4f02-bb74-08dd1c135350. SalahTimes applies its own `recommended` rule instead, so its times differ from Diyanet's above about 45°.
- Diyanet doesn't publish its rounding.

## United Arab Emirates (Dubai)

`dubai`: Fajr and Isha at 18.2°, sunrise 3 minutes earlier, and Dhuhr, Asr and Maghrib 3 minutes later.

The UAE's General Authority of Islamic Affairs and Endowments (Awqaf) doesn't publish its method in a form we could find, so every value is fitted to its official timetables.

Sources:
- Awqaf's official Dubai timetable for 2018 (https://www.awqaf.gov.ae/en/Pages/PrayerTimes.aspx), the first day of each month, as quoted unadjusted in adhan-swift's MIT-licensed test data (`Tests/Data/adhan-swift/Dubai-Gulf.json`). With these values all 72 times agree within a minute; with the angles alone, 24 do (SalahTimes' fit; official data).
- AlAdhan, *Calculation Methods*: the Dubai method is "not an official calculation but based on the research done by the Batoul Apps team", with 18.2° for Fajr and Isha. https://aladhan.com/calculation-methods (secondary)
- The Sheikh Zayed Grand Mosque Centre's timetable for Abu Dhabi, https://www.szgmc.gov.ae/en/worshippers/prayer-timingss, and a Dubai Ramadan timetable published by Gulf News for 18 February 2026: on these three days Fajr and Isha fit 18.2° within half a minute, sunrise is 3 minutes early, and Dhuhr and Maghrib 3 minutes late (SalahTimes' fit; official and press data).

Notes:
- The complete official 2026 Dubai and Abu Dhabi timetables, retrieved on 2026-10-14 from
  Awqaf's public prayer-page service, confirm that the 2018 Asr calibration differs from the
  newer calendars. With the preset as shipped, official Asr is 1–3 minutes earlier in Dubai
  and 2–3 minutes earlier in Abu Dhabi. The other five prayers agree within a minute on every
  day. At the city-centre coordinates used in validation, `parameters.adjustments.asr = -2`
  puts Asr within a minute on all 365 days in both cities. This is a dated, place-specific
  override; the authority does not disclose its reference coordinates or method minutes.
  The preset retains its published 2018 calibration so existing consumers' times stay stable.
  Use an official published timetable when exact authority minutes are required.
- These are the values of adhan-swift's Dubai method. SalahTimes fits them independently from the official table.
- Isha stays angle-based in Ramadan in these timetables.
- Other sources claim 19.5° with Isha 90 minutes after Maghrib (an older "Gulf region" method), or 18° or 18.5°. We found no official statement for any of them.

## Kuwait

`kuwait`: Fajr at 18°, Isha at 17.5°.

Sources:
- AlAdhan, methods list: "Kuwait", Fajr 18°, Isha 17.5°. https://api.aladhan.com/v1/methods (secondary)
- The Al-Ojeiri Scientific Centre, whose calendar "is the official calendar of the State of Kuwait and its approved computation" for years, prayer times and crescents (https://alojeiri.com/ar/aboutUs): its 2026 times for Kuwait, https://alojeiri.com/ar/ojeiri-calendar, retrieved on 2026-10-18, all 365 days, compared at central Kuwait City (29.3697, 47.9783). With 18° and 17.5°, no added minutes and rounding to the nearest minute, every prayer is within a minute on every day but two, one sunrise and one Maghrib off by two minutes (one sunrise, published as 00:00, is left out), and matches to the minute on 67–85% of days (SalahTimes' fit; primary data, [issue #5](https://github.com/salah-kit/SalahTimes/issues/5)).

Notes:
- Neither the Centre nor the Ministry of Awqaf (https://www.awqaf.gov.kw) states the angles, so the preset is a fit to the official calendar, not a documented rule. The Arabeyes ITL documentation lists Kuwait under 18° for both; the calendar's Isha fits 17.5°, not 18°.
- Isha stays angle-based in Ramadan in the Centre's calendar.

## Qatar

`qatar`: Fajr at 18°, Isha 90 minutes after Maghrib.

Qatar Calendar House (Dar al-Taqweem al-Qatari) issues the state's approved calendar. Its about page quotes Council of Ministers resolution 333-23/2008, which makes that calendar the sole reference for dating events and documents; the resolution as quoted doesn't concern prayer times, and the page, which says the House prepares the prayer times, states no method.

Sources:
- Qatar Calendar House, about page. https://qatarch.com/brief-altakwem (primary for the authority; it doesn't state the method)
- Qatar Calendar House, Doha timetable for Ramadan 1447: Fajr falls with the Sun at 18.0° to 18.1° below the horizon, and Isha is exactly Maghrib plus 90 minutes, Ramadan included. https://qatarch.com/public/uploads/orginal/emsakia/emsakya.pdf (SalahTimes' fit; primary data)

Notes:
- A complete **2025** Qatar Calendar House year is now available from its published daily-card
  PDFs, retrieved on 2026-10-14 from the [official releases archive](https://qatarch.com/dar-releases).
  An automated OCR extraction covers all 365 dates and six prayers per date. Every Isha is
  exactly 90 minutes after Maghrib, including Ramadan; this independently supports retaining
  `ramadanIsha: .off` for the Qatar preset. At central Doha coordinates (25.2854, 51.5310),
  official minus unrounded preset times average −1.02 minutes for Fajr, 0.00 for sunrise,
  +0.48 for Dhuhr, +0.51 for Asr and +2.07 for Maghrib/Isha. The largest rounded difference is
  three minutes. The authority's reference coordinates and rounding/precautionary rules are
  still unpublished, and the extraction has automated consistency checks rather than visual
  review of every card. The preset therefore keeps its documented 18°/90-minute starting
  point with no fitted minutes. Use the published timetable for exact official minutes.
  Full 2026 daily-card coverage remains a publisher-availability limitation, separate from
  the completed 2025 comparison.
- The Calendar House's 2026 cards up to 11 October (284 days, retrieved on 2026-10-18) show the same Fajr, sunrise, Maghrib and Isha offsets as 2025 (−0.99, +0.02 and +2.09 minutes at central Doha), with Dhuhr and Asr about half a minute later than in 2025 (+0.97 and +0.99), Isha exactly 90 minutes after Maghrib every day ([issue #5](https://github.com/salah-kit/SalahTimes/issues/5)). Its 1448 cards say Doha's times are the reference for the east coast from al-Khor to al-Wakrah.
- Qatar doesn't lengthen Isha in Ramadan. Leave `ramadanIsha` off for Qatar.

## Singapore (MUIS)

`muis`: Fajr at 20°, Isha at 18°, Dhuhr 1 minute after transit, and times rounded up to the minute.

Majlis Ugama Islam Singapura publishes Singapore's official timetable but not its method, so every value is fitted to the timetable.

Sources:
- MUIS, *Muslim Prayer Timetable 2026*, on data.gov.sg (dataset `d_d441e7242e78efc566024dd5b0d9829c`, Singapore Open Data Licence 1.0), all 365 days, compared at 1.3521° N, 103.8198° E. With these values every prayer except Asr agrees within a minute on all 365 days, and Asr on 361 of them; 62% to 80% of the times match to the minute. Without the Dhuhr minute and the rounding, only 41% of Dhuhr times agree within a minute (SalahTimes' fit; primary data, `Validation/official-timetables/data/`).
- MUIS, *Prayer Timetable 2025*: over the whole year, 20° fits Subuh (18° would be about 8 minutes late) and 18° fits Isyak, and every prayer sits about half a minute after the computed time, Zohor a minute more. https://www.muis.gov.sg/-/media/Files/Corporate-Site/Prayer-Timetable-2025.ashx (SalahTimes' fit; primary data)
- adhan-swift's test data holds 366 days of MUIS times (`Tests/Data/adhan-swift/Singapore-Singapore.json`); every time agrees within a minute with these values.
- PrayTimes.org: "Islamic Religious Council of Singapore: 20 / 18". http://praytimes.org/calculation (secondary)

Notes:
- MUIS publishes neither the Dhuhr minute nor the rounding; both come from the fit. They're also the values of adhan-swift's Singapore method.
- We found no evidence that MUIS has changed its Subuh angle.

## Malaysia (JAKIM)

`jakim`: Fajr at 18°, Isha at 18°, Dhuhr 1 minute after transit.

JAKIM's e-Solat (https://www.e-solat.gov.my) publishes Malaysia's official zone timetables, and the state mufti offices issue them.

Sources:
- Federal Territories Mufti, *Al-Kafi #1638*: Subuh in Malaysia now uses "the Sun's altitude at 18° below the horizon", replacing 20°, following the 116th Muzakarah of the National Fatwa Council on 20–21 November 2019. https://www.muftiwp.gov.my/en/artikel/al-kafi-li-al-fatawi/4271 (primary)
- Kedah State Mufti, *Penentuan Awal Waktu Solat Subuh di Negeri Kedah Darul Aman*: the 2° change equals about 8 minutes ("selisih sebanyak 2° bersamaan 8 minit"), applied in Kedah from 25 February 2020. https://ifatwa.kedah.gov.my/wp-content/uploads/2022/08/1-PENENTUAN-AWAL-WAKTU-SOLAT-SUBUH-DI-NEGERI-KEDAH.pdf (primary)
- Federal Territories Mufti, *Bayan al-Falak* Siri ke-5 (7 January 2022): Subuh and Isyak at "108°" from the zenith (18° below the horizon), Isyak at the disappearance of the red twilight; Maghrib and Syuruk at 90° 50′; and Zuhur at 0° 16′, the Sun's semidiameter, past the meridian. https://www.muftiwp.gov.my/en/artikel/bayan-al-falak/5088-bayan-al-falak-siri-ke-5-isu-ketepatan-waktu-solat-dalam-takwim-waktu-solat-pejabat-mufti (primary)
- Selangor State Mufti, article 66 (9 August 2024): solar noon is "1 minute 4 seconds before" the Sun has passed the meridian, so Zohor is transit plus 1 minute 4 seconds. https://www.muftiselangor.gov.my/2024/08/09/66/ (primary)
- e-Solat's 2026 timetable for zone WLY01 (Kuala Lumpur) fits 18° for Subuh; 20° would be about 8 minutes early (SalahTimes' fit; primary data).
- Federal Territories Mufti, *Bayan al-Falak* Siri ke-17 (9 August 2022), citing JUPEM's *Almanak Falak Syarie 2021*: zone WLY01's prayer times are computed for Kg. Gedangsa, 3° 44′ N, 101° 23′ E, and its sunrise for Cheras, 3° 11′ 24″ N, 101° 45′ 30″ E. https://www.muftiwp.gov.my/en/artikel/bayan-al-falak/5381-bayan-al-falak-siri-ke-17-kaedah-penentuan-waktu-solat (primary)

Notes:
- The preset rounds Zohor's 1 minute 4 seconds to 1 minute.
- Before 2019 Malaysia used 20° for Subuh, and Kelantan 19°. States adopted 18° on different dates.
- Secondary sources describe 1 to 2 minutes of ihtiyati added per prayer, tied to the zone design: a zone's east-west difference may not exceed 2 minutes, and times are computed for its westernmost point. We found no official per-prayer table or rounding rule, so the preset adds nothing else.
- Measured against e-Solat's 2026 timetable for WLY01 (365 days) at its reference stations, the official prayers run about half a minute after the preset before rounding and sunrise half a minute before it, which is rounding the prayers up and sunrise down, with no other minutes added except a seasonal minute in Fajr (May to July) and in Maghrib and Isha (November to January). The preset is within a minute on 89–100% of days. At Kuala Lumpur's centre the same timetable runs 1.8 to 2.0 minutes after the preset; the reference point, not added minutes, explains that. `docs/validation.md` gives a fit, rounding up with sunrise a minute earlier, that brings WLY01 within a minute on 98–100% of days; JAKIM doesn't document that rounding, so the preset keeps rounding to the nearest minute.
- Zones whose stations we haven't found (PNG01, JHR02 and SBH07 were compared) run 1 to 1.5 minutes after the preset at their main cities' centres, by amounts that differ from zone to zone, so no single set of minutes reproduces every zone.
- Imsak is set 10 minutes before Subuh. SalahTimes doesn't compute Imsak.

## Indonesia (Kemenag)

`kemenag`: Fajr at 20°, Maghrib with the Sun 1° below the horizon, Isha at 18°, times rounded up to the minute, then Fajr +2, sunrise −3 (see below), Dhuhr +3, Asr +2, Maghrib +2, Isha +2.

Kemenag's Bimas Islam publishes Indonesia's official schedule (https://bimasislam.kemenag.go.id/jadwalshalat).

Sources:
- Kemenag's Director General of Bimas Islam, Kamaruddin Amin, 21 December 2020: the −20° Subuh criterion "used in making the prayer schedules" is correct in fiqh and science (reported by CNN Indonesia). https://www.cnnindonesia.com/nasional/20201221182418-20-584880/kemenag-waktu-subuh-20-derajat-benar-secara-fikih-dan-sains (secondary report of a primary statement)
- Tgk. Ismail, *Dinamika Jadwal Waktu Salat di Indonesia*, Bildung, 2022, ISBN 978-623-6379-82-0, quoting Kemenag's criteria for its digital schedule: Maghrib at 90° plus a height correction, "Isya −18°, and Subuh −20°, while the ihtiyat value is 2 minutes after the seconds are rounded up"; and Kemenag's *Ephemeris Hisab Rukyat* yearbooks, which used 1 minute for every prayer in 1997–2016 and Zuhur +3 with the others +2 from 2017, as agreed at the 2014 Badan Hisab Rukyat meeting (pages 100–102). https://repository.uinsuna.ac.id/id/eprint/43/ (secondary, quoting primary documents)
- Kemenag's official schedule for Kota Jakarta, 2025, all 365 days: Subuh and Isya sit 2 to 3 minutes after the 20° and 18° times, which fits rounding up then adding 2; Zuhur fits rounding up then adding 3; Terbit sits 2 to 3 minutes before sunrise (SalahTimes' fit; primary data).

Notes:
- Sunrise (Terbit): secondary sources describe dropping the seconds and subtracting 2 minutes, for example N. A. Mufidoh, *Sistem Hisab Awal Waktu Shalat Program Website Bimbingan Masyarakat Islam Kemenag RI*, UIN Walisongo, 2018, describing the *Ephemeris*: https://eprints.walisongo.ac.id/8929/1/SKRIPSI%20LENGKAP.pdf. SalahTimes rounds every time the same way, so the preset subtracts 3 minutes and rounds up, which gives the same minute except when sunrise falls exactly on a whole minute.
- Kemenag's own documents disagree on Zuhur: some give +2 like the other prayers, the 2017–2020 Ephemeris gives +3. The 2025 official data fits +3.
- Maghrib: the Ephemeris puts sunset at a fixed 1° below the horizon, slightly lower than SalahTimes' 50′, and the digital schedule computes Maghrib from 90° plus a height correction. The preset uses 1° for Maghrib. Against the official 2026 schedule for Kota Jakarta (365 days), that matches 97% of Maghrib times to the minute, against 33% with the 50′ sunset, and every prayer agrees within a minute on every day. SalahTimes' `sunset` event stays at 50′.
- Imsak is Subuh minus 10 minutes. SalahTimes doesn't compute Imsak.
- Muhammadiyah moved to 18° for Subuh in December 2020. That is its own schedule, not Kemenag's.

## Moonsighting Committee Worldwide

`moonsightingCommittee`: Fajr and Isha at 18°, bounded by the committee's seasonal values, with the general shafaq for Isha; Dhuhr +5 and Maghrib +3.

The method is Khalid Shaukat's for the Moonsighting Committee Worldwide. The Fiqh Council of North America adopted it in 2011 and replaced it with fixed angles in 2017 (see [ISNA](#isna)).

Sources:
- Moonsighting.com, *How we calculate* (updated 1 March 2024). https://www.moonsighting.com/how-we.html (primary)
- Moonsighting.com, *FAQ on prayer times*. https://www.moonsighting.com/faq_pt.html (primary)
- Syed Khalid Shaukat, *Fajr and Isha*, September 2015, 27 pages. The moonsighting.com links to it no longer resolve; a copy is at https://raw.githubusercontent.com/kskhan77/prayer-times-moonsighting/HEAD/booklet-fajr-isha.pdf (primary text, secondary host)
- The committee's timetable generator, https://www.moonsighting.com/pray.php, compared with the formula below for London, Chicago, Sydney, Karachi, Quito, Aberdeen, Oslo and latitudes from 54° to 70°, north and south, in 2024 and 2026. It agrees within a minute (secondary check).

### The formula

The booklet (§11) gives the seasonal values in minutes. `LT` is the latitude and `DYY` the number of days since the winter solstice.

| Value | A | B | C | D |
|---|---|---|---|---|
| Fajr | 75 + 28.65 × \|LT\| / 55 | 75 + 19.44 × \|LT\| / 55 | 75 + 32.74 × \|LT\| / 55 | 75 + 48.10 × \|LT\| / 55 |
| Isha, general shafaq | 75 + 25.60 × \|LT\| / 55 | 75 + 2.050 × \|LT\| / 55 | 75 − 9.21 × \|LT\| / 55 | 75 + 6.14 × \|LT\| / 55 |
| Isha, shafaq ahmer | 62 + 17.40 × \|LT\| / 55 | 62 − 7.16 × \|LT\| / 55 | 62 + 5.12 × \|LT\| / 55 | 62 + 19.44 × \|LT\| / 55 |
| Isha, shafaq abyad | 75 + 25.60 × \|LT\| / 55 | 75 + 7.16 × \|LT\| / 55 | 75 + 36.84 × \|LT\| / 55 | 75 + 81.84 × \|LT\| / 55 |

    if DYY < 91:  A + (B - A) / 91 × DYY
    elif DYY < 137: B + (C - B) / 46 × (DYY - 91)
    elif DYY < 183: C + (D - C) / 46 × (DYY - 137)
    elif DYY < 229: D + (C - D) / 46 × (DYY - 183)
    elif DYY < 275: C + (B - C) / 46 × (DYY - 229)
    else:          B + (A - B) / 91 × (DYY - 275)

"Fajr is sunrise − MIN and Isha is sunset + MIN", where sunset is the astronomical sunset, not the 3-minute later Maghrib.

- **The bases.** "75 … is the base time in minutes before sunrise for Fajr, and after sunset for Shafaq Abyad, and Shafaq General, which is time for disappearance of Shafaq Abyad observed at 18 degrees at equator. For Shafaq Ahmer that number is 62." The divisor 55 isn't explained; the booklet says only that "these formulae are good up to the 55° latitude". The latitude isn't capped at 55.
- **The day count.** "For Northern Hemisphere start from December 21 (DYY=0 for December 21, and counting forward, DYY=11 for January 1 and so on). For Southern Hemisphere start from June 21." In code: north, `DYY = dayOfYear + 10`, less the year's length once it reaches it; south, `DYY = dayOfYear − 172` (173 in a leap year), plus the year's length if negative. The source doesn't spell out leap years. The generator's output fits this count, and a day either way roughly doubles the error.
- **18° against the seasonal value.** "From equator to 55°, the 18° depression angle calculations are compared with the values given by the functions of latitude and seasons and most favorable values are used, which means; For Fajr, the later of the two and for Isha the earlier of the two." When the Sun doesn't reach 18°, the seasonal value is used, as the booklet's tables and the generator show.
- **From 55°.** "At latitudes between 55° and 60°, the rule of Sab'u Lail (1/7th of the night) is used… two things are calculated for Fajr; one is Tabayyan… and the other is last 1/7th of the night. Fajr time is later of the two. Similarly … Isha time is earlier of the two." So from 55°, the seventh of the night (sunset to sunrise) is an additional bound, and the seasonal value still applies. The generator applies it at exactly 55.0° and −55.0°, and not at 54.99°.
- **Above 60°.** The booklet adds: "If day length is more than 18 hours or less than 6 hours, then we slide down to 60° and calculate Fajr & Isha using the rule of Sab'u Lail", and the FAQ describes a different "aqrab al-bilad" variant. The committee's own generator applies neither. SalahTimes doesn't implement this rule.
- **Dhuhr and Maghrib.** "5 minutes should be added in Noon time for Zuhr", and "For Sunni's, actual sunset is 3 minutes after theoretical sunset". These are the preset's +5 and +3.
- **Shafaq.** Ahmer is the red glow and abyad the whiteness after it. General is "a combination of Shafaq Abyad and Shafaq Ahmer for high latitudes": abyad when nights are long (winter), ahmer when days are long (summer), with a transition in spring and autumn. The how-we page says the reverse in one sentence; the booklet and the coefficients show that sentence is a typo.

Notes:
- The generator's default (method 0) is "Hanafi (Shafaq General)", with Hanafi Asr. The preset keeps Shafi'i Asr like every other preset.
- The booklet's latitude tables on pages 21–23 contradict its own formula and shouldn't be used as test data. Its city tables fit once their "Sunset" column is read as Maghrib (sunset + 3).

## High-latitude rules

Where twilight lasts long or all night, Fajr and Isha computed from an angle come very early or late, or not at all. SalahTimes bounds them by a portion of the night from sunset to sunrise (`docs/algorithm.md` §8.1). Every preset uses `recommended`.

- **Middle of the night** (`middleOfTheNight`): "the period from sunset to sunrise is divided into two halves. The first half is considered to be the 'night' and the other half as 'day break'. Fajr and Isha in this method are assumed to be at mid-night during the abnormal periods."
- **Seventh of the night** (`seventhOfTheNight`): "the period between sunset and sunrise is divided into seven parts. Isha begins after the first one-seventh part, and Fajr is at the beginning of the seventh part." The Moonsighting Committee uses the same rule from 55° (see above).
- **Twilight angle** (`twilightAngle`): "Let α be the twilight angle for Isha, and let t = α/60. The period between sunset and sunrise is divided into t parts. Isha begins after the first part." Fajr is computed the same way.

Source for all three: Hamid Zarrabi-Zadeh, PrayTimes.org, *Prayer Times Calculation*, "Higher Latitudes". http://praytimes.org/calculation (secondary)

**Why the seventh beyond 48°.** `recommended` picks `seventhOfTheNight` beyond 48° of latitude, north or south, and `middleOfTheNight` elsewhere.
- The Sun stays less than 18° below the horizon all night at the summer solstice beyond about 90° − 23.44° − 18° = 48.56°, so an 18° Fajr or Isha stops existing for part of the year there.
- The Muslim World League's Islamic Fiqh Council drew its line at the same latitude. Its ninth session (Makkah, sixth resolution, 19 Rajab 1406 AH, 30 March 1986) resolved: "As for countries between latitudes 48 and 66 degrees north and south, the times of Isha and Fajr are determined by proportional estimation from their counterparts in the night of the nearest place where the signs of Isha and Fajr are distinguishable, and the Council proposes latitude 45 degrees". A later clarification restricts this to times when the sign doesn't appear at all. The resolution, as the League published it: https://web.archive.org/web/20160806121152id_/http://www.themwl.org/Fatwa/default.aspx?d=1&cidi=110&l=AR&cid=11 (primary; the Internet Archive's copy). Also quoted in Dar al-Ifta al-Misriyyah, fatwa 2259 (6 June 2012), with the clarification: https://www.dar-alifta.org/ar/fatwa/details/13433.
- The International Astronomical Center's work with the League on European timetables uses the zone between 48.6° and 66.6°. https://astronomycenter.net/latitude.html (secondary)
- The seventh of the night is a practical stand-in for these rulings, not the Council's own method. The Council's proportional estimation from 45° and the IAC's "local relative estimation" aren't implemented. A middle-of-the-night bound below 48° rarely changes a time, because twilight there ends well before the middle of the night.

## The Ramadan Isha rule

Umm al-Qura's timetables put Isha 120 minutes after Maghrib during Ramadan instead of 90. PrayTimes.org documents it: "90 minutes after Maghrib, 120 minutes during Ramadan" (http://praytimes.org/calculation, secondary). We found no official statement of the rule.

SalahTimes offers it as `ramadanIsha = .interval(minutes: 120, hijriDayOffset: 0)`, off in every preset. It changes only a positive `minutesAfterMaghrib` interval, on days in month 9 of the Umm al-Qura calendar (`docs/algorithm.md` §8.7). It's off by default because:
- Qatar, which also uses a 90-minute interval, keeps 90 minutes in Ramadan in its official 1447 timetable;
- the start of Ramadan announced by sighting can differ from the calendar by a day, which `hijriDayOffset` handles;
- mosques outside Saudi Arabia that follow Umm al-Qura differ in whether they lengthen Isha.

## Qibla: the Kaaba's coordinates

SalahTimes uses 21.4225241° N, 39.8261818° E (`docs/algorithm.md` §10).

- The point lies inside the Kaaba's outline in OpenStreetMap, way 103914569 (الكعبة), whose centroid is 21.4225079° N, 39.8261890° E. https://www.openstreetmap.org/way/103914569
- Wikidata gives 21.4225° N, 39.826167° E for the Kaaba (Q29466). https://www.wikidata.org/wiki/Q29466
- The three points are within about 3 metres of each other. The Kaaba is about 11 by 13 metres, so the choice has no measurable effect on a Qibla bearing.

## Country suggestions

`CalculationMethod.suggested(forCountryCode:)` returns a method for a country only when a source supports it. A suggestion is a starting point for a default, not a ruling. Countries without one return `nil`; the app decides, ideally by asking the user. `Vectors/country-methods.json` holds the same table with the sources.

A suggestion is kept when the country's official religious authority states its method, when a reputable source documents prevailing practice, or when the authority's own published timetable matches the preset's angles. The last case is SalahTimes' own fit of official data and is marked as such.

| Code | Country | Method | Source |
|---|---|---|---|
| AE | United Arab Emirates | `dubai` | AlAdhan's Dubai method; its angles fit the official Abu Dhabi timetable (see [Dubai](#united-arab-emirates-dubai)). Secondary. |
| AF | Afghanistan | `karachi` | PrayTimes.org regions (https://praytimes.org/docs/methods). Secondary. |
| BD | Bangladesh | `karachi` | PrayTimes.org regions. Secondary. |
| BN | Brunei | `muis` | Ministry of Religious Affairs timetable (https://www.mora.gov.bn/SitePages/WaktuSembahyang.aspx) fits 20° and 18°. SalahTimes' fit. |
| CA | Canada | `moonsightingCommittee` | Fiqh Council of North America, 2011 (see [ISNA](#isna)); FCNA's current page suggests 13° ([#8](https://github.com/salah-kit/SalahTimes/issues/8)). |
| DZ | Algeria | `muslimWorldLeague` | Ministry of Religious Affairs calendar for Algiers (https://marw.gov.dz/media/calendrier/1448/Alger.pdf) fits 18° and 17°. SalahTimes' fit. |
| EG | Egypt | `egyptian` | Dar al-Ifta, fatwa 4021 (page 13816). Primary. |
| ID | Indonesia | `kemenag` | Kemenag publishes the national schedule. Primary. |
| IN | India | `karachi` | PrayTimes.org regions. Secondary; India has no national authority. |
| IR | Iran | `tehran` | The Institute of Geophysics computes Iran's official times (Khabaronline). |
| JO | Jordan | `karachi` | Ministry of Awqaf timetable for Amman (https://www.awqaf.gov.jo/ar/Pages/PrayerTime) fits 18° and 18°. SalahTimes' fit. |
| KW | Kuwait | `kuwait` | The Al-Ojeiri Scientific Centre's official calendar (https://alojeiri.com/ar/ojeiri-calendar) fits 18° and 17.5° (see [Kuwait](#kuwait)). SalahTimes' fit. |
| MY | Malaysia | `jakim` | JAKIM's e-Solat publishes the national zone timetables. Primary. |
| PK | Pakistan | `karachi` | PrayTimes.org regions. Secondary. |
| QA | Qatar | `qatar` | Qatar Calendar House timetable fits 18° and 90 minutes. Primary data, SalahTimes' fit. |
| SA | Saudi Arabia | `ummAlQura` | The Umm al-Qura calendar is Saudi Arabia's official calendar; PrayTimes.org lists the method for the Arabian Peninsula. Secondary. |
| SG | Singapore | `muis` | MUIS publishes the national timetable. Primary. |
| TN | Tunisia | `karachi` | Ministry of Religious Affairs data for Tunis (https://www.affaires-religieuses.tn/public/getData/1) fits 18° and 18°. SalahTimes' fit. |
| TR | Turkey | `diyanet` | Diyanet publishes Turkey's official times. Primary. |
| US | United States | `moonsightingCommittee` | Fiqh Council of North America, 2011 (see [ISNA](#isna)); FCNA's current page suggests 15°, the `isna` preset ([#8](https://github.com/salah-kit/SalahTimes/issues/8)). |

Known differences in these countries:
- Jordan's timetable puts Maghrib about 6.5 minutes after sunset and sunrise about 6.5 minutes before it (October to December 2026; [#9](https://github.com/salah-kit/SalahTimes/issues/9)), Tunisia's Maghrib about 2 minutes after sunset and Dhuhr about 7 after the transit, on the two days available ([#10](https://github.com/salah-kit/SalahTimes/issues/10)), and Algeria's Maghrib about 3.5 minutes after sunset. The suggested presets don't include these minutes.
- Algeria's 2026 calendar for Algiers fits rounding up: with `rounding: .up`, Fajr, sunrise, Dhuhr, Asr and Isha match it to the minute on 90–98% of days (every day of the year, leaving out 11 Isha times printed an hour late).
- Brunei's 2026 timetable fits rounding to the nearest minute, so the `muis` preset, whose upward rounding is fitted to MUIS's timetable, gives Brunei's minute on about half the days and is never more than a minute off (2026, Brunei-Muara; [issue #5](https://github.com/salah-kit/SalahTimes/issues/5)). The Ministry adds 3 minutes for Belait district and 1 for Tutong.
- The Islamic Foundation Bangladesh's permanent timetable for Dhaka (https://web.archive.org/web/20200424211525id_/http://www.islamicfoundation.gov.bd//sites/default/files/files/islamicfoundation.portal.gov.bd/page/e64eafb0_5067_44ac_aa4e_a2e2545a454b/Calender_permanent%20fr%20Sahri%20&%20Iftar%20(1).pdf, the Internet Archive's copy) adds 3 minutes to Fajr, Dhuhr and Maghrib, and uses Hanafi Asr; in February 2025 it announced that sehri, the Fajr adhan and iftar no longer carry those minutes (https://objectstorage.ap-dcc-gazipur-1.oraclecloud15.com/n/axvjbnqprylg/b/V2Ministry/o/office-islamicfoundation/2024/12/54660c350c61491e80f52729e33d4831.pdf). Afghanistan's Ministry's Kabul table (https://mohia.gov.af/dr/%D8%AC%D8%AF%D9%88%D9%84-%D8%AF%D8%A7%DB%8C%D9%85%DB%8C-%D8%A7%D9%88%D9%82%D8%A7%D8%AA-%D9%86%D9%85%D8%A7%D8%B2-%D9%87%D8%A7%DB%8C-%D9%BE%D9%86%DA%86%DA%AF%D8%A7%D9%86%D9%87-%D8%B4%D9%87%D8%B1%DA%A9%D8%A7%D8%A8%D9%84) uses Hanafi Asr and puts Maghrib about 3 minutes after sunset in a 15-day sample.

Entries that were dropped from the country table of a 2026 rebuild of Batoul Apps' Guidance for Mac (https://github.com/batoulapps/GuidanceMac/pull/8), and why:
- **Morocco (MA).** The Ministry of Habous timetable for Rabat (https://www.habous.gov.ma/prieres/horaire_hijri_2.php?ville=1) fits Fajr at 19° and Isha at 17°, with Maghrib about 4 minutes after sunset. No preset matches; `egyptian` would put Fajr about 3 minutes early.
- **Algeria (DZ)** moved from `egyptian` to `muslimWorldLeague`, which its timetable fits.
- **Sudan, South Sudan, Libya, Lebanon, Syria, Israel, Palestine, Iraq (SD, SS, LY, LB, SY, IL, PS, IQ)** were `egyptian`. Only aggregator sites support any method for them, and they disagree. PrayTimes.org lists the Egyptian method for "Africa, Syria, Lebanon, Malaysia", which is too broad to rely on; Malaysia, for one, has its own method.
- **Malaysia (MY)** was `egyptian`; it's now `jakim`. **Turkey (TR)** was `egyptian`; it's now `diyanet`.
- **Bahrain, Oman, Yemen (BH, OM, YE)** were `qatar`. Bahrain's official Islamiyat app gives an angle-based Isha near 18°, not 90 minutes; for Oman and Yemen no official source was found and secondary sources disagree.
- **United Kingdom (GB, and the non-ISO "UK")** was `moonsightingCommittee`. Britain has no national authority, and mosques use different timetables: some based on the Hizbul Ulama observations, some on 18°, some on the committee's method (for example, the East London Mosque explains its own basis at https://www.eastlondonmosque.org.uk/prayer-times-and-calendar-explained).
- **The default** (`muslimWorldLeague` for everything else) isn't carried over. A missing suggestion returns `nil`.

## Differences from adhan-swift's presets

adhan-swift (https://github.com/batoulapps/adhan-swift, MIT) is the Swift library Batoul Apps' Guidance for Mac calculates with. SalahTimes doesn't copy its code. These are the parameters that differ from its `CalculationMethod.params` and METHODS.md, and why.

| Method | adhan-swift | SalahTimes | Reason |
|---|---|---|---|
| `muslimWorldLeague`, `egyptian`, `karachi` | Dhuhr +1 | no minutes | None of these authorities requires a Dhuhr minute. The Muslim World League's resolution allows an optional two (see [Muslim World League](#muslim-world-league)). |
| `northAmerica` → `isna` | Dhuhr +1 | no minutes | As above. The name follows the authority. |
| (Malaysia) `singapore` → `jakim` | 20° / 18° | 18° / 18°, Dhuhr +1 | Malaysia moved Subuh to 18° in 2019; Zohor is transit plus 1 minute 4 seconds. |
| (Indonesia) `singapore` → `kemenag` | 20° / 18°, Dhuhr +1, rounding up | 20° / 18°, Maghrib at 1°, Fajr +2, sunrise −3, Dhuhr +3, Asr +2, Maghrib +2, Isha +2, rounding up | Kemenag's documented ihtiyat and Maghrib altitude. |
| `turkey` → `diyanet` | same values | same values | Only the name changed. |
| `singapore` → `muis` | same values | same values | Fitted independently to MUIS's 2026 timetable. |
| `ummAlQura` | "add a +30 minute custom adjustment for Isha during Ramadan" | the opt-in `ramadanIsha` rule | The rule applies only in Ramadan, by the Umm al-Qura calendar. |
| `moonsightingCommittee` | from `latitude >= 55`, the night's seventh replaces the 18° time, and the seasonal bound still applies to it | the 18° time always counts: Fajr is the latest and Isha the earliest of the 18° time, the seasonal bound and, from 55° of absolute latitude, the night's seventh | The committee's booklet bounds the twilight time rather than replacing it, and its generator applies the seventh at −55° too. adhan-swift compares the signed latitude, so it never applies the rule in the southern hemisphere. |
| `recommended` (the high-latitude rule) | the seventh of the night when `latitude > 48` | the seventh of the night beyond 48° of absolute latitude | adhan-swift compares the signed latitude, so it picks the middle of the night everywhere in the southern hemisphere, Ushuaia included. |
| `tehran` | Maghrib at 4.5° only when it falls between sunset and Isha | Maghrib at 4.5°, bounded like Isha by the high-latitude rule | A behavior difference, not a parameter (`docs/algorithm.md` §8.3). |
| `other` | all angles 0 | no preset | Custom methods build `CalculationParameters` directly. |

The following are unchanged: every Fajr and Isha angle and interval except JAKIM's; Diyanet's temkin; Dubai's minutes, fitted independently to Awqaf's 2018 timetable; the Moonsighting Committee's coefficients and its Dhuhr +5 and Maghrib +3; and `recommended` as every preset's high-latitude rule.
