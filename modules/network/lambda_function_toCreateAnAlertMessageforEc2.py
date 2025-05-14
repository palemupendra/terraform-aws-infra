import boto3
import json
from datetime import datetime, timedelta

def lambda_handler(event, context):
    # Initialize AWS clients
    cloudwatch = boto3.client('cloudwatch')
    ec2 = boto3.client('ec2')
    sns = boto3.client('sns')
    
    # Configuration
    CPU_THRESHOLD = 80.0  # CPU usage percentage threshold
    MEMORY_THRESHOLD = 80.0  # Memory usage percentage threshold
    TIME_PERIOD = 300  # Time period in seconds (5 minutes)
    
    # SNS Topic ARN - replace with your actual SNS topic ARN
    SNS_TOPIC_ARN = 'arn:aws:sns:your-region:your-account-id:your-topic-name'
    
    try:
        # Get all running EC2 instances
        response = ec2.describe_instances(
            Filters=[
                {
                    'Name': 'instance-state-name',
                    'Values': ['running']
                }
            ]
        )
        
        exhausted_instances = []
        
        # Check each instance
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                instance_id = instance['InstanceId']
                instance_name = get_instance_name(instance.get('Tags', []))
                
                # Check CPU usage
                cpu_usage = get_metric_average(
                    cloudwatch, 
                    instance_id, 
                    'CPUUtilization',
                    TIME_PERIOD
                )
                
                # Check Memory usage
                memory_usage = get_metric_average(
                    cloudwatch, 
                    instance_id, 
                    'MemoryUtilization',
                    TIME_PERIOD
                )
                
                # Check if instance is exhausted
                is_exhausted = False
                issues = []
                
                if cpu_usage and cpu_usage > CPU_THRESHOLD:
                    is_exhausted = True
                    issues.append(f"CPU: {cpu_usage:.2f}%")
                    
                if memory_usage and memory_usage > MEMORY_THRESHOLD:
                    is_exhausted = True
                    issues.append(f"Memory: {memory_usage:.2f}%")
                
                if is_exhausted:
                    exhausted_instances.append({
                        'instance_id': instance_id,
                        'instance_name': instance_name,
                        'issues': issues,
                        'cpu_usage': cpu_usage,
                        'memory_usage': memory_usage
                    })
        
        # Send notifications for exhausted instances
        if exhausted_instances:
            send_notifications(sns, SNS_TOPIC_ARN, exhausted_instances)
            
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': f'Found {len(exhausted_instances)} exhausted instances',
                    'instances': exhausted_instances
                })
            }
        else:
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'No exhausted instances found'
                })
            }
            
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }

def get_metric_average(cloudwatch, instance_id, metric_name, time_period):
    """Get average metric value for an instance over the specified time period"""
    try:
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(seconds=time_period)
        
        # For Memory metrics, we need to specify the namespace differently
        if metric_name == 'MemoryUtilization':
            namespace = 'CWAgent'
            dimensions = [
                {
                    'Name': 'InstanceId',
                    'Value': instance_id
                }
            ]
        else:
            namespace = 'AWS/EC2'
            dimensions = [
                {
                    'Name': 'InstanceId',
                    'Value': instance_id
                }
            ]
        
        response = cloudwatch.get_metric_statistics(
            Namespace=namespace,
            MetricName=metric_name,
            Dimensions=dimensions,
            StartTime=start_time,
            EndTime=end_time,
            Period=time_period,
            Statistics=['Average']
        )
        
        if response['Datapoints']:
            return response['Datapoints'][0]['Average']
        else:
            return None
            
    except Exception as e:
        print(f"Error getting metric {metric_name} for instance {instance_id}: {str(e)}")
        return None

def get_instance_name(tags):
    """Extract instance name from tags"""
    for tag in tags:
        if tag['Key'] == 'Name':
            return tag['Value']
    return 'Unknown'

def send_notifications(sns, topic_arn, exhausted_instances):
    """Send SNS notifications for exhausted instances"""
    for instance in exhausted_instances:
        subject = f"ALERT: EC2 Instance {instance['instance_id']} is Exhausted"
        
        message = f"""
EC2 Instance Alert!

Instance ID: {instance['instance_id']}
Instance Name: {instance.get('instance_name', 'Unknown')}
Issues: {', '.join(instance['issues'])}

Current Resource Usage:
- CPU: {instance.get('cpu_usage', 'N/A'):.2f}%
- Memory: {instance.get('memory_usage', 'N/A'):.2f}%

Please investigate and take appropriate action.

Time: {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')} UTC
"""
        
        try:
            sns.publish(
                TopicArn=topic_arn,
                Message=message,
                Subject=subject
            )
            print(f"Notification sent for instance {instance['instance_id']}")
        except Exception as e:
            print(f"Error sending notification for instance {instance['instance_id']}: {str(e)}")

# Additional function to set up the Lambda with required configuration
def setup_lambda_configuration():
    """
    This is a helper function to understand the required configuration for the Lambda.
    You don't need to include this in your Lambda function.
    """
    configuration = {
        "runtime": "python3.9",
        "timeout": 300,  # 5 minutes
        "memory": 256,   # MB
        "environment_variables": {
            "SNS_TOPIC_ARN": "arn:aws:sns:region:account:topic"
        },
        "iam_role_permissions": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream", 
            "logs:PutLogEvents",
            "ec2:DescribeInstances",
            "cloudwatch:GetMetricStatistics",
            "sns:Publish"
        ]
    }
    return configuration