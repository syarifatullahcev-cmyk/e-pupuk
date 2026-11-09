import unittest

from sqlalchemy.engine import make_url

from seed_data import _is_demo_database, seed


class SeedDataSafetyTest(unittest.TestCase):
    def test_seed_requires_explicit_demo_confirmation(self):
        with self.assertRaisesRegex(RuntimeError, "disabled by default"):
            seed()

    def test_only_allows_named_demo_database_on_local_host(self):
        self.assertTrue(
            _is_demo_database(make_url("sqlite:///epupuk_demo.db"))
        )
        self.assertTrue(
            _is_demo_database(
                make_url("mysql+pymysql://user:pass@127.0.0.1/epupuk_demo")
            )
        )
        self.assertFalse(
            _is_demo_database(make_url("sqlite:///epupuk.db"))
        )
        self.assertFalse(
            _is_demo_database(
                make_url("mysql+pymysql://user:pass@example.com/epupuk_demo")
            )
        )


if __name__ == "__main__":
    unittest.main()
