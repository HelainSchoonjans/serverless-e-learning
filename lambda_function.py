import json
#1. import boto3
import boto3
import os

KNOWLEDGE_BASE_ID = os.environ['KNOWLEDGE_BASE_ID']
MODEL_ARN = os.environ['MODEL_ARN']

#2 create client connection with bedrock
client_bedrock_knowledgebase = boto3.client('bedrock-agent-runtime')

def lambda_handler(event, context):
    #3 Store the user prompt
    print(event['prompt'])
    user_prompt=event['prompt']
    # 4. Use retrieve and generate API
    client_knowledgebase = client_bedrock_knowledgebase.retrieve_and_generate(
    input={
        'text': user_prompt
    },
    retrieveAndGenerateConfiguration={
        'type': 'KNOWLEDGE_BASE',
        'knowledgeBaseConfiguration': {
            'knowledgeBaseId': KNOWLEDGE_BASE_ID,
            'modelArn': MODEL_ARN
        }
    })
            
    # print(client_knowledgebase)     
    #print(client_knowledgebase['output']['text'])
    #print(client_knowledgebase['citations'][0]['generatedResponsePart']['textResponsePart'])
    response_kbase_final=client_knowledgebase['output']['text']
    return {
        'statusCode': 200,
        'body': response_kbase_final
    }
    