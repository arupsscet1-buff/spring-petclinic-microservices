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
    
    stages {
        stage('Checkout'){
            steps {
				gitCheckout(branch:'main', credentialsId:'github_cred', url:'https://github.com/arupsscet1-buff/spring-petclinic-microservices.git')
            }
        }
        stage('Build & Verify'){
            steps {
				sh 'mvn wrapper:wrapper'
				mavenWrapperBuild()
            }
        }
        stage('Concurrent Analysis & Testing') {
            parallel {
                stage('Gileaks secret scan'){
                    steps {
						gitLeaks()
                    }
                }
                stage('Trivy file system scan') {
                    steps {
						trivyScan()
                    }
                }
            }
        }
        stage('Docker build') {
            steps {
				script {
					services.each { s ->
						dockerBuild(svc_name: s.name, port: s.port)
					}
				}
            }
        }
        stage('Push Image') {
            steps {
				script {
					def branches = services.collectEntries { s ->
						["push-${s.name}" : { dockerPush(svc_name: s.name) }]
					}
					parallel branches
				}
			}
        }
        stage('Deploy') {
            steps {
                sh '''
                    pwd

                    find kubernetes_manifest -name "deployment.yaml" \
                    -exec sed -Ei "s|(image: .+:).*|\\1${IMAGE_TAG}|" {} \\;

                    kubectl apply -f kubernetes_manifest/
                '''
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