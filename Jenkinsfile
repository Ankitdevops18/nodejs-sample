pipeline {
  agent any

  tools {
    nodejs 'default'
  }

  environment {
    IMAGE_NAME = 'hello-node-app'
    DOCKER_REGISTRY = 'ankitofficial1821'
    IMAGE_TAG = 'latest'
    IMAGE_FULL_NAME = "docker.io/${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
    KUBECONFIG = "/var/jenkins_home/.kube/config"
  }

  stages {

    stage('Test Tools') {
      steps {
        sh 'kubectl version --client'
        sh 'node --version'
        sh 'git --version'
        sh 'npm --version'
        sh 'nerdctl --version'
      }
    }

    stage('Create Namespace & Jenkins-Role') {
      steps {
        sh """
        if ! kubectl get ns nodejs-app > /dev/null 2>&1; then
          kubectl apply -f k8s/namespace.yaml      
        else
          echo "Namespace 'nodejs-app' already exists, skipping"
        fi
        """
      }
    }

    stage('Checkout') {
      steps {
        git 'https://github.com/Ankitdevops18/nodejs-sample.git'
      }
    }

    stage('Install') {
      steps {
        sh 'npm install'
      }
    }

    stage('Login to DockerHub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
          sh 'echo "$DOCKER_PASSWORD" | nerdctl login -u "$DOCKER_USERNAME" --password-stdin'
        }
      }
    }

    stage('Build & Push Image (nerdctl)') {
      steps {
        sh """
        nerdctl build -t ${IMAGE_FULL_NAME} .
        nerdctl push ${IMAGE_FULL_NAME}
        nerdctl image rm ${IMAGE_FULL_NAME}
        """
      }
    }

 
    stage('Detect Deployment Color') {
      steps {
        script {
          def serviceExists = sh(
            script: "kubectl get svc nodejs-service -n default > /dev/null 2>&1 && echo true || echo false",
            returnStdout: true
          ).trim()

          if (serviceExists == "true") {
            echo "Service exists. Proceeding with blue-green logic."
            env.currentColor = sh(
              script: "kubectl get svc nodejs-service -n default -o jsonpath='{.spec.selector.version}'",
              returnStdout: true
            ).trim()

            echo "Currently live color is: ${env.currentColor}"

            if (env.currentColor == "blue") {
              env.TARGET_COLOR = "green"
            } else if (env.currentColor == "green") {
              env.TARGET_COLOR = "blue"
            } else {
              error("Unknown color deployed: ${env.currentColor}")
            }

            env.SWITCH_TRAFFIC = "true"
          } else {
            echo "Service does not exist. Deploying fresh as blue."
            env.TARGET_COLOR = "blue"
            env.SWITCH_TRAFFIC = "false"
          }

          echo "Target deployment color: ${env.TARGET_COLOR}"
        }
      }
    }


    stage('Deploy to Target Color') {
      steps {
        echo "Deploying to ${env.TARGET_COLOR} environment..."

        sh """
        kubectl apply -f k8s/${env.TARGET_COLOR}-deploy.yaml
        kubectl apply -f k8s/service-${env.TARGET_COLOR}.yaml
        kubectl get svc nodejs-${env.TARGET_COLOR}-service -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
        """
      }
    }

    stage('Switch Traffic & Cleanup') {
      when {
        expression { return SWITCH_TRAFFIC }
      }
      steps {
        sh """
        sed 's/VERSION_PLACEHOLDER/${TARGET_COLOR}/g' k8s/switch-traffic.yaml.template > k8s/switch-traffic.yaml
        git add --all
        git commit -m "Switching traffic to ${TARGET_COLOR} environment"
        git push -u origin master
        kubectl apply -f k8s/switch-traffic.yaml
        kubectl get svc nodejs-service -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
        kubectl delete -f k8s/service-${env.currentColor}.yaml
        kubectl delete -f k8s/${env.currentColor}-deploy.yaml
        """
      }
    }
  }
}
