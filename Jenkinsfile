#!groovy
// -*- mode: groovy -*-

// Args:
// GitHub repo name
// Jenkins agent label
// Tracing artifacts to be stored alongside build logs
def images_pipeline(String repoName, String agentLabel, Closure body) {
  node(agentLabel) {
    try {
      env.REPO_NAME = repoName
      runStage('git checkout') {
	checkout scm
	//sh 'git submodule update --init'
	sh 'git --no-pager log -1 --pretty=format:"%an" > .commit_author'
	env.COMMIT_AUTHOR = readFile('.commit_author').trim()
      }
      wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'XTerm']) {
	body.call()
      }

      slackSend color: 'good', message: "<${env.BUILD_URL}|Build ${env.BUILD_NUMBER}> for ${env.REPO_NAME} by ${env.COMMIT_AUTHOR} has passed on branch ${env.BRANCH_NAME} (jenkins node: ${env.NODE_NAME})."
    } catch (Exception e) {
      slackSend color: 'danger', message: "<${env.BUILD_URL}|Build ${env.BUILD_NUMBER}> for ${env.REPO_NAME} by ${env.COMMIT_AUTHOR} has failed on branch ${env.BRANCH_NAME} at stage: ${env.STAGE_NAME} (jenkins node: ${env.NODE_NAME})."
      throw e; // rethrow so the build is considered failed
    }
  }
}

images_pipeline("images", 'docker-host') {
  withCredentials(
    [[$class: 'FileBinding', credentialsId: 'github-rbkmoney-ci-bot-file', variable: 'GITHUB_PRIVKEY']]) {
    runStage('submodules') {
      sh 'make submodules'
    }
  }
  runStage('stage3 download') {
    sh 'make .latest-stage3'
  }
  withCredentials(
    [[$class: 'FileBinding', credentialsId: 'bakka-su-rbkmoney-all', variable: 'BAKKA_SU_PRIVKEY']]) {
    runStage('bootstrap image build') {
      sh 'make bootstrap'
    }
  }
  if (env.BRANCH_NAME == 'master') {
    runStage('docker image push') {
      sh 'make push'
    }
  }
}
