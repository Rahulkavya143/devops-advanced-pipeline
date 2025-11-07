# 🚀 DevOps Advanced CI/CD Pipeline (Blue–Green Deployment)

This project demonstrates a **complete CI/CD pipeline** built with **Jenkins, Docker, Docker Hub, Prometheus, and Grafana** — automating build, test, and deployment using the **Blue–Green deployment strategy**.

---

## 🧩 Technologies Used

* **Jenkins** – CI/CD automation server
* **Docker** – Containerization of frontend & backend apps
* **Docker Hub** – Image repository for storing Docker images
* **Prometheus** – Metrics & monitoring system
* **Grafana** – Visualization dashboard for performance monitoring
* **Node Exporter** – System-level metrics exporter

---

## ⚙️ Pipeline Workflow (Step-by-Step)

### 1. **Code Checkout**

Jenkins pulls the latest source code from **GitHub** (`main` branch).
This ensures Jenkins always works on the newest code.

### 2. **Change Detection**

Jenkins checks whether any files were updated since the last commit.
If no changes are found → pipeline stops early to **save time** ⏱️.

### 3. **Docker Image Build (Parallel)**

* Backend and frontend are **built simultaneously** using Docker.
* Build cache and `DOCKER_BUILDKIT` are enabled for **faster builds**.
* Images are tagged as `backend:local` and `frontend:local`.

### 4. **Push to Docker Hub (Parallel)**

* Jenkins logs in to Docker Hub using stored credentials.
* Pushes versioned images (`v1`, `v2`, etc.) and also updates the `latest` tag.
* Example tags:

  ```
  rahulr143/backend:v3
  rahulr143/frontend:v3
  rahulr143/backend:latest
  rahulr143/frontend:latest
  ```

### 5. **Deploy to GREEN Environment**

* Jenkins deploys new containers (`docker-compose.green.yml`)
* GREEN runs in parallel while BLUE stays live (no downtime).
* Ensures **zero-downtime deployment**.

### 6. **Health Check GREEN**

* Jenkins verifies the GREEN deployment using `curl`.
* If the app is reachable → proceed to next stage.
* If not → pipeline **fails safely** and triggers a rollback.

### 7. **Switch Traffic to GREEN**

* Once GREEN passes health checks, traffic is switched from BLUE → GREEN.
* The new version now becomes live.

### 8. **Stop BLUE (Cleanup)**

* The old BLUE environment is stopped and cleaned up.
* Only the latest GREEN version stays running.

### 9. **Rollback (Automatic Recovery)**

If any stage fails, Jenkins:

* Runs `deploy/switch-blue-green.sh blue`
* Brings back the previous stable BLUE version
* Ensures **instant rollback** with no downtime.

---

## 📊 Monitoring Setup (Prometheus + Grafana)

1. **Prometheus** scrapes metrics from:

   * Jenkins
   * Node Exporter (system metrics)

2. **Grafana** visualizes Prometheus metrics.

   * URL: `http://<EC2-IP>:3000`
   * Default login: `admin / admin`
   * Dashboards: CPU, memory, container health, etc.

---

## 🧠 How to Explain in Interviews

You can say:

> “I implemented a Jenkins pipeline that automates Docker builds, pushes images to Docker Hub, and deploys using a Blue–Green strategy.
> The pipeline checks for changes, builds backend and frontend in parallel for speed, performs a health check on the new version (GREEN), and switches traffic only after it passes.
> If any stage fails, Jenkins automatically rolls back to the previous BLUE environment.
> For monitoring, I integrated Prometheus and Grafana to visualize server and container health.”

---

## ⚡ Highlights

* Parallel Docker build & push for faster CI/CD
* Fully automated Blue–Green deployment
* Auto rollback for safety
* Integrated monitoring via Prometheus + Grafana
* Secure DockerHub authentication with Jenkins credentials

---

## 🏁 Result

✅ Continuous Integration
✅ Continuous Deployment
✅ Zero Downtime Rollout
✅ Real-time Monitoring

---

**Author:** Rahul R
**GitHub:** [@Rahulkavya143](https://github.com/Rahulkavya143)
