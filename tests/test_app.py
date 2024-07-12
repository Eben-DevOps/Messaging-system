import pytest
from app import app

@pytest.fixture
def client():
    with app.test_client() as client:
        yield client

def test_sendmail(client):
    response = client.get('/?sendmail=test@example.com')
    assert b'Email to test@example.com is queued.' in response.data

def test_talktome(client):
    response = client.get('/?talktome=1')
    assert b'Current time' in response.data

def test_invalid_parameter(client):
    response = client.get('/')
    assert b'Please provide a valid parameter.' in response.data

def test_get_logs(client):
    response = client.get('/logs')
    assert response.status_code == 200
