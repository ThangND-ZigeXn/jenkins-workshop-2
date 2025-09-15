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
            def RELEASE_DATE = new Date().format("yyyyMMddHHmmss")
            def PRIVATE_FOLDER = "/usr/share/nginx/html/jenkins/thangnd2"
            def DEPLOY_FOLDER = "/usr/share/nginx/html/jenkins/thangnd2/deploy"
            def RELEASE_FOLDER = "${DEPLOY_FOLDER}/${RELEASE_DATE}"
            def TEMPLATE_FOLDER = "/usr/share/nginx/html/jenkins/template2"
            def REMOTE_PORT = 3334
            def REMOTE_USER = "newbie"
            def REMOTE_HOST = "118.69.34.46"

            sshagent(credentials: ['REMOTE_SERVER']) {
              sh """
                ssh -o StrictHostKeyChecking=no -p ${REMOTE_PORT} ${REMOTE_USER}@${REMOTE_HOST} '
                  mkdir -p ${PRIVATE_FOLDER}
                  if [ -z "\$(ls -A ${PRIVATE_FOLDER})" ]; then
                    cp -r ${TEMPLATE_FOLDER}/* ${PRIVATE_FOLDER}
                  fi
                '
              """

              sh """
                ssh -o StrictHostKeyChecking=no -p ${REMOTE_PORT} ${REMOTE_USER}@${REMOTE_HOST} "mkdir -p ${RELEASE_FOLDER}"
              """

              sh """
                scp -o StrictHostKeyChecking=no -P ${REMOTE_PORT} -r ./index.html ./404.html ./css ./js ./images ${REMOTE_USER}@${REMOTE_HOST}:${RELEASE_FOLDER}
              """

              sh """
                ssh -o StrictHostKeyChecking=no -p ${REMOTE_PORT} ${REMOTE_USER}@${REMOTE_HOST} "rm -rf ${DEPLOY_FOLDER}/current && ln -s ${RELEASE_FOLDER} ${DEPLOY_FOLDER}/current"
              """

              sh """
                ssh -o StrictHostKeyChecking=no -p ${REMOTE_PORT} ${REMOTE_USER}@${REMOTE_HOST} '
                  cd ${DEPLOY_FOLDER} && ls -1tr | grep -v "^current\$" | tail -n +\$((${MAX_RELEASE} + 1)) | xargs -r rm -rf
                '
              """
            }
          }
          else if (params.DEPLOY_TYPE == 'firebase') {
            if (env.GOOGLE_APPLICATION_CREDENTIALS) {
              withCredentials([file(credentialsId: 'ADC', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                sh 'export GOOGLE_APPLICATION_CREDENTIALS=$GOOGLE_APPLICATION_CREDENTIALS'
                sh 'firebase deploy --only hosting --project="thangnd-workshop2"'
              }
            } else if (env.FIREBASE_TOKEN) {
              sh 'NODE_OPTIONS="--max-old-space-size=4096" firebase deploy --token "$FIREBASE_TOKEN" --only hosting --project="thangnd-workshop2"'
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
