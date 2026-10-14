"""Import boundaries: wrong place, incomplete coverage and ambiguous times must fail."""

import copy
import datetime
import importlib.util
import pathlib
import unittest

SPEC = importlib.util.spec_from_file_location(
    "import_awqaf", pathlib.Path(__file__).with_name("import-awqaf.py"))
IMPORTER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(IMPORTER)


class AwqafImportTests(unittest.TestCase):
    def setUp(self):
        self.source = {"fetch": {"year": 2026, "officialId": 69}}
        first = datetime.date(2026, 1, 1)
        records = []
        for index in range(365):
            records.append({
                "date": (first + datetime.timedelta(days=index)).isoformat(),
                "fajer": "05:42", "shuroq": "07:02", "dhohur": "12:23",
                "aser": "15:22", "maghreb": "17:42", "isha": "19:01",
            })
        self.response = {"errors": [], "result": {
            "meta_data": {"location": {"CountryID": "224", "official_id": "69"},
                          "method": {"official": True}},
            "prayer_times": records,
        }}

    def test_complete_year_mapping_and_sorting(self):
        self.response["result"]["prayer_times"].reverse()
        rows = IMPORTER.rows_from_response(self.source, self.response)
        self.assertEqual(len(rows), 365)
        self.assertEqual(rows[0], [
            "2026-01-01", "05:42", "07:02", "12:23", "15:22", "17:42", "19:01"])
        self.assertEqual(rows[-1][0], "2026-12-31")

    def test_wrong_city_country_and_nonofficial_data_are_rejected(self):
        for field, value in [("official_id", "38"), ("CountryID", "108")]:
            with self.subTest(field=field):
                response = copy.deepcopy(self.response)
                response["result"]["meta_data"]["location"][field] = value
                with self.assertRaises(ValueError):
                    IMPORTER.rows_from_response(self.source, response)
        self.response["result"]["meta_data"]["method"]["official"] = False
        with self.assertRaises(ValueError):
            IMPORTER.rows_from_response(self.source, self.response)

    def test_missing_duplicate_extra_and_noncanonical_dates_are_rejected(self):
        for replacement in [None, "2026-01-02", "2027-01-01", "20260101"]:
            with self.subTest(replacement=replacement):
                response = copy.deepcopy(self.response)
                if replacement is None:
                    response["result"]["prayer_times"].pop(0)
                else:
                    response["result"]["prayer_times"][0]["date"] = replacement
                with self.assertRaises(ValueError):
                    IMPORTER.rows_from_response(self.source, response)

    def test_invalid_and_unordered_wall_times_are_rejected(self):
        for replacement in ["24:00", "5:42", "05:60", "19:30", "07:02"]:
            with self.subTest(replacement=replacement):
                response = copy.deepcopy(self.response)
                response["result"]["prayer_times"][0]["fajer"] = replacement
                with self.assertRaises(ValueError):
                    IMPORTER.rows_from_response(self.source, response)

    def test_leap_year_requires_every_date(self):
        self.source["fetch"]["year"] = 2024
        records = self.response["result"]["prayer_times"]
        for index, record in enumerate(records):
            record["date"] = (datetime.date(2024, 1, 1)
                              + datetime.timedelta(days=index)).isoformat()
        with self.assertRaises(ValueError):
            IMPORTER.rows_from_response(self.source, self.response)
        records.append(dict(records[-1], date="2024-12-31"))
        self.assertEqual(len(IMPORTER.rows_from_response(self.source, self.response)), 366)


if __name__ == "__main__":
    unittest.main()
