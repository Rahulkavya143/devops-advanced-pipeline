pipeline {
  agent any

  environment {
    HUB = "rahulr143"
    DOCKERHUB_USER = credentials('dockerhub-user')
    DOCKERHUB_PASS = credentials('dockerhub-pass')
    APP_TAG = "v${env.BUILD_NUMBER}

    HUB = "rahulr143"                 // your Docker Hub username
    DOCKERHUB = credentials('dockerhub-user') // Jenkins credential ID (Username + Token)
    APP_TAG = "v${env.BUILD_NUMBER}"  // unique tag per build
  }

  options {
    timestamps()
    ansiColor('xterm')
 a5129ce (final: working Jenkinsfile with unified creds and rollback)
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
      when { expression { env.SKIP_PIPELINE != "true" } }
      parallel {
        stage('Backend Build') {
          steps {
            sh '''
              set -euxo pipefail
              echo "[INFO] Building Backend..."
              docker build --pull --cache-from $HUB/backend:latest -t backend:local ./backend
            '''
          }
        }

        stage('Frontend Build') {
          steps {
            sh '''
              set -euxo pipefail
              echo "[INFO] Building Frontend..."
              docker build --pull --cache-from $HUB/frontend:latest -t frontend:local ./frontend
            '''
          }
        }
      }
    }

    stage('Push to Docker Hub (Parallel)') {
      when { expression { env.SKIP_PIPELINE != "true" } }
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
      when { expression { env.SKIP_PIPELINE != "true" } }
      steps {
        sh '''
          echo "[DEPLOY] Starting GREEN environment..."

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
 a5129ce (final: working Jenkinsfile with unified creds and rollback)
          cd deploy
          docker compose -f docker-compose.green.yml up -d
        '''
      }
}

    stage('Health Check GREEN') {
      when { expression { env.SKIP_PIPELINE != "true" } }
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
      when { expression { env.SKIP_PIPELINE != "true" } }
      steps {
        sh '''
          cd deploy
          echo "[SWITCH] Switching traffic to GREEN..."
          bash switch-blue-green.sh green
        '''
      }
    }

    stage('Stop BLUE (Cleanup)') {
      when { expression { env.SKIP_PIPELINE != "true" } }
      steps {
        sh '''
          cd deploy
          echo "[CLEANUP] Stopping BLUE environment..."
          docker compose -f docker-compose.blue.yml down || true
        '''
      }
    }
  }

  post {
    failure {
      echo "[ROLLBACK] Build failed — rolling back to BLUE..."
      script {
        dir("deploy") {
          sh """
            echo '[ROLLBACK] Switching back to BLUE...'
            bash switch-blue-green.sh blue
            docker compose -f docker-compose.blue.yml up -d || true
          """
        }
      }
    }
  }
}
a5129ce (final: working Jenkinsfile with unified creds and rollback)
