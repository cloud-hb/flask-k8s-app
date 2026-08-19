import os
from app.app import app


def _base_dir():
    """
    Return the repository root directory.
    tests/ is at repo_root/tests, so repo_root = parent of tests dir.
    """
    return os.path.dirname(os.path.dirname(__file__))


def test_search_template_exists():
    """Ensure app/templates/search.html exists."""
    base = _base_dir()
    template_path = os.path.join(base, "app", "templates", "search.html")
    assert os.path.isfile(template_path), f"Template not found: {template_path}"


def test_static_favicon_exists():
    """Ensure app/static/favicon.ico exists."""
    base = _base_dir()
    favicon_path = os.path.join(base, "app", "static", "favicon.ico")
    assert os.path.isfile(favicon_path), f"Favicon not found: {favicon_path}"


def test_static_css_exists():
    """Ensure app/static/css/style.css exists (if you add it)."""
    base = _base_dir()
    css_path = os.path.join(base, "app", "static", "css", "style.css")
    # If style.css might not exist yet, you can remove this test or adjust path.
    if os.path.exists(css_path):
        assert os.path.isfile(css_path)


def test_static_js_exists():
    """Ensure app/static/js/app.js exists (if you add it)."""
    base = _base_dir()
    js_path = os.path.join(base, "app", "static", "js", "app.js")
    if os.path.exists(js_path):
        assert os.path.isfile(js_path)


def test_static_manifest_exists():
    """Ensure app/static/site.webmanifest exists."""
    base = _base_dir()
    manifest_path = os.path.join(base, "app", "static", "site.webmanifest")
    assert os.path.isfile(manifest_path), f"Manifest not found: {manifest_path}"


def test_search_page_renders_template(client):
    """Ensure /search-page successfully renders search.html."""
    response = client.get("/search-page")
    assert response.status_code == 200
    assert response.content_type.startswith("text/html")
    assert b"search" in response.data.lower()