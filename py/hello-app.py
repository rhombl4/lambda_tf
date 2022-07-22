import boto3
import json

rds = boto3.client('rds')

def lambda_handler(event, context):
    message = 'Hello {} UPQ!'.format(event['key1'])
    print(message)
    response = rds.describe_db_instances()
    print(response)
    response = rds.describe_db_snapshots()
    print(response)
    response = rds.copy_db_snapshot(
        SourceDBSnapshotIdentifier='testdb',
        TargetDBSnapshotIdentifier='testdb-daily'
    )
    print(response)
    response = rds.copy_db_snapshot(
        SourceDBSnapshotIdentifier='testdb-daily',
        TargetDBSnapshotIdentifier='testdb-monthly'
    )
    print(response)
    response = rds.delete_db_snapshot(
        DBSnapshotIdentifier='testdb-monthly'
    )
    print(response)

    return {
        'message' : message
    }

