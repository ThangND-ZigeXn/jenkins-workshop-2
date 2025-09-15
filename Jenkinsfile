pipeline {
  agent any

  environment {
    FIREBASE_TOKEN = credentials('FIREBASE_TOKEN')
    GOOGLE_APPLICATION_CREDENTIALS = credentials('GOOGLE_APPLICATION_CREDENTIALS')
  }

  parameters {
    choice(name: 'DEPLOY_TYPE', choices: ['local', 'remote', 'firebase', 'all'], description: 'The type of the deploy')
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
          def deployTypes = []

          if (params.DEPLOY_TYPE == 'all') {
            deployTypes = ['local', 'remote', 'firebase']
          } else {
            deployTypes = [params.DEPLOY_TYPE]
          }

          for (deployType in deployTypes) {
            echo "========> Deploying to ${deployType} <========="
            if (deployType == 'local') {
              ansiblePlaybook(
                playbook: '/var/jenkins_home/ansible/deploy.local.yml',
                inventory: '/var/jenkins_home/ansible/hosts',
                extraVars: [
                  max_release: params.MAX_RELEASE
                ]
              )
            } else if (deployType == 'remote') {
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
            else if (deployType == 'firebase') {
              sh '''
                mkdir -p public
                cp -r ./index.html ./404.html ./css ./js ./images ./public
              '''

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
  }

  post {
    success {
      echo '*************** Build success ***************'
      script {
        def authorEmail = ""

        dir("${env.WORKSPACE}") {
          authorEmail = sh(
            script: "git log -1 --pretty=format:'%ae' ${env.GIT_COMMIT}",
            returnStdout: true
          ).trim()
        }
        def repoUrl = env.GIT_URL.replaceFirst(/\.git$/, '')
        def commitUrl = "${repoUrl}/commit/${env.GIT_COMMIT}"
        def buildTime = new Date().format("yyyy-MM-dd HH:mm:ss")
        def deployTypeDisplay = params.DEPLOY_TYPE == 'all' ? 'all (local, remote, firebase)' : params.DEPLOY_TYPE

        def message = """
          :white_check_mark: Build SUCCESS
          - Author: ${authorEmail}
          - Job: ${env.JOB_NAME}#${env.BUILD_NUMBER}
          - Commit: ${commitUrl}
          - Time: ${buildTime}
          - Deploy type: ${deployTypeDisplay}
        """.trim()

        if (params.DEPLOY_TYPE == 'local') {
          message += '\n - Local: http://localhost/jenkins/deploy/current/'
        } else if (params.DEPLOY_TYPE == 'firebase') {
          message += '\n - Firebase: https://thangnd-workshop2.web.app/'
        } else if (params.DEPLOY_TYPE == 'remote') {
          message += '\n - Remote: http://118.69.34.46/jenkins/thangnd2/deploy/current/'
        } else if (params.DEPLOY_TYPE == 'all') {
          message += '\n - Local: http://localhost/jenkins/deploy/current/'
          message += '\n - Firebase: https://thangnd-workshop2.web.app/'
          message += '\n - Remote: http://118.69.34.46/jenkins/thangnd2/deploy/current/'
        }

        // sendSlack(
        //   channel: '#lnd-2025-workshop',
        //   color: 'good',
        //   message: message
        // )

        echo message
      }
    }

    failure {
      echo '*************** Build failure ***************'
      script {
        def authorEmail = ""

        dir("${env.WORKSPACE}") {
          authorEmail = sh(
            script: "git log -1 --pretty=format:'%ae' ${env.GIT_COMMIT}",
            returnStdout: true
          ).trim()
        }
        def repoUrl = env.GIT_URL.replaceFirst(/\.git$/, '')
        def commitUrl = "${repoUrl}/commit/${env.GIT_COMMIT}"
        def buildTime = new Date().format("yyyy-MM-dd HH:mm:ss")
        def deployTypeDisplay = params.DEPLOY_TYPE == 'all' ? 'all (local, remote, firebase)' : params.DEPLOY_TYPE
        def logUrl = "${env.BUILD_URL}console"

        def message = """
          :x: Build FAILED
          - Author: ${authorEmail}
          - Job: ${env.JOB_NAME}#${env.BUILD_NUMBER}
          - Commit: ${commitUrl}
          - Time: ${buildTime}
          - Deploy type: ${deployTypeDisplay}
          - Log: ${logUrl}
        """.trim()

        // sendSlack(
        //   channel: '#lnd-2025-workshop',
        //   color: 'danger',
        //   message: message
        // )

        echo message
      }
    }

    always {
      script {
        cleanWs()
      }
    }
  }
}
