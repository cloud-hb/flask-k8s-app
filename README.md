<p align="center">

<img src="https://img.shields.io/badge/ArgoCD-FB8C00?style=for-the-badge&logo=argo&logoColor=white"/>
<img src="https://img.shields.io/badge/GitOps-Declarative%20%7C%20Versioned%20%7C%20Automated-2496ED?style=for-the-badge&logo=git&logoColor=white"/><img src="https://img.shields.io/badge/Kubernetes-Container%20Orchestration-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white"/><img src="https://img.shields.io/badge/Minikube%20OR%20Kind-Local%20K8s%20Clusters-3A76D8?style=for-the-badge&logo=docker&logoColor=white" alt="Minikube OR Kind Local K8s Clusters"/>

</p>

---

Project : [Structure](./docs/notes/structure.md#top) ‎‎‎ | ‎‎‎ [Setup](./docs/notes/setup.md#top) ‎‎‎ | ‎‎‎ [Glossary](./docs/notes/glossary.md#top)

---

<h1 align="center">Python Flask Kubernetes(k8s) App</h1>


Building a python app `flask-k8s-app` using flask (a simple framework for building complex web applications)

# App routes

```bash
# 1. cmd to get the app routes details
## flask --app app/app.py routes

# 2. Result
Endpoint        Methods           Rule                   
--------------  ----------------  -----------------------
favicon         GET               /favicon.ico           
health          GET               /health                
index           GET               /                      
index_redirect  GET               /index                 
search          GET, POST, QUERY  /search                
search_page     GET               /search-page           
static          GET               /static/<path:filename>
```

# Browser

```text
http://127.0.0.1:8080/search-page
```

# Tests
```bash
# POST
curl -X POST http://127.0.0.1:8080/search \
  -H "Content-Type: application/json" \
  -d '{"name":"python"}'
## Expected : {"method":"POST","query":{"name":"python"},"safe":false}

# QUERY
curl -X QUERY http://127.0.0.1:8080/search \
  -H "Content-Type: application/json" \
  -d '{"name":"python"}'
## Expected : {"method":"QUERY","query":{"name":"python"},"safe":true}
```
---
