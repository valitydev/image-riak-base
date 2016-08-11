#!groovy
// -*- mode: groovy -*-

build("images", 'docker-host') {
  withCredentials(
    [[$class: 'FileBinding', credentialsId: 'github-rbkmoney-ci-bot-file', variable: 'GITHUB_PRIVKEY'],
     [$class: 'FileBinding', credentialsId: 'bakka-su-rbkmoney-all', variable: 'BAKKA_SU_PRIVKEY']]) {
    runStage('submodules') {
      sh 'make submodules'
    }
    runStage('shared repositories update') {
      sh 'make repos'
    }
  }
  runStage('stage3 download') {
    sh 'make .latest-stage3'
  }
  runStage('bootstrap image build') {
    sh 'make bootstrap'
  }
  if (env.BRANCH_NAME == 'master') {
    runStage('docker image push') {
      sh 'make push'
    }
  }
}
