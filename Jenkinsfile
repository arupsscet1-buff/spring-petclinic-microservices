@Library('jenkins_shared_libraries') _
def services = [
    [name: 'spring-petclinic-admin-server',       port: '9090'],
    [name: 'spring-petclinic-customers-service',  port: '8081'],
    [name: 'spring-petclinic-vets-service',       port: '8082'],
    [name: 'spring-petclinic-visits-service',     port: '8083'],
    [name: 'spring-petclinic-genai-service',      port: '8084'],
    [name: 'spring-petclinic-config-server',      port: '8888'],
    [name: 'spring-petclinic-discovery-server',   port: '8761'],
    [name: 'spring-petclinic-api-gateway',        port: '8080'],
]
def appDir
def helmDir

pipeline {
    agent {
        kubernetes {
            cloud 'jenkins-agent'
            inheritFrom 'jenkins-agent'
            defaultContainer 'jenkins-tools'
        }
    }
    environment {
        ECR_REGISTRY      = "748624204530.dkr.ecr.ap-south-1.amazonaws.com"
        REGION            = "ap-south-1"
        IMAGE_TAG           = "1.0.0-${env.BUILD_NUMBER}"
    }

    stages {

        stage('Checkout Application Code') {
            steps {
                script {
                    appDir = gitCheckout(
                        url: 'https://github.com/arupsscet1-buff/spring-petclinic-microservices.git',
                        branch: 'main'
                    )
                }
            }
        }
        stage('Build & Verify'){
            steps {
                dir(appDir) {
                    sh 'mvn wrapper:wrapper'
                    mavenWrapperBuild()
                }
            }
        }
        stage('Concurrent Analysis & Testing') {
            parallel {
                stage('Gileaks secret scan'){
                    steps {
                        dir(appDir) {
						    gitLeaks()
                        }
                    }
                }
                stage('Trivy file system scan') {
                    steps {
                        dir(appDir) {
						    trivyScan()
                        }
                    }
                }
            }
        }
        stage('Docker build') {
            steps {
                dir(appDir) {
                    sh 'pwd'
                    sh 'ls -ltra spring-petclinic-admin-server/target/'
                    script {
                        services.each { s ->
                            dockerBuild(svc_name: s.name, port: s.port)
                        }
                    }
				}
            }
        }
        stage('Push Image') {
            steps {
                dir(appDir) {
                        sh '''
                        echo "=== AWS Identity ==="
                        aws sts get-caller-identity

                        echo "=== AWS Configure ==="
                        aws configure list

                        echo "=== Environment ==="
                        env | grep AWS || true
                        '''
                    script {
                        def branches = services.collectEntries { s ->
                            ["push-${s.name}" : { dockerPush(imageName: s.name, registryType: 'ecr', registry: env.ECR_REGISTRY, repository: s.name, awsRegion: env.REGION) }]
                        }
                        parallel branches
                    }
                }
			}
        }
        stage('Checkout Helm Charts') {
            steps {
                script {
                    helmDir = gitCheckout(
                        url: 'https://github.com/arupsscet1-buff/petclinic-helm.git',
                        branch: 'main'
                    )
                }
            }
        }
        stage('Update Helm Values') {
            steps {
                dir(helmDir) {

                    script {
                        sh "yq -i '.*.image.tag = \"${IMAGE_TAG}\"' values.yaml"
                        sh "cat values.yaml | grep tag"
                        withCredentials([
                            usernamePassword(
                                credentialsId: 'github_cred',
                                usernameVariable: 'GIT_USERNAME',
                                passwordVariable: 'GIT_TOKEN'
                            )
                        ]) {
                                sh """
                                    git config --global --add safe.directory /home/jenkins/agent/workspace/spring-petsclinic/petclinic-helm
                                    git config user.name "arupsscet1-buff"
                                    git config user.email "arupsscet1@gmail.com"

                                    git remote set-url origin https://${GIT_USERNAME}:${GIT_TOKEN}@github.com/arupsscet1-buff/petclinic-helm.git

                                    git add values.yaml

                                    git diff --cached --quiet || \
                                    git commit -m "Update service images to ${IMAGE_TAG}"

                                    git push origin main
                                """
                            }
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up the workspace...'
            cleanWs()
        }
    }
}
