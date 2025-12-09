import requests
def test_health():
    r = requests.get("http://myservice.local/health", timeout=5)
    assert r.status_code == 200

