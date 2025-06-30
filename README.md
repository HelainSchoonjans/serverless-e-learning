# Serverless e-learning app

This project comes from the [Bedrock/GenAI Udemy course](https://www.udemy.com/course/amazon-bedrock-aws-generative-ai-beginner-to-advanced)

It is a simple serverless API querying a Bedrock knowledge base of AWS documentation pdfs.

## Prerequisites

Follow the steps in PREREQUISITES.md

## Infrastructure-as-code

### Commands

The project infrastructure as code is defined in Terraform and can be interacted with the following commands:

#### Initialize Terraform working directory, download providers and modules

    terraform init

#### Preview the changes Terraform will make

    terraform plan

#### Apply the infrastructure changes

    terraform apply

Type 'yes' when prompted to confirm

#### To update infrastructure, modify .tf files then run

    terraform plan    # Preview changes
    terraform apply   # Apply changes

#### To destroy all resources created by Terraform

    terraform destroy
    
Type 'yes' when prompted to confirm

#### To automatically approve without prompts

    terraform apply -auto-approve
    terraform destroy -auto-approve