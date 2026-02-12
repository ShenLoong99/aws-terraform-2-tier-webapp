output "alb_logs_id" {
  description = "The ID of the ALB logs S3 bucket"
  value       = aws_s3_bucket.alb_logs.id
}

output "alb_log_policy" {
  description = "The ALB log bucket policy"
  value       = aws_s3_bucket_policy.alb_log_policy
}
