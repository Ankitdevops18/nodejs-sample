pipeline {
  agent any

  tools {
    nodejs 'default'
    dockerTool 'default'
  }

  environment {
    IMAGE_NAME = 'hello-node-app'
    DOCKER_REGISTRY = 'ankitofficial1821'
    KUBECONFIG = "/var/jenkins_home/.kube/config"
  }



  stages {

    stage('Detect Current Deployment') {
        steps {
            script {
                // Enable traffic switch by default
                SWITCH_TRAFFIC = false
                // Fetch current version label from the service
                def currentColor = sh(
                    script: "kubectl get svc nodejs-service -o jsonpath='{.spec.selector.version}'",
                    returnStdout: true
                ).trim()

                echo "Currently live color is: ${currentColor}"

                // Toggle color
                if (currentColor == "blue") {
                    TARGET_COLOR = "green"
                } else if (currentColor == "green") {
                    TARGET_COLOR = "blue"
                } else {
                    error("Unknown color deployed: ${currentColor}")
                }
                echo "Target deployment color: ${TARGET_COLOR}"
            }
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

    stage('Test') {
      steps {
        sh 'npm test'
      }
    }

    stage('Build Docker Image') {
      steps {
        sh 'docker build -t $DOCKER_REGISTRY/$IMAGE_NAME:latest .'
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

    stage('Deploy to Target Color') {
        steps {
            echo "Deploying to ${TARGET_COLOR} environment..."

            sh """
            kubectl apply -f k8s/${TARGET_COLOR}-deploy.yaml
            kubectl apply -f k8s/service-${TARGET_COLOR}.yaml
            kubectl get svc nodejs-${TARGET_COLOR}-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
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
        kubectl get svc nodejs-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
        kubectl delete -f k8s/service-${currentColor}.yaml
        kubectl delete -f k8s/${currentColor}-deploy.yaml
        """
      }
    }
  }
}