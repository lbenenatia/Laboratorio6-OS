"""
Tests automáticos para Dummy B Flask API
Ejecutar con: pytest test_app.py -v
"""

import pytest
import json
from app import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


class TestRootEndpoint:
    def test_root_returns_200(self, client):
        response = client.get("/")
        assert response.status_code == 200

    def test_root_returns_json(self, client):
        response = client.get("/")
        data = json.loads(response.data)
        assert "app" in data
        assert "status" in data

    def test_root_status_is_running(self, client):
        response = client.get("/")
        data = json.loads(response.data)
        assert data["status"] == "running"


class TestHealthEndpoint:
    def test_health_returns_200(self, client):
        response = client.get("/health")
        assert response.status_code == 200

    def test_health_returns_json(self, client):
        response = client.get("/health")
        data = json.loads(response.data)
        assert "status" in data
        assert "timestamp" in data

    def test_health_status_is_ok(self, client):
        response = client.get("/health")
        data = json.loads(response.data)
        assert data["status"] == "ok"

    def test_health_service_name(self, client):
        response = client.get("/health")
        data = json.loads(response.data)
        assert data["service"] == "dummy-b"


class TestInfoEndpoint:
    def test_info_returns_200(self, client):
        response = client.get("/info")
        assert response.status_code == 200

    def test_info_returns_hostname(self, client):
        response = client.get("/info")
        data = json.loads(response.data)
        assert "hostname" in data
