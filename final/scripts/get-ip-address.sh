# Step 1 - gets the cluster arn using the cluster name
# aws ecs list-tasks --cluster backend_cluster_example_app | jq -r .taskArns[0]
task_arn=$(aws ecs list-tasks --cluster backend_cluster_example_app | jq -r .taskArns[0])

# Step 2 - Uses the taks arn (from above) to get the eni
# aws ecs describe-tasks --cluster backend_cluster_example_app --task arn:aws:ecs:us-east-1:041332443526:task/backend_cluster_example_app/dc11a8245e8f495488dfa7465b5305b5 | jq -r .tasks[0].attachments[0].details | jq -r '.[] | select(.name=="networkInterfaceId")'.value 
eni=$(aws ecs describe-tasks --cluster backend_cluster_example_app --task $task_arn | jq -r .tasks[0].attachments[0].details | jq -r '.[] | select(.name=="networkInterfaceId")'.value )

# Step 3 - Gets the specific network interface for the cluster task
# aws ec2 describe-network-interfaces --network-interface-ids eni-0d090ab283cdc010a | jq -r .NetworkInterfaces[0].Association.PublicIp
public_ip=$(aws ec2 describe-network-interfaces --network-interface-ids $eni | jq -r .NetworkInterfaces[0].Association.PublicIp)



echo "Fargate task[0] public ip address = http://${public_ip}"