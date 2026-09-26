pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'venkateshgupta04/kanban-dashboard'
        IMAGE_TAG = "build-${BUILD_NUMBER}"
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
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${DOCKER_IMAGE}:${IMAGE_TAG} .'
            }
        }

        stage('Verify Docker Image') {
            steps {
                sh 'docker images ${DOCKER_IMAGE}:${IMAGE_TAG}'
            }
        }

        stage('Docker Hub Login') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKERHUB_USER',
                        passwordVariable: 'DOCKERHUB_TOKEN'
                    )
                ]) {
                    sh '''
                        echo "$DOCKERHUB_TOKEN" | docker login \
                            --username "$DOCKERHUB_USER" \
                            --password-stdin
                    '''
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                sh 'docker push ${DOCKER_IMAGE}:${IMAGE_TAG}'
            }
        }
    }

    post {
        always {
            sh 'docker image rm ${DOCKER_IMAGE}:${IMAGE_TAG} || true'
        }

        success {
            echo 'CI pipeline completed successfully and image was pushed to Docker Hub.'
        }

        failure {
            echo 'CI pipeline failed. Check the stage logs above.'
        }
    }
}
