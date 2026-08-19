<p align="center">

<img src="https://img.shields.io/badge/Flask-Python%20Web%20Framework-000000?style=for-the-badge&logo=flask&logoColor=white"/>
<img src="https://img.shields.io/badge/Python-3.10%2B-3776AB?style=for-the-badge&logo=python&logoColor=white"/>
<img src="https://img.shields.io/badge/Docker-Containerized-2496ED?style=for-the-badge&logo=docker&logoColor=white"/>
<img src="https://img.shields.io/badge/Kubernetes(k8S)-Container%20Orchestration-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white"/>


</p>

---

Project : [🏗️ Structure](./docs/notes/structure.md#top) ‎‎‎ | ‎‎‎ [🚀 Setup](./docs/notes/setup.md#top) ‎‎‎ | ‎‎‎ [🧪 Tests](./docs/notes/tests.md#tests) ‎‎‎ | ‎‎‎ [📚 Glossary](./docs/notes/glossary.md#top)

---

<h1 align="center">Python Flask k8s App</h1>


Building a python app `flask-k8s-app` using flask (a simple framework for building complex web applications)


---

## 🧭 App Routes

View all registered routes with:

```bash
flask --app app/app.py routes
```

| Endpoint        | Methods           | Rule                     |
|-----------------|-------------------|--------------------------|
| `favicon`       | `GET`             | `/favicon.ico`           |
| `health`        | `GET`             | `/health`                |
| `index`         | `GET`             | `/`                      |
| `index_redirect`| `GET`             | `/index`                 |
| `search`        | `GET`, `POST`     | `/search`                |
| `search_page`   | `GET`             | `/search-page`           |
| `static`        | `GET`             | `/static/<path:filename>`|

> 💡 The `/search` endpoint also supports a custom `QUERY` method for experimental use.

---
## 🧪 Testing Endpoints

### Manual cURL tests

#### POST `/search`

```bash
curl -X POST http://127.0.0.1:8080/search \
  -H "Content-Type: application/json" \
  -d '{"name":"python"}'
```

**Expected response:**
```json
{"method":"POST","query":{"name":"python"},"safe":false}
```

#### QUERY `/search`

```bash
curl -X QUERY http://127.0.0.1:8080/search \
  -H "Content-Type: application/json" \
  -d '{"name":"python"}'
```

**Expected response:**
```json
{"method":"QUERY","query":{"name":"python"},"safe":true}
```

### 📬 Postman Collection

Import the Postman collection to quickly test all endpoints with pre-configured requests and environments.

- **Collection:** [Flask k8s App – Postman Collection](./docs/postman/app-collection.json)

**How to use:**

1. Click the collection link above.
2. In Postman, click **Import**.
4. Run the requests or use the **Collection Runner** / **Newman** for automated tests.








