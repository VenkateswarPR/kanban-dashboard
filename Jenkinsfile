pipeline {
    agent any

    environment {
        IMAGE_NAME = 'kanban-dashboard'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Environment Check') {
            steps {
                sh 'git --version'
                sh 'docker --version'
                sh 'docker info'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${IMAGE_NAME}:jenkins-${BUILD_NUMBER} .'
            }
        }

        stage('Verify Docker Image') {
            steps {
                sh 'docker images ${IMAGE_NAME}:jenkins-${BUILD_NUMBER}'
            }
        }
    }

    post {
        always {
            sh 'docker image rm ${IMAGE_NAME}:jenkins-${BUILD_NUMBER} || true'
        }

        success {
            echo 'CI pipeline completed successfully.'
        }

        failure {
            echo 'CI pipeline failed. Check the stage logs above.'
        }
    }
}
