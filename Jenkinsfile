pipeline {
  agent any

  environment {
    HUB = "rahulr143"                       // Docker Hub username
    DOCKERHUB = credentials('dockerhub-user') // Jenkins credential ID
    APP_TAG = "v${env.BUILD_NUMBER}"        // unique tag per build
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
          set -euxo pipefail
          echo "[INFO] Logging into Docker Hub..."
          echo "$DOCKERHUB_PSW" | docker login -u "$DOCKERHUB_USR" --password-stdin

          echo "[INFO] Tagging and pushing images..."
          docker tag backend:local ${HUB}/backend:${APP_TAG}
          docker tag frontend:local ${HUB}/frontend:${APP_TAG}

          docker push ${HUB}/backend:${APP_TAG}
          docker push ${HUB}/frontend:${APP_TAG}

          docker tag ${HUB}/backend:${APP_TAG} ${HUB}/backend:latest
          docker tag ${HUB}/frontend:${APP_TAG} ${HUB}/frontend:latest

          docker push ${HUB}/backend:latest
          docker push ${HUB}/frontend:latest
        '''
      }
    }

    stage('Deploy GREEN Environment') {
      steps {
        sh '''
          set -euxo pipefail
          echo "[INFO] Deploying GREEN environment..."
          cd deploy
          docker compose -f docker-compose.green.yml down || true
          docker compose -f docker-compose.green.yml pull
          docker compose -f docker-compose.green.yml up -d
        '''
      }
    }

    stage('Health Check GREEN') {
      steps {
        sh '''
          set -euxo pipefail
          echo "[INFO] Performing health check on GREEN environment..."
          sleep 5
          curl -fsS http://localhost:8082 > /dev/null
          echo "[SUCCESS] GREEN environment is healthy."
        '''
      }
    }

    stage('Switch Traffic to GREEN') {
      steps {
        sh '''
          echo "[INFO] Switching traffic to GREEN..."
          bash deploy/switch-blue-green.sh green
        '''
      }
    }

    stage('Stop BLUE Environment') {
      steps {
        sh '''
          echo "[INFO] Stopping BLUE environment..."
          docker compose -f deploy/docker-compose.blue.yml down || true
        '''
      }
    }
  }

  post {
    failure {
      sh '''
        echo "[ROLLBACK] Build failed — rolling back to BLUE..."
        bash deploy/switch-blue-green.sh blue || true
        cd deploy
        docker compose -f docker-compose.blue.yml up -d || true
      '''
    }
  }
}
