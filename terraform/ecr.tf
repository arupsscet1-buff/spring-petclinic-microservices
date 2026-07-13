resource "aws_ecr_repository" "customer_service" {
    name = "sprint_petclinic/customer_service"
    image_tag_mutability = "IMMUTABLE"
    force_delete = true
}

resource "aws_ecr_repository" "vets_service" {
    name = "spring_petclinic/vets_service"
    image_tag_mutability = "IMMUTABLE"
    force_delete = true
}