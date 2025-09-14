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
              playbook: 'deploy.local.yml',
              inventory: 'hosts',
              extraVars: [
                max_release: params.MAX_RELEASE
              ]
            )
          }
          else if (params.DEPLOY_TYPE == 'remote') {
            ansiblePlaybook(
              playbook: 'deploy.remote.yml',
              inventory: 'hosts',
              extraVars: [
                max_release: params.MAX_RELEASE
              ]
            )
          }
          else if (params.DEPLOY_TYPE == 'firebase') {
            ansiblePlaybook(
              playbook: 'deploy.firebase.yml',
              inventory: 'hosts',
              extraVars: [
                max_release: params.MAX_RELEASE,
                firebase_token: env.FIREBASE_TOKEN,
                google_application_credentials: env.GOOGLE_APPLICATION_CREDENTIALS
              ]
            )
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
