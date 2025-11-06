pipeline {
  agent any
  environment {
    HUB = "rahulr143" // your Docker Hub username
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

    stage('Build Docker Images') {
      steps {
        sh '''
          docker build -t backend:local ./backend
          docker build -t frontend:local ./frontend
        '''
      }
    }

    stage('Push to Docker Hub') {
      steps {
        sh '''
          echo $DOCKERHUB_PASS | docker login -u $DOCKERHUB_USER --password-stdin
          docker tag backend:local $HUB/backend:$APP_TAG
          docker tag frontend:local $HUB/frontend:$APP_TAG
          docker push $HUB/backend:$APP_TAG
          docker push $HUB/frontend:$APP_TAG
          docker tag $HUB/backend:$APP_TAG $HUB/backend:latest
          docker tag $HUB/frontend:$APP_TAG $HUB/frontend:latest
          docker push $HUB/backend:latest
          docker push $HUB/frontend:latest
        '''
      }
    }

    stage('Deploy Green Environment') {
      steps {
        sh '''
          cd deploy
          docker compose -f docker-compose.green.yml down || true
          docker compose -f docker-compose.green.yml pull
          docker compose -f docker-compose.green.yml up -d
        '''
      }
    }

    stage('Health Check') {
      steps {
        sh 'sleep 5 && curl -fsS http://localhost:8082 > /dev/null'
      }
    }

    stage('Switch Traffic to Green') {
      steps {
        sh 'bash deploy/switch-blue-green.sh green'
      }
    }

    stage('Stop Blue Environment') {
      steps {
        sh 'docker compose -f deploy/docker-compose.blue.yml down || true'
      }
    }
  }

  post {
    failure {
      script {
        sh '''
          echo "❌ Build failed — rolling back to BLUE environment"
          bash deploy/switch-blue-green.sh blue || true
          cd deploy
          docker compose -f docker-compose.blue.yml up -d || true
        '''
      }
    }
  }
}
