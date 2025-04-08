pipeline {

  agent {
     kubernetes {
       yaml """
apiVersion: v1
kind: Pod
metadata:
  name: kaniko-agent
spec:
  containers:
    - name: kaniko
      image: gcr.io/kaniko-project/executor:latest
      command:
        - cat
      tty: true
      volumeMounts:
        - name: kaniko-secret
          mountPath: /kaniko/.docker/
  volumes:
    - name: kaniko-secret
      secret:
        secretName: regcred
    """
     }
   }

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

    stage('Build & Push Image (Kaniko)') {
      steps {
        container('kaniko') {
          sh """
          /kaniko/executor \
            --dockerfile=Dockerfile \
            --context=. \
            --destination=${IMAGE_FULL_NAME} \
            --insecure-pull=false \
            --verbosity=info \
            --cache=true \
            --docker-config=/kaniko/.docker

          cat /kaniko/.docker/config.json
          """
        }
      }
    }


    stage('Detect Current Deployment') {
      steps {
        script {
          def SWITCH_TRAFFIC = false
          def TARGET_COLOR = " "
          def currentColor = sh(
            script: "kubectl get svc nodejs-service -n default -o jsonpath='{.spec.selector.version}'",
            returnStdout: true
          ).trim()
          echo "Currently live color is: ${currentColor}"

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

    stage('Deploy to Target Color') {
      steps {
        echo "Deploying to ${TARGET_COLOR} environment..."

        sh """
        kubectl apply -f k8s/${TARGET_COLOR}-deploy.yaml
        kubectl apply -f k8s/service-${TARGET_COLOR}.yaml
        kubectl get svc nodejs-${TARGET_COLOR}-service -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
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
        kubectl delete -f k8s/service-${currentColor}.yaml
        kubectl delete -f k8s/${currentColor}-deploy.yaml
        """
      }
    }
  }
}