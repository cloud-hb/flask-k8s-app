___
<a id="top"></a>
<!-- markdown lint-disable-line MD041 -->
**[🏠 Home TOC](./../../README.md#app-routes)**  ‎‎ | ‎‎ **[⬇️ ‎‎ Bottom](#end) ‎‎‎**
___

# Setup

This guide covers how to set up and run the Flask application `flask-k8s-app` locally, using only Python and Docker. 


All Flask code lives under `app/`.

---

## Prerequisites

You need:

- Python 3.9+ (or the version specified in your Dockerfile)
- `pip` (usually bundled with Python)
- (Optional but recommended) a virtual environment tool: `venv`, `virtualenv`, or `conda`
- Docker (if you want to build/run the image)

Verify:

```bash
python --version
pip --version
docker --version  # optional, for containerized runs
```

---

## 1. Local Python Environment Setup

### 1.1 Create a Virtual Environment (recommended)

From the project root:

```bash
python3 -m venv .venv
```

Activate it:

- **Linux/macOS**:

  ```bash
  source .venv/bin/activate
  ```

- **Windows (PowerShell)**:

  ```powershell
  .venv\Scripts\Activate.ps1
  ```

- **Windows (CMD)**:

  ```cmd
  .venv\Scripts\activate.bat
  ```

You should see `(.venv)` in your shell prompt.

### 1.2 Install Dependencies

From the project root (with the virtual environment activated):

```bash
pip install -r app/requirements.txt
```

This installs all Python packages required by the Flask app (e.g., `flask`, `gunicorn`, etc., as defined in `app/requirements.txt`).

---

## 2. Running the Flask App Locally

The main application entry point is `app/app.py`.

### 2.1 Using Flask’s Development Server

From the project root:

```bash
export FLASK_APP=app/app.py
export FLASK_ENV=development  # optional, enables debug mode in many setups
flask run --port 8080
```

Or, if your `app.py` creates an app object and includes a `if __name__ == "__main__":` block, you can run:

```bash
python3 app/app.py
```

(Ensure the code inside `app.py` listens on port `8080` or adjust the port accordingly.)

Then open:

- `http://localhost:8080`

In development mode, you typically get:

- Auto-reload on code changes
- Interactive debugger (if enabled)

### 2.2 Using Gunicorn (optional, closer to production)

If `gunicorn` is listed in `app/requirements.txt`, you can run:

```bash
gunicorn "app.app:app" --bind 0.0.0.0:8080 --workers 2
```

Notes:

- `"app.app:app"` assumes:
  - The package directory is `app/`
  - Inside `app/app.py` there is `app = Flask(__name__)`
- Adjust the module path if your structure or variable name differs.

Then open:

- `http://localhost:8080`

---

## 3. Docker-Based Local Development

Use this if you want to run the app in an environment identical to your deployment image, but still without Kubernetes.

### 3.1 Build the Docker Image

From the project root (where `Dockerfile` is):

```bash
docker build -t username/flask-k8s-app:latest .
```

Replace `username` with your Docker Hub (or other registry) username, or use a local-only tag like `flask-k8s-app:latest`.

### 3.2 Run the Container

```bash
docker run --rm -p 8080:8080 username/flask-k8s-app:latest
```

Then open:

- `http://localhost:8080`

This uses whatever command is defined in the `Dockerfile` (often `gunicorn` or `flask run`).

If you need to override the command (e.g., for debug):

```bash
docker run --rm -p 8080:8080 --entrypoint python username/flask-k8s-app:latest app/app.py
```

Adjust the entrypoint/command according to your Dockerfile and how `app.py` is structured.

---

## 4. Inspecting the Image Filesystem (Optional)

If you want to see what’s inside the built image (e.g., to verify files, dependencies, or static assets), you can use the helper script:

```bash
chmod +x scripts/linux-macos/check_docker_image_data.sh
./scripts/linux-macos/check_docker_image_data.sh username/flask-k8s-app:latest
```

This will:

- Create a temporary container from the image
- Export its filesystem to `image-fs.tar`
- Extract it into `image-fs/` for browsing

The temporary container is cleaned up automatically.

---

## 5. Common Development Tasks

### 5.1 Adding New Dependencies

1. With your virtual environment activated:

   ```bash
   pip install <package-name>
   ```

2. Update `app/requirements.txt`:

   ```bash
   pip freeze > app/requirements.txt
   ```

   (Or manually edit to keep only the packages you actually need.)

3. Rebuild the Docker image if you use it:

   ```bash
   docker build -t username/flask-k8s-app:latest .
   ```

### 5.2 Running Tests (if you add them later)

If you add a `tests/` directory and use `pytest`:

```bash
pip install pytest
pytest
```

Run from the project root, ensuring your virtual environment is active and `app/` is importable.

___
<a id="end"></a>
**[‎‎ 🏠 Home TOC](../../README.md#app-routes)**  ‎‎ | ‎‎ **[‎‎ Top ‎ ⬆️️](#top) ‎‎‎**
___
