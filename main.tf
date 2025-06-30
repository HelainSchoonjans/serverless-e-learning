# create s3 bucket and upload knowledge files

# Create S3 bucket
resource "aws_s3_bucket" "knowledge_bucket" {
  bucket = "elearning-knowledge-base-bucket"
}

# Upload files from S3Docs folder
resource "aws_s3_object" "docs" {
  for_each = fileset("${path.module}/S3Docs", "**/*")
  
  bucket = aws_s3_bucket.knowledge_bucket.id
  key    = each.value
  source = "${path.module}/S3Docs/${each.value}"
  etag   = filemd5("${path.module}/S3Docs/${each.value}")
}

# Block public access
resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.knowledge_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

