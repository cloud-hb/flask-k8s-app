___
<a id="top"></a>
<!-- markdown lint-disable-line MD041 -->
**[⬅️ ‎‎ Home](../../README.md#app-routes)**  ‎‎ | ‎‎ **[⬇️ ‎‎ Bottom](#end) ‎‎‎**
___

## Project Structure

```text

.
├── .gitignore                   # Git ignore rules (files/folders to exclude from commits)
├── README.md                    # Project overview, setup, and usage documentation
├── Dockerfile                   # Instructions to build the Docker image for the app
├── docs/                        # Documentation site sources and assets (e.g., MkDocs/Sphinx)
│   
├── app/                         # Flask application code and dependencies
│   ├── app.py                   # Main Flask app entry point (routes, app init)
│   ├── requirements.txt         # Python dependencies for the Flask app (pip install -r)
│   ├── static/                  # Static assets (CSS, JS, images, favicon ...) served by Flask
│   └── templates/               # Jinja2 HTML templates rendered by Flask views
│   
├── deploy/                      # Kubernetes manifests for deploying the app
│   ├── deployment.yaml          # Kubernetes Deployment: pod spec, replicas, container config
│   └── service.yaml             # Kubernetes Service: exposes the Deployment inside/outside the cluster
│   
└── tests/                        # Automated tests and test configuration
    ├── __init__.py               # Marks tests as a Python package
    ├── __pycache__               # Cached Python bytecode generated at runtime
    ├── conftest.py               # Shared pytest fixtures and test configuration
    ├── requirements.txt           # Python dependencies required to run the tests
    ├── test_app.py                # Tests the application’s main functionality and routes
    └── test_static_templates.py   # Tests static files and template rendering
```

All Flask code lives under `app/`.

___

<a id="end"></a>
**[⬅️ ‎‎ Home](../../README.md#app-routes)**  ‎‎ | ‎‎ **[‎‎ Top ‎ ⬆️️](#top) ‎‎‎**

___

