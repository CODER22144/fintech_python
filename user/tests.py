from django.test import TestCase
from django.contrib.auth.hashers import make_password

class MyTest(TestCase):
    def test_simple_addition(self):
        self.assertEqual(2 + 2, 4)
        print(make_password('VtQcCv!@#345p1'))