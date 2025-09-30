pipeline {
    agent any

    environment {
        DOCKER_IMAGE_NAME = "aykhanbme/url-shortener"
    }

    stages {
        stage('Checkout Code') {
            steps {
                git(url: 'https://github.com/4ykh4nCyb3r/url-shortener-devops', branch: 'main')
            }
        }

        stage('Build Docker Image') {
            when {
                changeset "**/Dockerfile", "**/*.js", "**/*.json", "**/*.yml", "**/*.yaml"
            }
            steps {
                script {
                    // Get short commit hash for tagging
                    def shortCommit = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    env.IMAGE_TAG = shortCommit

                    // Build image with version tag
                    docker.build("${DOCKER_IMAGE_NAME}:${IMAGE_TAG}")
                }
            }
        }

        stage('Push Docker Image') {
            when {
                changeset "**/Dockerfile", "**/*.js", "**/*.json", "**/*.yml", "**/*.yaml"
            }
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-creds') {
                        // Push versioned tag
                        docker.image("${DOCKER_IMAGE_NAME}:${IMAGE_TAG}").push()

                        // Tag and push as latest
                        sh "docker tag ${DOCKER_IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_IMAGE_NAME}:latest"
                        docker.image("${DOCKER_IMAGE_NAME}:latest").push()
                    }
                }
            }
        }

        stage('Deploy with Ansible') {
            when {
                changeset "**/Dockerfile", "**/*.js", "**/*.json", "**/*.yml", "**/*.yaml"
            }
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'ansible_ssh_key', keyFileVariable: 'SSH_KEY')]) {
                    sh '''
                    cd ansible
                    ansible-playbook ansible-playbook.yml --private-key=$SSH_KEY
                    '''
                }
            }
        }
    }
}
