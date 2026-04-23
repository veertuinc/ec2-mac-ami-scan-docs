pipeline {
    agent { node { label 'everything-linux-ec2-t2micro' } }
    options {
      disableConcurrentBuilds()
      timeout(time: 15, unit: 'MINUTES')
      skipStagesAfterUnstable()
    }
    stages {
        stage("Install Node Modules") {
          steps {
            sh """
            source ~/.bashrc &>/dev/null
            nvm install 20
            nvm use 20
            npm ci
            """
          }
        }
        stage("Look for broken links") {
          when { anyOf { branch 'master' }}
          steps {
            sh """
              source ~/.bashrc &>/dev/null
              nvm use 20
              curl https://htmltest.wjdp.uk | bash
              npm run html-test-build
              npx docusaurus serve --port 3000 --no-open &
              SERVE_PID=$!
              sleep 8
              ./bin/htmltest -c .htmltest.yml build
              kill $SERVE_PID
            """
          }
        }
        stage("build staging") {
            when { anyOf { branch 'staging' }}
            steps {
                sh 'source ~/.bashrc &>/dev/null; nvm use 20 && npm run staging-build'
            }
        }
        stage("deploy staging") {
            when { anyOf { branch 'staging' }}
            steps {
              withAWS(credentials:'jenkins-iam', region: 'us-west-2') {
                sh 'source ~/.bashrc &>/dev/null; nvm use 20 && npm run staging-deploy'
              }
            }
        }
        stage("build public") {
            when { anyOf { branch 'master' }}
            steps {
                sh 'source ~/.bashrc &>/dev/null; nvm use 20 && npm run public-build'
            }
        }
        stage("deploy public") {
            when { anyOf { branch 'master' }}
            steps {
              withAWS(credentials:'jenkins-iam', region: 'us-west-2') {
                sh 'source ~/.bashrc &>/dev/null; nvm use 20 && npm run public-deploy'
              }
            }
        }
    }

}
