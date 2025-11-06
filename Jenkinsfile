pipeline {
  agent any
  environment {
    HUB = "rahulr143"
    DOCKERHUB = credentials('dockerhub-user')
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
      
