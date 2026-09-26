pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'venkateshgupta04/kanban-dashboard'
        IMAGE_TAG = "build-${BUILD_NUMBER}"
        CONTAINER_NAME = 'kanban-dashboard'
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

        stage('Deploy to EC2') {
            steps {
                sh '''
                    set -e

                    NEW_IMAGE="${DOCKER_IMAGE}:${IMAGE_TAG}"

                    echo "Pulling new image..."
                    docker pull "$NEW_IMAGE"

                    OLD_IMAGE=$(docker inspect \
                        --format='{{.Config.Image}}' \
                        "$CONTAINER_NAME" 2>/dev/null || true)

                    echo "Current image: ${OLD_IMAGE:-none}"
                    echo "New image: $NEW_IMAGE"

                    echo "Stopping current application..."
                    docker stop "$CONTAINER_NAME" 2>/dev/null || true
                    docker rm "$CONTAINER_NAME" 2>/dev/null || true

                    echo "Starting new application..."

                    if ! docker run -d \
                        --name "$CONTAINER_NAME" \
                        --memory=512m \
                        --cpus=0.5 \
                        -p 80:8080 \
                        --restart unless-stopped \
                        "$NEW_IMAGE"; then

                        echo "New container failed to start."

                        if [ -n "$OLD_IMAGE" ]; then
                            echo "Rolling back to: $OLD_IMAGE"

                            docker run -d \
                                --name "$CONTAINER_NAME" \
                                --memory=512m \
                                --cpus=0.5 \
                                -p 80:8080 \
                                --restart unless-stopped \
                                "$OLD_IMAGE"

                            echo "Rollback container started."
                        fi

                        exit 1
                    fi

                    echo "Waiting for new deployment health check..."

                    HEALTHY=false

                    for i in $(seq 1 12); do
                        STATUS=$(docker inspect \
                            --format='{{.State.Health.Status}}' \
                            "$CONTAINER_NAME" 2>/dev/null || true)

                        echo "Health status: $STATUS"

                        if [ "$STATUS" = "healthy" ]; then
                            HEALTHY=true
                            break
                        fi

                        sleep 5
                    done

                    if [ "$HEALTHY" = true ]; then
                        echo "Deployment successful."
                        exit 0
                    fi

                    echo "New deployment failed health check."

                    echo "Removing failed container..."
                    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

                    if [ -n "$OLD_IMAGE" ]; then
                        echo "Rolling back to: $OLD_IMAGE"

                        docker run -d \
                            --name "$CONTAINER_NAME" \
                            --memory=512m \
                            --cpus=0.5 \
                            -p 80:8080 \
                            --restart unless-stopped \
                            "$OLD_IMAGE"

                        echo "Waiting for rollback health check..."

                        for i in $(seq 1 12); do
                            STATUS=$(docker inspect \
                                --format='{{.State.Health.Status}}' \
                                "$CONTAINER_NAME" 2>/dev/null || true)

                            echo "Rollback health status: $STATUS"

                            if [ "$STATUS" = "healthy" ]; then
                                echo "Rollback successful."
                                break
                            fi

                            sleep 5
                        done
                    fi

                    exit 1
                '''
            }
        }

        stage('Deployment Validation') {
            steps {
                sh '''
                    docker ps
                    docker inspect \
                        --format='Health={{.State.Health.Status}}' \
                        "$CONTAINER_NAME"

                    curl -I --fail http://localhost/
                '''
            }
        }
    }

    post {
        always {
            sh 'docker image rm ${DOCKER_IMAGE}:${IMAGE_TAG} || true'
        }

        success {
            echo 'CI/CD pipeline completed successfully. Application deployed to EC2.'
        }

        failure {
            echo 'Deployment failed. Rollback was attempted.'
        }
    }
}
