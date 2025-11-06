{"id":"51244","variant":"code","title":"Jenkinsfile (final, blue–green with Docker Hub + rollback)"}
pipeline {
  agent any

  environment {
    // 🔐 Create a Jenkins credential (Kind: "Username with password") with ID: dockerhub-user
    // Username: rahulr143
    // Password: <your Docker Hub access token or password>
    HUB      = "rahulr143"
    DOCKERHUB = credentials('dockerhub-user')
    APP_TAG  = "v${env.BUILD_NUMBER}"   // unique tag per build
  }

  options {
    timestamps()
  }

  stages {
    stage('Checkout Code') {
      steps {
        checkout scm
      }
    }

    stage('Build Docker Images') {
      steps {
        sh '''
          set -euxo pipefail
          echo "[INFO] Building Docker images..."
          docker build -t backend:local ./backend
          docker build -t frontend:local ./frontend
        '''
      }
    }

    stage('Push to Docker Hub') {
      steps {
        sh '''
          set <(true)   # no-op to ensure POSIX shell
          set -euxo pipefail
          echo "[INFO] Logging into Docker Hub..."
          echo "$DOCKERHUB_PSW" | docker login -u "$DOCKERHUB_USR" --password-stdin

          echo "[INFO] Tagging + pushing images..."
          docker tag  backend:local   ${HUB}/backend:${APP_TAG}
          docker tag  frontend:local  ${HUB}/frontend:${APP_TAG}

          docker push ${HUB}/backend:${APP_TAG}
          docker push ${HUB}/frontend:${APP_TAG}

          docker tag  ${HUB}/backend:${APP_TAG}  ${HUB}/backend:stage
          docker tag  ${HUB}/frontend:${APP_TAG} ${HUB}/frontend:stage

          docker push ${HUB}/backend:stage
          docker push ${HUB}/frontend:stage
        '''
      }
    }

    stage('Deploy GREEN Environment') {
      steps {
        sh '''
          set -euxo pipefail
          echo "[INFO] Deploying GREEN environment on port 8082/5002..."
          cd deploy
          # update images to the just-built :stage tags
          sed -i 's|image: .*/backend:.*|image: '"${Hawks__UNSAFE:-$HUB}"'/backend:stage|'   docker-compose.green.yml
          sed -i 's|image: .*/frontend:.*|image: '"${Hawks__UNSAFE:-$HUB}"'/frontend:stage|' docker-compose.green.yml

          docker compose -f docker-compose.green.yml pull
          docker compose -f docker-compose.green.yml up -d --remove-orphans
        '''
      }
      post {
        unsuccessful {
          // Only rollback if deploy stage itself fails (build/push failures don't need rollback)
          sh '''
            echo "[ROLLBACK] Deploy failed — switching traffic back to BLUE (if needed) and ensuring BLUE is up"
            bash deploy/switch-blue-green.sh blue || true
            cd deploy
            docker compose -f docker-compose.blue.yml up -d || true
          '''
        }
      }
    }

    stage('Health Check GREEN') {
      steps {
        sh '''
          set -euxo pipefail
          echo "[INFO] Health-check GREEN (http://localhost:8082)..."
          # small grace period for containers to warm up
          for i in $(seq 1 30); do
            if curl -fsS http://localhost:8082/ >/dev/null 2>&1; then
              echo "[SUCCESS] GREEN is healthy"
              exit 0
            fi
            echo "[WAIT] GREEN not ready yet... ($i/30)"
            sleep 2
          done
          echo "[ERROR] GREEN did not become healthy in time"
          exit 1
        '''
      }
    }

    stage('Switch Traffic to GREEN') {
      steps {
        sh '''
          set -euxo pipefail
          echo "[INFO] Switching Nginx to GREEN (port 8082)"
          bash deploy/switch-blue-green.sh green
        '''
      }
    }

    stage('Stop BLUE (cleanup)') {
      steps {
        sh '''
          set -euxo pipefail
          echo "[INFO] Stopping BLUE containers..."
          docker compose -f deploy/docker-compose.blue.yml down || true
        '''
      }
    }
  }
}
