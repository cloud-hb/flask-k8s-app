___
<a id="top"></a>
<!-- markdown lint-disable-line MD041 -->
**[⬅️ ‎‎ Home](../../README.md#app-routes)**  ‎‎ | ‎‎ **[⬇️ ‎‎ Bottom](#end) ‎‎‎**
___

## Troubleshooting

- **Import errors**:
  - Ensure you’re running Python from the project root so `app/` is on `sys.path`.
  - Confirm virtual environment is activated and dependencies are installed.
- **Port conflicts**:
  - If `8080` is in use, change the port:
    - Flask: `flask run --port 5000`
    - Gunicorn: `--bind 0.0.0.0:5000`
    - Docker: `-p 5000:8080` and adjust your browser URL.
- **Static files not loading**:
  - Ensure `static/` and `templates/` are under `app/` and referenced correctly in `app.py`.
  - Check that your Flask app is configured with the correct `static_folder` and `template_folder` if customized.


---


## 1. Common Problems

### Flask command is not found

Error:

```text
flask: command not found
```

or:

```text
'flask' is not recognized as an internal or external command
```

Fix:

```bash
python -m pip install Flask
python -m flask --app app run --debug
```

Using `python -m` helps ensure that Flask is installed in the same Python environment that runs the application.

### Import error

Error:

```text
ModuleNotFoundError: No module named 'flask'
```

Fix:

```bash
python -m pip install Flask
```

If the problem continues, verify the Python interpreter:

```bash
python --version
python -m pip --version
```

On systems with multiple Python installations, try:

```bash
python3 -m pip install Flask
python3 app.py
```

### Port 5000 is already in use

Run Flask on another port:

```bash
flask --app app run --debug --port 5001
```

Then visit:

```text
http://127.0.0.1:5001/
```

Alternatively, stop the process that is using port 5000.

### Template not found

Error:

```text
jinja2.exceptions.TemplateNotFound: index.html
```

Make sure the template is located here:

```text
templates/index.html
```

The directory must be named `templates` and must normally be beside `app.py`.

Use:

```python
return render_template("index.html")
```

Do not include the `templates` directory in the filename:

```python
# Correct
render_template("index.html")

# Usually incorrect
render_template("templates/index.html")
```

### Static files are not loading

Make sure static files are inside:

```text
static/
```

For example:

```text
static/css/style.css
static/js/app.js
static/images/logo.png
```

Reference them with `url_for`:

```html
<link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
<script src="{{ url_for('static', filename='js/app.js') }}"></script>
<img src="{{ url_for('static', filename='images/logo.png') }}" alt="Logo">
```

Avoid hard-coded paths such as:

```html
<link rel="stylesheet" href="/css/style.css">
```

unless the application is specifically configured to serve files from that location.

## 3. Favicon Detection Problem

A browser automatically requests a favicon from:

```text
/favicon.ico
```

If the Flask application does not provide that file, the development server may show a log entry such as:

```text
GET /favicon.ico HTTP/1.1" 404 -
```

This is usually not an application failure. It means the browser requested a tab icon and Flask could not find one.

### Recommended fix

Place the icon at:

```text
static/favicon.ico
```

Then explicitly reference it in the HTML `<head>`:

```html
<link rel="icon" type="image/x-icon"
      href="{{ url_for('static', filename='favicon.ico') }}">
```

The resulting structure should be:

```text
my_flask_app/
├── app.py
├── templates/
│   └── index.html
└── static/
    └── favicon.ico
```

Flask will serve the file at a URL similar to:

```text
/static/favicon.ico
```

You can test it directly by opening:

```text
http://127.0.0.1:5000/static/favicon.ico
```

### Optional explicit `/favicon.ico` route

If a browser or external tool specifically requires `/favicon.ico`, add this route:

```python
from flask import Flask, send_from_directory

app = Flask(__name__)


@app.route("/")
def index():
    return "Flask application is running"


@app.route("/favicon.ico")
def favicon():
    return send_from_directory(
        app.static_folder,
        "favicon.ico",
        mimetype="image/vnd.microsoft.icon",
    )


if __name__ == "__main__":
    app.run(debug=True)
```

A simpler alternative is to redirect the request to Flask’s static-file URL:

```python
from flask import Flask, redirect, url_for

app = Flask(__name__)


@app.route("/favicon.ico")
def favicon():
    return redirect(url_for("static", filename="favicon.ico"))
```

In most applications, explicitly adding the `<link rel="icon">` element and placing the file in `static/` is sufficient.

### Favicon still appears missing

Browsers cache favicons aggressively. Try one of the following:

- Perform a hard refresh.
- Open the page in a private browsing window.
- Clear the browser cache.
- Add a version query parameter temporarily:

```html
<link rel="icon"
      href="{{ url_for('static', filename='favicon.ico') }}?v=2">
```

Also check that:

- The filename is exactly `favicon.ico`.
- The file is a valid icon file, not merely a renamed PNG.
- The file is inside the correct `static` directory.
- The browser request is not returning a `404` or `500` response.
- The development server has been restarted if the project structure changed.

## 4. Debugging Checklist

When troubleshooting a Flask application, check the following:

1. Confirm that the virtual environment is activated.
2. Confirm that Flask is installed in that environment.
3. Check the terminal for Python tracebacks.
4. Verify the project directory structure.
5. Confirm that route URLs match the links used by the browser.
6. Use `url_for()` for static files and internal links.
7. Inspect the browser’s developer tools under the **Network** tab.
8. Check the HTTP status code for failed requests.
9. Restart Flask after changing Python code or project configuration.
10. Disable debug mode in production.

A useful route for checking whether the server is responding is:

```python
@app.route("/health")
def health():
    return {"status": "ok"}, 200
```

Test it at:

```text
http://127.0.0.1:5000/health
```

## 5. Production Warning

Do not use Flask’s development server as a production server. For deployment, use a production WSGI server such as Gunicorn or Waitress, configure environment variables, disable debug mode, and place the application behind a suitable web server or platform.

___

<a id="end"></a>
**[⬅️ ‎‎ Home](../../README.md#app-routes)**  ‎‎ | ‎‎ **[‎‎ Top ‎ ⬆️️](#top) ‎‎‎**

___

