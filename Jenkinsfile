#!groovy
// -*- mode: groovy -*-

build("image-embedded", 'docker-host') {
  checkoutRepo()
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
    sh 'make .latest-stage3.loaded'
  }
  runStage('embedded image build') {
    sh 'make embedded'
  }
  try {
    runStage('smoke test') {
      sh 'make test'
    }
    if (env.BRANCH_NAME == 'master') {
      runStage('docker image push') {
	sh 'make push'
      }
    }
  } finally {
    runStage('rm local image') {
      sh 'make clean'
    }
  }
}
