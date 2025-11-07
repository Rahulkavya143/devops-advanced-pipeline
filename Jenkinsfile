pipeline {
  agent any

  environment {
    HUB = "rahulr143"                // Your Docker Hub username
    DOCKERHUB_USER = credentials('dockerhub-user')
    DOCKERHUB_PASS = credentials('dockerhub-pass')
    APP_TAG = "v${env.BUILD_NUMBER}"
  }

  stages {
    stage('Checkout Code') {
      steps {
        checkout scm
      }
    }

    stage('Check for Changes') {
      steps {
        script {
          def changes = sh(returnStdout: true, script: "git diff --name-only HEAD~1 HEAD || true").trim()
          if (changes == "") {
            echo "✅ No changes detected. Skipping build & deploy."
            currentBuild.result = 'SUCCESS'
            env.SKIP_PIPELINE = "true"
          } else {
            echo "🔄 Changes detected, continuing build..."
            env.SKIP_PIPELINE = "false"
          }
        }
      }
    }

    stage('Build Docker Images (Parallel)') {
      when {
        expression { env.SKIP_PIPELINE != "true" }
      }
      parallel {
        stage('Backend Build') {
          steps {
            sh '''
              set -euxo pipefail
              echo "[INFO] Building Backend..."
              export DOCKER_BUILDKIT=1
              docker pull $HUB/backend:latest || true
              docker build --cache-from $HUB/backend:latest -t backend:local ./backend
            '''
          }
        }

        stage('Frontend Build') {
          steps {
            sh '''
              set -euxo pipefail
              echo "[INFO] Building Frontend..."
              export DOCKER_BUILDKIT=1
              docker pull $HUB/frontend:latest || true
              docker build --cache-from $HUB/frontend:latest -t frontend:local ./frontend
            '''
          }
        }
      }
    }

    stage('Push to Docker Hub (Parallel)') {
      when {
        expression { env.SKIP_PIPELINE != "true" }
      }
      parallel {
        stage('Push Backend') {
          steps {
            sh '''
              echo $DOCKERHUB_PASS | docker login -u $DOCKERHUB_USER --password-stdin
              docker tag backend:local $HUB/backend:$APP_TAG
              docker push $HUB/backend:$APP_TAG
              docker tag $HUB/backend:$APP_TAG $HUB/backend:latest
              docker push $HUB/backend:latest
            '''
          }
        }

        stage('Push Frontend') {
          steps {
            sh '''
              echo $DOCKERHUB_PASS | docker login -u $DOCKERHUB_USER --password-stdin
              docker tag frontend:local $HUB/frontend:$APP_TAG
              docker push $HUB/frontend:$APP_TAG
              docker tag $HUB/frontend:$APP_TAG $HUB/frontend:latest
              docker push $HUB/frontend:latest
            '''
          }
        }
      }
    }

    stage('Deploy GREEN Environment') {
      when {
        expression { env.SKIP_PIPELINE != "true" }
      }
      steps {
        sh '''
          echo "[DEPLOY] Starting GREEN environment..."
          cd deploy
          docker compose -f docker-compose.green.yml up -d --no-recreate
        '''
      }
    }

    stage('Health Check GREEN') {
      when {
        expression { env.SKIP_PIPELINE != "true" }
      }
      steps {
        sh '''
          echo "[CHECK] Checking health of GREEN..."
          sleep 5
          if ! curl -f http://localhost:5001; then
            echo "❌ GREEN failed health check!"
            exit 1
          fi
        '''
      }
    }

    stage('Switch Traffic to GREEN') {
      when {
        expression { env.SKIP_PIPELINE != "true" }
      }
      steps {
        sh '''
          echo "[SWITCH] Switching traffic to GREEN..."
          bash deploy/switch-blue-green.sh green
        '''
      }
    }

    stage('Stop BLUE (Cleanup)') {
      when {
        expression { env.SKIP_PIPELINE != "true" }
      }
      steps {
        sh '''
          echo "[CLEANUP] Stopping BLUE environment..."
          cd deploy
          docker compose -f docker-compose.blue.yml down || true
        '''
      }
    }
  }

  post {
    failure {
      script {
        echo "[ROLLBACK] Build failed — rolling back to BLUE..."
        node {
          sh '''
            bash deploy/switch-blue-green.sh blue
            cd deploy
            docker compose -f docker-compose.blue.yml up -d --no-recreate || true
          '''
        }
      }
    }
  }
}
