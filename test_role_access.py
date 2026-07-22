import unittest
from app import app

class RoleAccessTestCase(unittest.TestCase):
    def setUp(self):
        app.config['TESTING'] = True
        app.config['WTF_CSRF_ENABLED'] = False
        self.client = app.test_client()

    def login(self, username, password='password123'):
        return self.client.post('/login', data={'username': username, 'password': password}, follow_redirects=True)

    def check_urls(self, username, expected_allowed, expected_denied):
        self.login(username)
        print(f"\n--- Testing User: {username} ---")
        for url in expected_allowed:
            response = self.client.get(url, follow_redirects=False)
            status = response.status_code
            if status != 200:
                print(f"  [FAIL] {url} returned status {status} (Expected 200)")
            else:
                print(f"  [PASS] {url} allowed (200)")
            self.assertEqual(status, 200, f"User {username} should have access to {url}")
            
        for url in expected_denied:
            response = self.client.get(url, follow_redirects=False)
            status = response.status_code
            # Expect 302 redirect back to dashboard or login
            if status != 302:
                print(f"  [FAIL] {url} returned status {status} (Expected 302 redirect)")
            else:
                print(f"  [PASS] {url} properly denied (302 redirect)")
            self.assertEqual(status, 302, f"User {username} should NOT have access to {url}")

    def test_admin(self):
        all_urls = ['/dashboard', '/patients', '/cases', '/examinations', '/investigations', '/autopsies', '/evidence', '/court_reports', '/reports', '/staff', '/audit']
        self.check_urls('admin', all_urls, [])

    def test_jmo(self):
        allowed = ['/dashboard', '/patients', '/cases', '/examinations', '/investigations', '/autopsies', '/evidence', '/court_reports', '/reports']
        denied = ['/staff', '/audit']
        self.check_urls('r_jayasinghe_jmo', allowed, denied)

    def test_medical_officer(self):
        allowed = ['/dashboard', '/patients', '/cases', '/examinations', '/investigations', '/evidence']
        denied = ['/autopsies', '/court_reports', '/reports', '/staff', '/audit']
        self.check_urls('n_perera_mo', allowed, denied)

    def test_lab_staff(self):
        allowed = ['/dashboard', '/investigations', '/evidence']
        denied = ['/patients', '/cases', '/examinations', '/autopsies', '/court_reports', '/reports', '/staff', '/audit']
        self.check_urls('k_fernando_lab', allowed, denied)

    def test_clerk(self):
        allowed = ['/dashboard', '/patients', '/cases', '/court_reports', '/reports']
        denied = ['/examinations', '/investigations', '/autopsies', '/evidence', '/staff', '/audit']
        self.check_urls('j_doe_clerk', allowed, denied)

if __name__ == '__main__':
    unittest.main()
