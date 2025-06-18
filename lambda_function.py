import json
import boto3
from boto3.dynamodb.conditions import Key
import datetime

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('GuestMovement')

def lambda_handler(event, context):
    # Parse request parameters from API Gateway
    current_attraction = event.get('queryStringParameters', {}).get('currentAttraction', 'treasure_hunt')

    try:
        # Fetch recent congestion data (last 5 minutes)
        recent_time = (datetime.datetime.utcnow() - datetime.timedelta(minutes=5)).isoformat()
        response = table.scan()  # In a real app, use Query if possible for better performance
        
        # Filter and score attractions by lowest congestion
        data = response['Items']
        relevant_data = [item for item in data if item['timestamp'] > recent_time]

        # Example scoring by congestion level (lower is better)
        scores = {}
        for item in relevant_data:
            attr_id = item['attractionId']
            congestion = int(item['congestionLevel'])
            scores[attr_id] = min(congestion, scores.get(attr_id, 100))

        # Recommend attraction with lowest congestion
        if scores:
            best_option = min(scores, key=scores.get)
        else:
            best_option = "No clear recommendation—please try again soon."

        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'currentLocation': current_attraction,
                'recommendedNextStop': best_option
            })
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
