# create s3 bucket and upload knowledge files

# Create S3 bucket
resource "aws_s3_bucket" "knowledge_bucket" {
  bucket = "${local.env.sid}-knowledge-base-bucket"
}

resource "aws_s3_bucket_cors_configuration" "this" {
  bucket = aws_s3_bucket.knowledge_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = [
      "GET",
      "PUT",
      "POST",
      "DELETE"
    ]
    allowed_origins = ["*"]
  }
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

# Create IAM role for Bedrock knowledge base
resource "aws_iam_role" "bedrock_kb_role" {
  name = "${local.env.sid}-bedrock-kb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
      }
    ]
  })
}

# Create IAM policy for S3 access
resource "aws_iam_role_policy" "bedrock_kb_policy" {
  name = "${local.env.sid}-bedrock-kb-policy"
  role = aws_iam_role.bedrock_kb_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.knowledge_bucket.arn,
          "${aws_s3_bucket.knowledge_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Permissions to chat with documents
resource "aws_iam_role_policy" "bedrock_kb_chat_policy" {
  name = "${local.env.sid}-bedrock-kb-chat-policy"
  role = aws_iam_role.bedrock_kb_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:RetrieveAndGenerate"
        ]
        Resource = [
          "*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "bedrock_kb_kms_policy" {
  name = "${local.env.sid}-bedrock-kb-kms-policy"
  role = aws_iam_role.bedrock_kb_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = [
          "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:key/*"
        ]
        Condition = {
          StringLike = {
            "kms:ViaService": "aoss.*.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Policy for opensearch access
resource "aws_iam_role_policy" "bedrock_kb_oass_policy" {
  name = "${local.env.sid}-bedrock-kb-oass-policy"
  role = aws_iam_role.bedrock_kb_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aoss:APIAccessAll"
        ]
        Resource = [
          aws_opensearchserverless_collection.collection.arn
        ]
      }
    ]
  })
}

# Policy for opensearch access
resource "aws_iam_role_policy" "bedrock_kb_model_policy" {
  name = "${local.env.sid}-bedrock-kb-model-policy"
  role = aws_iam_role.bedrock_kb_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = [
         data.aws_bedrock_foundation_model.embedding.model_arn
        ]
      }
    ]
  })
}


locals {
    s3_uri = "s3://${aws_s3_bucket.knowledge_bucket.id}"
    collection_name = "${local.env.sid}-bedrock-kb-collection"
}

# useful resource for opensearch configuration with terraform:
# https://aws.amazon.com/blogs/big-data/deploy-amazon-opensearch-serverless-with-terraform/

data "aws_bedrock_foundation_model" "embedding" {
  model_id = "amazon.titan-embed-text-v2:0"
}

data "aws_bedrock_foundation_model" "claude" {
  model_id = "anthropic.claude-3-haiku-20240307-v1:0"
}

# Create Bedrock knowledge base
resource "aws_bedrockagent_knowledge_base" "elearning_kb" {
  name = "${local.env.sid}-bedrock-kb"
  role_arn = aws_iam_role.bedrock_kb_role.arn

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
        embedding_model_arn = data.aws_bedrock_foundation_model.embedding.model_arn
    }
  }
  
  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.collection.arn
      vector_index_name = "bedrock-knowledge-base-default-index" 
      field_mapping {
        vector_field   = "bedrock-knowledge-base-default-vector"
        text_field     = "AMAZON_BEDROCK_TEXT"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
  }
}

resource "aws_bedrockagent_data_source" "s3_source" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.elearning_kb.id
  name              = "${local.env.sid}-s3-source"
  data_deletion_policy = "RETAIN"

  data_source_configuration {
    type = "S3"
    s3_configuration {
        bucket_arn = aws_s3_bucket.knowledge_bucket.arn
    }
  }

  depends_on = [aws_bedrockagent_knowledge_base.elearning_kb]
}