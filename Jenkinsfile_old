pipeline {
    agent any

    environment {
        ECR_REGISTRY      = "748624204530.dkr.ecr.ap-south-1.amazonaws.com"
        CUSTOMER_ECR_REPO = "sprint_petclinic/customer_service"
        VETS_ECR_REPO     = "spring_petclinic/vets_service"
        REGION            = "ap-south-1"
        IMAGE_TAG         = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                sh '''
                if [ -d "spring-petclinic-microservices" ]; then
                  rm -rf spring-petclinic-microservices
                fi
                  git clone https://github.com/arupsscet1-buff/spring-petclinic-microservices.git
                '''
            }
        }

        stage('Build') {
            steps {
                sh '''
                cd spring-petclinic-microservices
                ./mvnw clean package -pl spring-petclinic-customers-service
                ./mvnw clean package -pl spring-petclinic-vets-service
                '''
            }
        }

        stage('Secret Scan') {
            steps {
                dir('spring-petclinic-microservices') {
                    sh 'gitleaks detect --source ./spring-petclinic-customers-service --no-git -v --exit-code 1'
                    sh 'gitleaks detect --source ./spring-petclinic-vets-service --no-git -v --exit-code 1'
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                cd spring-petclinic-microservices
                docker build  -f docker/Dockerfile --build-arg ARTIFACT_NAME=spring-petclinic-customers-service/target/spring-petclinic-customers-service* --build-arg EXPOSED_PORT=8081 -t customer-service:${IMAGE_TAG} .
                docker build  -f docker/Dockerfile --build-arg ARTIFACT_NAME=spring-petclinic-vets-service/target/spring-petclinic-vets-service* --build-arg EXPOSED_PORT=8081 -t vets-service:${IMAGE_TAG} .

                docker tag customer-service:${IMAGE_TAG} ${ECR_REGISTRY}/${CUSTOMER_ECR_REPO}:${IMAGE_TAG}
                docker tag vets-service:${IMAGE_TAG} ${ECR_REGISTRY}/${VETS_ECR_REPO}:${IMAGE_TAG}
                '''
            }
        }


        stage('Image Scan (Trivy)') {
            steps {
                sh 'cd spring-petclinic-microservices'
                sh "trivy image ${ECR_REGISTRY}/${CUSTOMER_ECR_REPO}:${IMAGE_TAG}"
                sh "trivy image ${ECR_REGISTRY}/${VETS_ECR_REPO}:${IMAGE_TAG}"
            }
        }
        
        stage('Image Push') {
            steps {
                sh '''docker push ${ECR_REGISTRY}/${CUSTOMER_ECR_REPO}:${IMAGE_TAG}
                docker push ${ECR_REGISTRY}/${VETS_ECR_REPO}:${IMAGE_TAG}'''
            }
        }
        
        stage('Deploy Application') {
            steps {
                dir('spring-petclinic-microservices') {
                    sh '''
                    sed -i "s|image:.*|image: ${ECR_REGISTRY}/${CUSTOMER_ECR_REPO}:${IMAGE_TAG}|g" "kubernetes_manifests/customer_service.yaml"
                    sed -i "s|image:.*|image: ${ECR_REGISTRY}/${VETS_ECR_REPO}:${IMAGE_TAG}|g" "kubernetes_manifests/vets_service.yaml"
                    kubectl apply -f kubernetes_manifests/customer_service.yaml 
                    kubectl apply -f kubernetes_manifests/vets_service.yaml
                    
                    #check the deploymnet status
                    kubectl rollout status deployment/customer-service deployment/vets-service -n petclinic
                    '''
                }
            }
        }
    }
    post {
        // The post block executes regardless of whether the build passes or crashes
        always {
            // Wipes out the workspace when the pipeline completes to save disk space
            cleanWs()
        }
    }
}