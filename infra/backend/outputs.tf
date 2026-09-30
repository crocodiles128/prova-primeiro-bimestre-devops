output "bucket_name" {
  description = "Nome do bucket S3 para Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB para lock do Terraform"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "aws_region" {
  description = "Região AWS configurada"
  value       = "us-east-1"
}
