#!/bin/bash
exec > aws-dump.txt 2>&1
set -e
export AWS_PROFILE=conducky-pulumi

echo "=== ECS Clusters ==="
aws ecs list-clusters

CLUSTER_ARN=$(aws ecs list-clusters --query 'clusterArns[0]' --output text)
echo "Using ECS Cluster: $CLUSTER_ARN"

echo "=== ECS Services ==="
aws ecs list-services --cluster "$CLUSTER_ARN"

SERVICE_ARN=$(aws ecs list-services --cluster "$CLUSTER_ARN" --query 'serviceArns[0]' --output text)
echo "Using ECS Service: $SERVICE_ARN"

echo "=== ECS Service Description ==="
aws ecs describe-services --cluster "$CLUSTER_ARN" --services "$SERVICE_ARN"

echo "=== ECS Tasks ==="
TASK_ARN=$(aws ecs list-tasks --cluster "$CLUSTER_ARN" --service-name "$SERVICE_ARN" --query 'taskArns[0]' --output text)
aws ecs describe-tasks --cluster "$CLUSTER_ARN" --tasks "$TASK_ARN"

echo "=== Load Balancers ==="
aws elbv2 describe-load-balancers

ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[0].LoadBalancerArn' --output text)
echo "Using ALB: $ALB_ARN"

echo "=== Target Groups ==="
aws elbv2 describe-target-groups --load-balancer-arn "$ALB_ARN"

TG_ARN=$(aws elbv2 describe-target-groups --load-balancer-arn "$ALB_ARN" --query 'TargetGroups[0].TargetGroupArn' --output text)
echo "Using Target Group: $TG_ARN"

echo "=== Target Health ==="
aws elbv2 describe-target-health --target-group-arn "$TG_ARN"

echo "=== Security Groups for ALB ==="
SG_ID=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[0].SecurityGroups[0]' --output text)
aws ec2 describe-security-groups --group-ids "$SG_ID"

echo "=== CloudWatch Log Groups ==="
aws logs describe-log-groups --log-group-name-prefix conducky

echo "=== Route Tables for VPC ==="
VPC_ID=$(aws ec2 describe-vpcs --query 'Vpcs[0].VpcId' --output text)
aws ec2 describe-route-tables --filters Name=vpc-id,Values="$VPC_ID"

echo "=== Done ==="