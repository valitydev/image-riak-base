#!groovy
// -*- mode: groovy -*-
build("image-embedded", 'docker-host') {
  checkoutRepo()
  withGithubSshCredentials {
    runStage('submodules') { sh 'make submodules' }
    withCredentials(
    [[$class: 'FileBinding', credentialsId: 'bakka-su-rbkmoney-all', variable: 'BAKKA_SU_PRIVKEY']]) {
      runStage('repos') { sh 'make repos' }}}
  try {
    docker.withRegistry('https://dr2.rbkmoney.com/v2/', 'jenkins_harbor') {
      runStage('build image') { sh 'make' }
      runStage('test image') { sh 'make test' }
      if (env.BRANCH_NAME == 'master') {
        runStage('docker image push') { sh 'make push' }
      }
    }
  } finally {
    runStage('Clean up') { sh 'make clean' }
  }
}
