output "repository_urls" {
  value = {
    for name, repo in aws_ecr_repository.repo :
    name => repo.repository_url
  }
}

output "repository_names" {
  value = keys(aws_ecr_repository.repo)
}