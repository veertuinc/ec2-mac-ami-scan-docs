pipeline {
    agent { node { label 'everything-linux-ec2-t2micro' } }
    options { 
      disableConcurrentBuilds()
      timeout(time: 10, unit: 'MINUTES')
      skipStagesAfterUnstable()
    }
    stages {
        stage("Install Node Modules") {
          steps {
            sh """
            source ~/.bashrc &>/dev/null
            nvm install 12.21.0
            nvm use 12.21.0
            npm install
            """
          }
        }
        stage("Look for broken links") {
          when { anyOf { branch 'master' }}
          steps {
            sh """
              source ~/.bashrc &>/dev/null
              nvm use 12.21.0
              curl https://htmltest.wjdp.uk | bash
              npx hugo server &
              npm run html-test-build
              ./bin/htmltest -c .htmltest.yml public/
            """
          }
        }
        // stage("generate version snapshots") {
        //     when { anyOf { 
        //       branch 'master';
        //       branch 'staging'; 
        //     } }
        //     steps {
        //         withAWS(credentials:'jenkins-iam', region: 'us-west-2') {
        //           sh './generate-version-snapshots.bash'
        //         }
        //     }
        // }
        stage("build staging") {
            when { anyOf { branch 'staging' }}
            steps {
                sh 'source ~/.bashrc &>/dev/null; nvm use 12.21.0 && npm run staging-build'
            }
        }
        stage("deploy staging") {
            when { anyOf { branch 'staging' }}
            steps {
              withAWS(credentials:'jenkins-iam', region: 'us-west-2') {
                sh 'source ~/.bashrc &>/dev/null; nvm use 12.21.0 && npm run staging-deploy'
              }
            }
        }
        stage("build public") {
            when { anyOf { branch 'master' }}
            steps {
                sh 'source ~/.bashrc &>/dev/null; nvm use 12.21.0 && npm run public-build'
            }
        }
        stage("deploy public") {
            when { anyOf { branch 'master' }}
            steps {
              withAWS(credentials:'jenkins-iam', region: 'us-west-2') {
                sh 'source ~/.bashrc &>/dev/null; nvm use 12.21.0 &&npm run public-deploy'
              }
            }
        }
    }

}