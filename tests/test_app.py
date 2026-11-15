from app.main import app


def test_homepage():
    client = app.test_client()
    response = client.get('/')
    assert response.status_code == 200
    assert b'Cloud Deployment Lab' in response.data


def test_health():
    response = app.test_client().get('/health')
    assert response.status_code == 200
    assert response.get_json() == {'status': 'healthy'}


def test_info():
    data = app.test_client().get('/api/info').get_json()
    assert data['name'] == 'cloud-deployment-lab'
    assert data['version']
