pipeline {
  agent any

  environment {
    FIREBASE_TOKEN = credentials('FIREBASE_TOKEN')
    GOOGLE_APPLICATION_CREDENTIALS = credentials('GOOGLE_APPLICATION_CREDENTIALS')
  }

  parameters {
    choice(name: 'DEPLOY_TYPE', choices: ['local', 'remote', 'firebase'], description: 'The type of the deploy')
    string(name: 'MAX_RELEASE', defaultValue: '5', description: 'The max release')
  }

  stages {
    stage('Checkout(scm)') {
      steps {
        echo '*************** Checkout ***************'
        checkout scm
      }
    }

    stage('Build') {
      steps {
        echo '*************** Build ***************'
        sh 'npm install'
      }
    }

    stage('Lint/Test') {
      steps {
        echo '*************** Lint/Test ***************'
        sh 'npm run test:ci'
      }
    }

    stage('Deploy') {
      steps {
        echo '*************** Deploy ***************'
        script {
          if (params.DEPLOY_TYPE == 'local') {
            ansiblePlaybook(
              playbook: '/var/jenkins_home/ansible/deploy.local.yml',
              inventory: '/var/jenkins_home/ansible/hosts',
              extraVars: [
                max_release: params.MAX_RELEASE
              ]
            )
          }
          else if (params.DEPLOY_TYPE == 'remote') {
            ansiblePlaybook(
              playbook: '/var/jenkins_home/ansible/deploy.remote.yml',
              inventory: '/var/jenkins_home/ansible/hosts',
              extraVars: [
                max_release: params.MAX_RELEASE
              ]
            )
          }
          else if (params.DEPLOY_TYPE == 'firebase') {
            if (env.GOOGLE_APPLICATION_CREDENTIALS) {
              sh 'export GOOGLE_APPLICATION_CREDENTIALS="$GOOGLE_APPLICATION_CREDENTIALS"'
              sh 'firebase deploy --only hosting --project="thangnd-workshop2"'
            } else if (env.FIREBASE_TOKEN) {
              sh 'firebase deploy --token "$FIREBASE_TOKEN" --only hosting --project="thangnd-workshop2"'
            }
          }
        }
      }
    }
  }

  post {
    always {
      script {
        cleanWs()
      }
    }

    success {
      echo '*************** Build success ***************'
      // sendSlack(
      //   channel: '#lnd-2025-workshop',
      //   color: 'good',
      //   message: 'Build success'
      // )
    }

    failure {
      echo '*************** Build failure ***************'
      // sendSlack(
      //   channel: '#lnd-2025-workshop',
      //   color: 'danger',
      //   message: 'Build failure'
      // )
    }
  }
}
