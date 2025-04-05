pipeline {
  agent any

  environment {
    IMAGE_NAME = 'hello-node-app'
    DOCKER_REGISTRY = 'ankitofficial1821'
  }

  stages {
    stage('Checkout') {
      steps {
        git 'https://github.com/Ankitdevops18/nodejs-sample.git' // change to your repo
      }
    }

    stage('Install') {
      steps {
        sh 'npm install'
      }
    }

    stage('Test') {
      steps {
        // No test cases here, just a placeholder
        echo 'No tests defined.'
      }
    }

    stage('Build Docker Image') {
      steps {
        sh 'sudo docker build -t $DOCKER_REGISTRY/$IMAGE_NAME:latest .'
      }
    }

    stage('Push to Docker Hub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
          sh 'echo $PASSWORD | docker login -u $USERNAME --password-stdin'
          sh 'docker push $DOCKER_REGISTRY/$IMAGE_NAME:latest'
        }
      }
    }

    stage('Deploy') {
      steps {
        echo 'Deploy stage can use kubectl or helm to deploy to EKS/Kubernetes'
      }
    }
  }
}
