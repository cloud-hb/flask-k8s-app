# tests/conftest.py
import pytest
from app.app import app


@pytest.fixture
def app_ctx():
    """
    Provide a Flask app context with TESTING=True.
    Restores original config after the test.
    """
    original_testing = app.config.get("TESTING")
    app.config["TESTING"] = True

    with app.app_context():
        yield app

    # Restore original config
    if original_testing is not None:
        app.config["TESTING"] = original_testing
    else:
        app.config.pop("TESTING", None)


@pytest.fixture
def client(app_ctx):
    """
    Create a test client for the Flask app.
    Uses the app_ctx fixture to ensure TESTING=True and proper context.
    """
    with app_ctx.test_client() as client:
        yield client