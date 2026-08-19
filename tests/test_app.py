import json


def test_index(client):
    """GET / should return 200 and JSON message."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.get_json()
    assert data == {"message": "Flask Kubernetes application is running"}


def test_index_redirect(client):
    """GET /index should redirect (302) to /."""
    response = client.get("/index", follow_redirects=False)
    assert response.status_code == 302
    assert response.location in ["/", "http://localhost/", "http://127.0.0.1/"]


def test_health(client):
    """GET /health should return 200 and status ok."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.get_json()
    assert data == {"status": "ok"}


def test_search_page(client):
    """GET /search-page should return 200 and HTML from search.html."""
    response = client.get("/search-page")
    assert response.status_code == 200
    assert response.content_type.startswith("text/html")
    assert b"search" in response.data.lower()


def test_search_get(client):
    """GET /search should return info about using POST/QUERY."""
    response = client.get("/search")
    assert response.status_code == 200
    data = response.get_json()
    assert data["method"] == "GET"
    assert data["safe"] is False
    assert "Use POST or QUERY with a JSON request body" in data["message"]


def test_search_post(client):
    """POST /search with JSON should return method and query data."""
    payload = {"query": "test query", "filters": {"type": "example"}}
    response = client.post(
        "/search",
        data=json.dumps(payload),
        content_type="application/json",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert data["method"] == "POST"
    assert data["safe"] is False
    assert data["query"] == payload


def test_search_query(client):
    """QUERY /search with JSON should return method and safe=True."""
    payload = {"query": "test query", "filters": {"type": "example"}}
    response = client.open(
        "/search",
        method="QUERY",
        data=json.dumps(payload),
        content_type="application/json",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert data["method"] == "QUERY"
    assert data["safe"] is True
    assert data["query"] == payload


def test_404_handler(client):
    """Request to non-existent path should trigger 404 handler."""
    response = client.get("/nonexistent-path-xyz")
    assert response.status_code == 404
    data = response.get_json()
    assert data["error"] == "Not Found"
    assert data["path"] == "/nonexistent-path-xyz"
    assert data["message"] == "The requested endpoint does not exist"


def test_favicon_route_if_enabled(client):
    """
    GET /favicon.ico.
    If the favicon route is uncommented in app/app.py, this should return 200.
    If it's still commented out, this will hit the 404 handler.
    """
    response = client.get("/favicon.ico")
    if response.status_code == 404:
        data = response.get_json()
        assert data["error"] == "Not Found"
        assert data["path"] == "/favicon.ico"
    else:
        assert response.status_code == 200
        assert "image" in response.content_type or "icon" in response.content_type