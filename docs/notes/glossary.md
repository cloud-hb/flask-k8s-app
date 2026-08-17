___
<a id="top"></a>
<!-- markdown lint-disable-line MD041 -->
**[🏠 Home TOC](./../../README.md)**  ‎‎ | ‎‎ **[⬇️ ‎‎ Bottom](#end) ‎‎‎**
___

# Glossary

# Flask Kubernetes Application Glossary

This glossary explains the main files, tools, technologies, and terms used by
`flask-k8s-app`.

## Project

### flask-k8s-app

The name of this repository. It contains a Flask web application, a Docker
image definition, and Kubernetes manifests for deploying the application.

### Repository

A project directory managed by Git. It contains the application source code,
configuration files, deployment manifests, and Git history.

### `.git`

The hidden directory created by Git. It stores commits, branches, tags,
configuration, and repository metadata.

### `.gitignore`

A file that tells Git which untracked files and directories should not be
included in commits.

Typical ignored files include:

- Python bytecode.
- Virtual environments.
- Environment files containing secrets.
- Test and tool caches.
- Build artifacts.

Example:

```gitignore
__pycache__/
*.py[cod]
*.egg-info/
.venv/
venv/
env/

.env
.env.*

.pytest_cache/
.mypy_cache/
.coverage
htmlcov/

.DS_Store

*.log

build/
dist/

.vscode/
.idea/

*.swp
```

### Conventional Commit

A structured Git commit message format:

```text
<type>[optional scope]: <description>
```

Examples:

```text
feat(api): add health endpoint
build(docker): add production container image
feat(kubernetes): add application deployment
```

## Python and Flask

### Python

The programming language used to implement the application.

This project uses Python 3.14 through the Docker base image:

```dockerfile
FROM python:3.14.7-slim-trixie
```

### Flask

A Python web framework used to create the HTTP application and define routes.

Example:

```python
from flask import Flask

app = Flask(__name__)
```

### Flask application object

The Python object representing the Flask application.

In this project, it is named `app`:

```python
app = Flask(__name__)
```

Gunicorn uses this object through:

```text
app:app
```

The first `app` refers to `app.py`; the second `app` refers to the Flask
application object inside that file.

### Route

A URL pattern associated with a Python function.

Example:

```python
@app.get("/")
def index():
    return {"message": "Application is running"}
```

This defines a `GET /` route.

### Endpoint

A URL that a client can call. This project may expose endpoints such as:

```text
GET /
GET /health
```

### Health endpoint

A lightweight endpoint used to check whether the application is running.

Example:

```python
@app.get("/health")
def health():
    return {"status": "ok"}
```

Kubernetes uses this endpoint for readiness and liveness probes.

### WSGI

Web Server Gateway Interface. It is the standard interface between a Python
web application and a web server.

Flask creates a WSGI application object, and Gunicorn serves

___
<a id="end"></a>
**[‎‎ 🏠 Home TOC](../../README.md)**  ‎‎ | ‎‎ **[‎‎ Top ‎ ⬆️️](#top) ‎‎‎**
___
