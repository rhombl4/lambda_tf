import boto3
import json

rds = boto3.client('rds')

def lambda_handler(event, context):
    message = 'Hello {} UPQ!'.format(event['key1'])
    print(message)
    response = rds.describe_db_instances()

    print(response)

    return {
        'message' : message
    }

