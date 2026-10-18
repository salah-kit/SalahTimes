"""Fetcher boundaries: the right addresses are requested and pages parse to the CSV rows."""

import calendar
import datetime
import importlib.util
import pathlib
import unittest
import zlib

SPEC = importlib.util.spec_from_file_location(
    "fetch", pathlib.Path(__file__).with_name("fetch.py"))
FETCH = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(FETCH)


def diyanet_page(caption, rows):
    cells = "".join(
        "<tr>" + "".join(f"<td>{cell}</td>" for cell in row) + "</tr>" for row in rows)
    return f'<table><caption id="{caption}"></caption>{cells}</table>'


class FakeClient:
    """Answers each requested URL from a dictionary and records the requests."""

    def __init__(self, pages):
        self.pages = pages
        self.requested = []

    def request(self, url, data=None, headers=None, binary=False):
        self.requested.append(url)
        return self.pages[url]


TURKISH_MONTHS = ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos",
                  "Eylül", "Ekim", "Kasım", "Aralık"]


def diyanet_yearly(year=2026, skip=()):
    """Rows of a yearly table: 31 December of the year before, then every day of the year."""
    days = [datetime.date(year - 1, 12, 31)]
    day = datetime.date(year, 1, 1)
    while day.year == year:
        if day not in skip:
            days.append(day)
        day += datetime.timedelta(days=1)
    return [[f"{day.day:02d} {TURKISH_MONTHS[day.month - 1]} {day.year} Perşembe",
             "12 Recep 1447", "6:59", "8:30", "13:04", "15:29", "17:27", "18:53"]
            for day in days]


class DiyanetTests(unittest.TestCase):
    PAGE = "https://namazvakitleri.diyanet.gov.tr/tr-TR/9930/van-namaz-vakitleri"
    ARCHIVED = "https://namazvakitleri.diyanet.gov.tr/tr-TR/9930/van-icin-"

    def source(self, **fetch):
        return {"fetch": {"kind": "diyanet", "page": self.PAGE, "snapshot": "20260421213524",
                          "year": 2026, **fetch}}

    def client(self, archived_url, yearly=None):
        yearly = yearly or diyanet_yearly()
        return FakeClient({
            archived_url: diyanet_page("table-caption-yearly", yearly),
            self.PAGE: diyanet_page("table-caption-monthly", yearly[290:320]),
        })

    def test_archived_copy_of_the_page_itself(self):
        archived = f"https://web.archive.org/web/20260421213524id_/{self.PAGE}"
        client = self.client(archived)
        rows = FETCH.fetch_diyanet(client, self.source())
        self.assertEqual(client.requested, [archived, self.PAGE])
        self.assertEqual(len(rows), 365)  # Without 31 December 2025.
        self.assertEqual(rows[0], ["2026-01-01", "06:59", "08:30", "13:04", "15:29", "17:27",
                                   "18:53"])

    def test_archived_copy_under_another_address(self):
        archived = f"https://web.archive.org/web/20260421213524id_/{self.ARCHIVED}"
        client = self.client(archived)
        rows = FETCH.fetch_diyanet(client, self.source(archivedPage=self.ARCHIVED))
        self.assertEqual(client.requested, [archived, self.PAGE])
        self.assertEqual(len(rows), 365)

    def test_an_incomplete_year_is_rejected(self):
        archived = f"https://web.archive.org/web/20260421213524id_/{self.PAGE}"
        client = self.client(archived, diyanet_yearly(skip={datetime.date(2026, 6, 1)}))
        with self.assertRaises(ValueError):
            FETCH.fetch_diyanet(client, self.source())

    def test_parse_keeps_every_row_and_pads_hours(self):
        rows = FETCH.parse_diyanet_table(
            diyanet_page("table-caption-yearly", diyanet_yearly()[:2]), "table-caption-yearly")
        self.assertEqual([row[0] for row in rows], ["2025-12-31", "2026-01-01"])
        self.assertEqual(rows[0][1:3], ["06:59", "08:30"])


WEEKDAYS = ["00c4", "00c400ae", "00c400c1", "00c400c4", "00c400c5", "00c400c6", "00c7"]


def ut_calendar_pdf(lengths=(31,) * 6 + (30,) * 5 + (29,), weekday=lambda day: day % 7,
                    split=17):
    """A PDF whose compressed content streams draw the Institute's rows, cut mid-row."""
    operators = []
    day_of_year = 0
    for length in lengths:
        for day in range(1, length + 1):
            glyphs = WEEKDAYS[weekday(day_of_year)]
            operators += [f"({day})Tj", f"<{glyphs}>Tj", "( )Tj", "<00ae>Tj"]
            minute = day_of_year % 60
            for hour in (4, 6, 12, 18, 18, 23):
                operators += [f"({hour}:{minute:02d})Tj", "-5.8 0 TD"]
            day_of_year += 1
    pdf = b"%PDF-1.4\n"
    # Rows have 16 operators, so streams of 17 end mid-row, as the Institute's pages do.
    for start in range(0, len(operators), split):
        content = "\n".join(operators[start:start + split]).encode()
        pdf += b"1 0 obj<<>>stream\n" + zlib.compress(content) + b"\nendstream endobj\n"
    pdf += b"2 0 obj<<>>stream\nnot compressed\nendstream endobj\n"
    return pdf


class UTCalendarTests(unittest.TestCase):
    def test_rows_across_split_streams(self):
        days = FETCH.parse_ut_calendar(ut_calendar_pdf())
        self.assertEqual(len(days), 365)
        self.assertEqual(days[0], ["04:00", "06:00", "12:00", "18:00", "18:00", "23:00"])
        self.assertEqual(days[364][0], "04:04")

    def test_leap_year(self):
        lengths = (31,) * 6 + (30,) * 6
        self.assertEqual(len(FETCH.parse_ut_calendar(ut_calendar_pdf(lengths))), 366)

    def test_layout_changes_are_rejected(self):
        for pdf in (
                ut_calendar_pdf((31,) * 6 + (30,) * 4 + (29,)),  # A month missing.
                ut_calendar_pdf((31,) * 5 + (30,) + (30,) * 5 + (29,)),  # Wrong month length.
                ut_calendar_pdf(weekday=lambda day: (day + (day >= 100)) % 7)):  # A day lost.
            with self.assertRaises(ValueError):
                FETCH.parse_ut_calendar(pdf)

    def documents(self):
        return [{"url": "https://example.org/1404.pdf", "firstDay": "2025-03-21"},
                {"url": "https://example.org/1405.pdf", "firstDay": "2026-03-21"}]

    def test_gregorian_year_from_two_persian_years(self):
        client = FakeClient({document["url"]: ut_calendar_pdf()
                             for document in self.documents()})
        source = {"fetch": {"kind": "ut-calendar", "year": 2026, "documents": self.documents()}}
        rows = FETCH.fetch_ut_calendar(client, source)
        self.assertEqual(len(rows), 365)
        self.assertEqual(rows[0][0], "2026-01-01")
        self.assertEqual(rows[-1][0], "2026-12-31")
        # 1 January 2026 is day 287 of 1404; Asr and Isha aren't published.
        self.assertEqual(rows[0], ["2026-01-01", "04:46", "06:46", "12:46", "", "18:46", ""])
        self.assertEqual(rows[79][0], "2026-03-21")
        self.assertEqual(rows[79][1], "04:00")

    def test_incomplete_year_is_rejected(self):
        documents = self.documents()[1:]
        client = FakeClient({documents[0]["url"]: ut_calendar_pdf()})
        source = {"fetch": {"kind": "ut-calendar", "year": 2026, "documents": documents}}
        with self.assertRaises(ValueError):
            FETCH.fetch_ut_calendar(client, source)


class ESATests(unittest.TestCase):
    CITY = "القـاهـرة"  # The option's value carries tatweels.

    def page(self, month, state):
        rows = ""
        if month:
            for day in range(1, calendar.monthrange(2026, month)[1] + 1):
                rows += (f"<tr><td>القاهرة</td><td>2026-{month:02d}-{day:02d}</td><td>1 رجب</td>"
                         "<td>5:4 ص</td><td>6:30 ص</td><td>12:2 م</td><td>3:15 م</td>"
                         "<td>5:4 م</td><td>12:20 ص</td></tr>")
        return (f'<input type="hidden" name="__VIEWSTATE" id="__VIEWSTATE" value="{state}" />'
                '<select name="ctl00$placeholder1$DropDownList1"><option value="الجيزة">الجيزة'
                f'</option><option value="{self.CITY}">القاهرة</option></select>'
                f"<table><tr><th>المدينة</th></tr>{rows}</table>")

    def test_city_then_each_month_is_posted_back(self):
        posts = []

        class Client:
            def request(client, url, data=None, headers=None, binary=False):
                posts.append(data)
                month = int(data["ctl00$placeholder1$DropDownList2"]) if data else 0
                return self.page(month, f"state{len(posts)}")

        source = {"fetch": {"kind": "esa", "city": "القاهرة", "year": 2026}}
        rows = FETCH.fetch_esa(Client(), source)
        self.assertEqual(len(rows), 365)
        self.assertEqual(rows[0], ["2026-01-01", "05:04", "06:30", "12:02", "15:15", "17:04",
                                   "00:20"])
        self.assertIsNone(posts[0])
        self.assertEqual(posts[1]["__EVENTTARGET"], "ctl00$placeholder1$DropDownList1")
        self.assertEqual(posts[1]["ctl00$placeholder1$DropDownList1"], self.CITY)
        self.assertEqual(posts[2]["__EVENTTARGET"], "ctl00$placeholder1$DropDownList2")
        self.assertEqual(posts[2]["__VIEWSTATE"], "state2")  # The previous answer's state.
        self.assertEqual([post["ctl00$placeholder1$DropDownList2"] for post in posts[2:]],
                         [str(month) for month in range(1, 13)])

    def test_clocks(self):
        self.assertEqual(FETCH.esa_clock("12:53 م"), "12:53")
        self.assertEqual(FETCH.esa_clock("12:05 ص"), "00:05")
        self.assertEqual(FETCH.esa_clock("7:9 م"), "19:09")
        with self.assertRaises(ValueError):
            FETCH.esa_clock("7:09")


class BanuriTests(unittest.TestCase):
    TODAY = datetime.date(2026, 10, 18)

    def page(self, month, today=None):
        name = FETCH.BANURI_MONTHS[month - 1]
        rows = ""
        for day in range(1, calendar.monthrange(2026, month)[1] + 1):
            attributes = ' style="background-color: #e8ddd3"' if day == today else ""
            rows += (f"<tr{attributes}><td>{day:02d} {name}</td><td>06:01</td><td>07:21</td>"
                     "<td>12:31</td><td>16:01</td><td>17:51</td><td>19:11</td></tr>")
        return f"<table><thead><tr><th>تاریخ</th></tr></thead><tbody>{rows}</tbody></table>"

    def source(self):
        return {"fetch": {"kind": "banuri", "country": "110-Pakistan", "city": "7487-Karachi - ",
                          "method": 1, "asrMethod": 1, "year": 2026}}

    def test_a_month_per_request_including_today(self):
        requested = []

        class Client:
            def request(client, url, data=None, headers=None, binary=False):
                requested.append(url)
                month = len(requested)
                return self.page(month, today=18 if month == 10 else None)

        rows = FETCH.fetch_banuri(Client(), self.source(), today=self.TODAY)
        self.assertEqual(len(rows), 365)
        self.assertEqual(rows[0], ["2026-01-01", "06:01", "07:21", "12:31", "16:01", "17:51",
                                   "19:11"])
        self.assertIn("city=7487-Karachi%20-%20", requested[0])
        self.assertIn("time_method=1", requested[0])

    def test_a_row_for_another_month_is_rejected(self):
        class Client:
            def request(client, url, data=None, headers=None, binary=False):
                return self.page(1)

        with self.assertRaises(ValueError):
            FETCH.fetch_banuri(Client(), self.source(), today=self.TODAY)

    def test_a_fetch_outside_the_year_is_rejected(self):
        # The page computes the current year, so 2027's times would be saved as 2026's.
        class Client:
            def request(client, url, data=None, headers=None, binary=False):
                raise AssertionError("nothing should be requested")

        with self.assertRaises(ValueError):
            FETCH.fetch_banuri(Client(), self.source(), today=datetime.date(2027, 1, 2))


def days_of(year, skip=()):
    day, days = datetime.date(year, 1, 1), []
    while day.year == year:
        if day not in skip:
            days.append(day)
        day += datetime.timedelta(days=1)
    return days


class JAKIMTests(unittest.TestCase):
    URL = ("https://www.e-solat.gov.my/index.php?r=esolatApi/takwimsolat&period=year"
           "&zone=WLY01")
    MONTHS = ["Jan", "Feb", "Mac", "Apr", "Mei", "Jun", "Jul", "Ogos", "Sep", "Okt", "Nov",
              "Dis"]

    def client(self, days):
        import json
        times = {"fajr": "06:01:00", "syuruk": "07:21:00", "dhuhr": "13:11:00",
                 "asr": "16:31:00", "maghrib": "19:11:00", "isha": "20:21:00"}
        body = {"prayerTime": [
            {"date": f"{day.day:02d}-{self.MONTHS[day.month - 1]}-{day.year}", **times}
            for day in days]}
        return FakeClient({self.URL: json.dumps(body)})

    def test_a_whole_year(self):
        rows = FETCH.fetch_jakim(self.client(days_of(2026)), {"fetch": {"zone": "WLY01"}})
        self.assertEqual(len(rows), 365)
        self.assertEqual(rows[0], ["2026-01-01", "06:01", "07:21", "13:11", "16:31", "19:11",
                                   "20:21"])

    def test_an_incomplete_year_is_rejected(self):
        client = self.client(days_of(2026, skip={datetime.date(2026, 8, 31)}))
        with self.assertRaises(ValueError):
            FETCH.fetch_jakim(client, {"fetch": {"zone": "WLY01"}})

    def test_rows_from_two_years_are_rejected(self):
        client = self.client(days_of(2026)[1:] + [datetime.date(2027, 1, 1)])
        with self.assertRaises(ValueError):
            FETCH.fetch_jakim(client, {"fetch": {"zone": "WLY01"}})


class KemenagTests(unittest.TestCase):
    PROVINCE, CITY = "a" * 32, "b" * 32

    def client(self, skip=()):
        import json
        test = self

        class Client:
            def request(client, url, data=None, headers=None, binary=False):
                if url.endswith("/jadwalshalat"):
                    return f'<option value="{test.PROVINCE}">JAWA TIMUR</option>'
                if url.endswith("/getKabkoshalat"):
                    return f'<option value="{test.CITY}">KOTA SURABAYA</option>'
                month = data["bln"]
                days = [day for day in days_of(2026) if day.month == month and day not in skip]
                times = {"subuh": "04:01", "terbit": "05:21", "dzuhur": "11:31",
                         "ashar": "14:51", "maghrib": "17:31", "isya": "18:41"}
                return json.dumps({"status": 1, "data": {day.isoformat(): times for day in days}})

        return Client()

    def source(self):
        return {"fetch": {"kind": "kemenag", "province": "JAWA TIMUR", "city": "KOTA SURABAYA",
                          "year": 2026}}

    def test_a_whole_year(self):
        rows = FETCH.fetch_kemenag(self.client(), self.source())
        self.assertEqual(len(rows), 365)
        self.assertEqual(rows[0], ["2026-01-01", "04:01", "05:21", "11:31", "14:51", "17:31",
                                   "18:41"])

    def test_an_incomplete_year_is_rejected(self):
        with self.assertRaises(ValueError):
            FETCH.fetch_kemenag(self.client(skip={datetime.date(2026, 2, 14)}), self.source())


class SourcesTests(unittest.TestCase):
    def test_every_source_has_a_fetcher_and_a_unique_file(self):
        import json
        sources = json.loads(
            pathlib.Path(__file__).with_name("sources.json").read_text(encoding="utf-8"))
        ids = [source["id"] for source in sources["sources"]]
        files = [source["file"] for source in sources["sources"]]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertEqual(len(files), len(set(files)))
        for source in sources["sources"]:
            kind = source["fetch"]["kind"]
            self.assertTrue(kind in FETCH.FETCHERS or kind == "awqaf-export", source["id"])


if __name__ == "__main__":
    unittest.main()
