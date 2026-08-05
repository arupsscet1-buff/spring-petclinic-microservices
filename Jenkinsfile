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
        def appDir
        def helmDir

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
                    script {
                        def branches = services.collectEntries { s ->
                            ["push-${s.name}" : { dockerPush(imageName: s.name, registryType: ecr, registry: ${ECR_REGISTRY}, repository: s.name, awsRegion: ap-south-1) }]
                        }
                        parallel branches
                    }
                }
			}
        }
        stage('Checkout Helm Charts') {
            steps {
                dir(helmDir) {
                    script {
                        helmDir = gitCheckout(
                            url: 'https://github.com/arupsscet1-buff/petclinic-helm.git',
                            branch: 'main'
                        )
                    }
                }
            }
        }
        stage('Update Helm Values') {
            steps {
                dir(helmDir) {
                    script {
                        sh "yq -i '.image.tag = \"${IMAGE_TAG}\"' values.yaml"
                        sh """
                            git add values.yaml
                            git commit -m "Update service images to ${IMAGE_TAG}"
                            git push -u origin main
                        """
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
