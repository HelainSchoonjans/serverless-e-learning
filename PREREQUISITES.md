## Prerequisites

- Request for access to the target models (titan, etc.) in the AWS Console
- Configure account credentials in the ~/home/.aws file
- Create a s3 bucket to save the terraform state and save his name in provider.tf backend.
- create a dynamoDB table matching the name specified in the S3 backend and with a partition key `LockID` of type string