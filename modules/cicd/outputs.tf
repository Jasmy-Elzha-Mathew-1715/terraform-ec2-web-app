output "codepipeline_name" {
  description = "The name of the CodePipeline"
  value       = aws_codepipeline.pipeline.name
}

output "codebuild_backend_project_name" {
  description = "The name of the CodeBuild project for the backend"
  value       = aws_codebuild_project.backend_build.name
}

output "codebuild_frontend_project_name" {
  description = "The name of the CodeBuild project for the frontend"
  value       = aws_codebuild_project.frontend_build.name
}

output "codedeploy_app_name" {
  description = "The name of the CodeDeploy application"
  value       = aws_codedeploy_app.application.name
}

output "codedeploy_backend_deployment_group" {
  description = "The name of the CodeDeploy deployment group for the backend"
  value       = aws_codedeploy_deployment_group.backend_deployment_group.deployment_group_name
}

output "codedeploy_frontend_deployment_group" {
  description = "The name of the CodeDeploy deployment group for the frontend"
  value       = aws_codedeploy_deployment_group.frontend_deployment_group.deployment_group_name
}

output "webhook_url" {
  description = "The URL of the webhook for GitHub integration"
  value       = aws_codepipeline_webhook.github_webhook.url
  sensitive   = true
}