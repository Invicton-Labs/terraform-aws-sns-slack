import urllib3
import os
http = urllib3.PoolManager()


def lambda_handler(event, context):
    webhook = os.environ["WEBHOOK"]
    print(event)

    for record in event["Records"]:
        if 'EventSource' in record and record['EventSource'] == 'aws:sns':
            encoded_msg = record['Sns']['Message'].encode('utf-8')
        else:
            encoded_msg = record["body"].encode('utf-8')
        resp = http.request('POST', webhook, body=encoded_msg)
        if resp.status != 200:
            print("[ERROR] Failed to post message to Slack webhook (status code: {}, response: {}). Original message: {}".format(
                resp.status, resp.data, record["body"]))
