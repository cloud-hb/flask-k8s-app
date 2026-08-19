___
<a id="top"></a>
<!-- markdown lint-disable-line MD041 -->
**[🏠 Home TOC](./../../README.md#app-routes)**  ‎‎ | ‎‎ **[⬇️ ‎‎ Bottom](#end) ‎‎‎**
___

# Tests

This document describes how to run and write tests for the Flask application.

## Prerequisites

- Postman
- Python 3
- `pytest` and `pytest` plugins installed in your environment  
  ```bash
  pip install pytest
  ```

## Project layout

Expected structure:

```text
project/
  docs/postman                # App postman collection
  app/
    app.py                    # Flask application
  tests/
    conftest.py               # Shared fixtures (e.g., test client)
    test_app.py               # Application tests
    test_static_templates.py  # Static files & template-related tests
    requirements.txt          # # Python dependencies for the tests (pip install -r)
```

## 1.Integration test

- Launch the app: 
```bash
python3 pytest app/app.py
```
- Import the  [Flask K8s App Postman Collection](../postman/app-collection.json) into Postman

- Run the collection & check the result


## 2.Running tests

From the project root (where the `tests/` directory lives):

```bash
# Run all tests
python3 -m pytest

# Verbose output
python3 -m pytest -v

# Stop on first failure
python3 -m pytest -x

# Show print() output
python3 -m pytest -s

# Run tests matching a name pattern
python3 -m pytest -k "search"

```

## Configuration (optional)

Create `pytest.ini` in the project root:

```ini
# pytest.ini
[pytest]
testpaths = tests
python_files = test_*.py
python_functions = test_*
addopts = -v --tb=short
```

Or use `pyproject.toml`:

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_functions = ["test_*"]
addopts = "-v --tb=short"
```

## Fixtures

### Test client

Defined in `tests/conftest.py`:

```python
# tests/conftest.py
import pytest
from app.app import app


@pytest.fixture
def app_ctx():
    original_testing = app.config.get("TESTING")
    app.config["TESTING"] = True

    with app.app_context():
        yield app

    if original_testing is not None:
        app.config["TESTING"] = original_testing
    else:
        app.config.pop("TESTING", None)


@pytest.fixture
def client(app_ctx):
    with app_ctx.test_client() as client:
        yield client
```

Use `client` in your tests to make HTTP requests against the app:

```python
def test_index(client):
    resp = client.get("/")
    assert resp.status_code == 200
```

## Example tests

Example `tests/test_app.py` covering main endpoints:

```python
# tests/test_app.py
import json


def test_index(client):
    resp = client.get("/")
    assert resp.status_code == 200
    data = resp.get_json()
    assert data["message"] == "Flask Kubernetes application is running"


def test_health(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.get_json()["status"] == "ok"


def test_index_redirect(client):
    resp = client.get("/index", follow_redirects=False)
    assert resp.status_code == 302
    assert resp.location == "/"


def test_search_get(client):
    resp = client.get("/search")
    assert resp.status_code == 200
    data = resp.get_json()
    assert data["method"] == "GET"
    assert data["safe"] is False


def test_search_post(client):
    payload = {"q": "test", "limit": 10}
    resp = client.post(
        "/search",
        data=json.dumps(payload),
        content_type="application/json",
    )
    assert resp.status_code == 200
    data = resp.get_json()
    assert data["method"] == "POST"
    assert data["safe"] is False
    assert data["query"] == payload


def test_404(client):
    resp = client.get("/nonexistent")
    assert resp.status_code == 404
    data = resp.get_json()
    assert data["error"] == "Not Found"
    assert "path" in data
```

## Writing new tests

Guidelines:

- Place new test files in `tests/` with names like `test_*.py`.
- Name test functions `test_*`.
- Use the `client` fixture for HTTP tests.
- Keep tests focused on one behavior per function.
- Use assertions on:
  - `resp.status_code`
  - `resp.get_json()` (for JSON responses)
  - Headers, if relevant

Example template:

```python
def test_something(client):
    resp = client.get("/some-endpoint")
    assert resp.status_code == 200
    data = resp.get_json()
    assert "expected_key" in data
```

## CI/CD usage

In CI, run:

```bash
python3 -m pytest
```

Check the exit code:

- `0` → all tests passed
- non-zero → at least one test failed or an error occurred

This is sufficient for most CI systems to mark the job as passed/failed.

___
<a id="end"></a>
**[‎‎ 🏠 Home TOC](../../README.md#app-routes)**  ‎‎ | ‎‎ **[‎‎ Top ‎ ⬆️️](#top) ‎‎‎**
___
