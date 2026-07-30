resource "aws_ecr_repository" "repo" {

  for_each = toset(var.repositories)

  name                 = each.value
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  force_delete = true

  tags = merge(
    var.tags,
    {
      Name = each.value
    }
  )
}