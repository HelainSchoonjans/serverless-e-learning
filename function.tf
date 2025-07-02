
# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda_bedrock_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach Bedrock Full Access policy
resource "aws_iam_role_policy_attachment" "bedrock_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonBedrockFullAccess"
}

# Basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "zip" {
  type = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function.zip"
}

# Lambda function
resource "aws_lambda_function" "bedrock_lambda" {
  filename         = data.archive_file.zip.output_path
  function_name    = "bedrock_lambda_function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.zip.output_base64sha256
  runtime         = "python3.12"
  timeout         = 60

  environment {
    variables = {
      ENVIRONMENT = local.env.environment
      KNOWLEDGE_BASE_ID = aws_bedrockagent_knowledge_base.elearning_kb.id
      MODEL_ARN = data.aws_bedrock_foundation_model.claude.model_arn
    }
  }
}
