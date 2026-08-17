___
<a id="top"></a>
<!-- markdown lint-disable-line MD041 -->
**[🏠 Home TOC](./../../README.md#app-routes)**  ‎‎ | ‎‎ **[⬇️ ‎‎ Bottom](#end) ‎‎‎**

___

# flask-k8s-app – Setup Guide

This guide shows how to build, run, and deploy the `flask-k8s-app` Flask application in three modes:

1. Local development with Docker only  
2. On a local Kubernetes cluster (Minikube or kind)  
3. Accessing the app via `kubectl port-forward` instead of a LoadBalancer  

Repo layout:

```text
.
├── .gitignore
├── README.md
├── Dockerfile
├── docs/
├── app/
│   ├── app.py
│   ├── requirements.txt
│   ├── static/
│   └── templates/
└── deploy/
    ├── deployment.yaml
    └── service.yaml
```

The Kubernetes manifests are:

- `deploy/deployment.yaml`:
  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: flask-app
  spec:
    replicas: 2
    selector:
      matchLabels:
        app: flask-app
    template:
      metadata:
        labels:
          app: flask-app
      spec:
        containers:
          - name: flask-app
            image: username/flask-k8s-app:latest
            imagePullPolicy: IfNotPresent
            ports:
              - containerPort: 8080
  ```

- `deploy/service.yaml`:
  ```yaml
  apiVersion: v1
  kind: Service
  metadata:
    name: flask-service
  spec:
    selector:
      app: flask-app
    ports:
      - protocol: TCP
        port: 80
        targetPort: 8080
    type: LoadBalancer  # can be used with or without LoadBalancer support
  ```

Adjust `username/flask-k8s-app:latest` to your actual image name/tag.

---

## Prerequisites

Install:

- [Docker](https://docs.docker.com/get-docker/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- One of:
  - [Minikube](https://minikube.sigs.k8s.io/docs/start/)
  - [kind](https://kind.sigs.k8s.io/)

Verify:

```bash
docker --version
kubectl version --client
```

---

## 1. Local Development (Docker Only)

Use this when you just want to test the Flask app without Kubernetes.

### Build the image

From the project root (where `Dockerfile` is):

```bash
docker build -t username/flask-k8s-app:latest .
```

### Run the container

```bash
docker run --rm -p 8080:8080 username/flask-k8s-app:latest
```

Then open:

- `http://localhost:8080`

No Kubernetes is involved here.

---

## 2. Deploy to a Local Kubernetes Cluster

### 2.1 Start a Cluster

#### Minikube

```bash
minikube start
kubectl cluster-info
```

Optional: use Minikube’s Docker daemon so images are immediately visible:

```bash
eval $(minikube docker-env)
# Now `docker build` images are directly visible to Minikube
docker build -t username/flask-k8s-app:latest .
```

If you don’t use `minikube docker-env`, load the image instead:

```bash
minikube image load username/flask-k8s-app:latest
```

#### kind

Create a cluster (if you don’t have one):

```bash
kind create cluster --name flask-kind
kubectl cluster-info
```

Load the image into kind:

```bash
kind load docker-image username/flask-k8s-app:latest --name flask-kind
```

---

### 2.2 Apply Kubernetes Manifests

From the project root:

```bash
kubectl apply -f deploy/
```

This applies both:

- `deploy/deployment.yaml`
- `deploy/service.yaml`

Check resources:

```bash
kubectl get deployments
kubectl get pods
kubectl get services
```

You should see:

- Deployment `flask-app` with 2 replicas
- Service `flask-service`

---

## 3. Accessing the App

You can access the app either via a LoadBalancer (if supported) or via `kubectl port-forward`. For local dev, port-forward is usually simplest.

### 3.1 Using a LoadBalancer (when supported)

If your environment supports `LoadBalancer` (cloud providers, or local setups with metallb / Minikube tunnel):

#### Minikube with tunnel

```bash
minikube tunnel
```

In another terminal:

```bash
kubectl get service flask-service
```

Use the `EXTERNAL-IP` shown (often `127.0.0.1` when tunneling) and open:

- `http://<EXTERNAL-IP>` (port 80)

#### kind or other clusters with a LoadBalancer controller

Same idea:

```bash
kubectl get service flask-service
```

Then access `http://<EXTERNAL-IP>`.

---

### 3.2 Using `kubectl port-forward` (no LoadBalancer needed)

If you **do not** have a LoadBalancer (common with plain kind or minimal clusters), you can ignore the LoadBalancer status and just use port-forwarding.

You can keep `type: LoadBalancer` in the Service; it just won’t get an external IP. You’ll access the app via `kubectl port-forward` instead.

#### Port-forward the Service

```bash
kubectl port-forward service/flask-service 8080:80
```

This forwards:

- Local port `8080` → Service port `80` → Pod port `8080`

Then open:

- `http://localhost:8080`

You do **not** need to change your Service type for this to work.

#### Port-forward a Pod directly (alternative)

If you prefer, you can forward a specific pod:

```bash
kubectl get pods -l app=flask-app
kubectl port-forward pod/<pod-name> 8080:8080
```

Then open:

- `http://localhost:8080`

---

### 3.3 Changing the Service Type (optional)

If you want to be explicit that you’re not relying on a LoadBalancer, you can edit `deploy/service.yaml`:

```yaml
type: ClusterIP
```

Then re-apply:

```bash
kubectl apply -f deploy/service.yaml
```

Access remains the same via port-forward:

```bash
kubectl port-forward service/flask-service 8080:80
```

`ClusterIP` is often preferable for local dev when you always use port-forwarding.

---

## 4. Updating the Application

### Rebuild and reload image

From the project root:

```bash
docker build -t username/flask-k8s-app:latest .
```

Then, depending on your cluster:

- **Minikube (with `minikube docker-env`)**: image is already visible; just restart pods:

  ```bash
  kubectl rollout restart deployment/flask-app
  ```

- **kind**:

  ```bash
  kind load docker-image username/flask-k8s-app:latest --name flask-kind
  kubectl rollout restart deployment/flask-app
  ```

- **Remote cluster**: push to registry, then:

  ```bash
  kubectl rollout restart deployment/flask-app
  ```

Check rollout status:

```bash
kubectl rollout status deployment/flask-app
```

---

## 5. Troubleshooting

- Check pods:

  ```bash
  kubectl get pods -l app=flask-app
  kubectl describe pod -l app=flask-app
  kubectl logs -l app=flask-app
  ```

- If pods are `ImagePullBackOff`:
  - Ensure the image name/tag is correct
  - Ensure the image is loaded/pushed where the cluster can see it
- If port-forward fails:
  - Confirm the Service exists: `kubectl get service flask-service`
  - Confirm labels match: `kubectl get pods -l app=flask-app`

---

## 6. Quick Reference

**Local Docker only:**

```bash
docker build -t username/flask-k8s-app:latest .
docker run --rm -p 8080:8080 username/flask-k8s-app:latest
# http://localhost:8080
```

**Minikube:**

```bash
minikube start
eval $(minikube docker-env)   # optional
docker build -t username/flask-k8s-app:latest .
kubectl apply -f deploy/
kubectl port-forward service/flask-service 8080:80
# http://localhost:8080
```

**kind:**

```bash
kind create cluster --name flask-kind
docker build -t username/flask-k8s-app:latest .
kind load docker-image username/flask-k8s-app:latest --name flask-kind
kubectl apply -f deploy/
kubectl port-forward service/flask-service 8080:80
# http://localhost:8080
```

This setup works whether or not your environment supports a LoadBalancer; for local dev, port-forwarding is usually the simplest and most reliable option.

___
<a id="end"></a>
**[‎‎ 🏠 Home TOC](../../README.md#app-routes)**  ‎‎ | ‎‎ **[‎‎ Top ‎ ⬆️️](#top) ‎‎‎**
___
