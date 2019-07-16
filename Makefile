
# This file was heavily influenced by the AWS EKS Reference Architecture
# https://github.com/aws-samples/amazon-eks-refarch-cloudformation

CUSTOM_FILE ?= custom.mk
ifneq ("$(wildcard $(CUSTOM_FILE))","")
	include $(CUSTOM_FILE)
endif

ROOT ?= $(shell pwd)
AWS_ACCOUNT_ID := $(shell aws sts get-caller-identity --query 'Account' --output text)
CLUSTER_STACK_NAME ?= eks-ei-blog
CLUSTER_NAME ?= $(CLUSTER_STACK_NAME)
EKS_ADMIN_ROLE ?= arn:aws:iam::$(AWS_ACCOUNT_ID):role/EksEiBlogPostRole
REGION ?= 'us-east-1'
AZ_0 ?= 'us-east-1a'
AZ_1 ?= 'us-east-1b'
SSH_KEY_NAME ?= ''
USERNAME ?= $(shell aws sts get-caller-identity --output text --query 'Arn' | awk -F'/' '{print $2}')
EI_TYPE ?= 'eia1.medium'
NODE_INSTANCE_TYPE ?= 'm5.large'
INFERENCE_NODE_INSTANCE_TYPE ?= 'c5.large'
NODE_ASG_MIN ?= 1
NODE_ASG_MAX ?= 5
NODE_ASG_DESIRED ?= 2
INFERENCE_NODE_ASG_MAX ?= 6
INFERENCE_NODE_ASG_MIN ?= 2
INFERENCE_NODE_ASG_DESIRED ?= 2
NODE_VOLUME_SIZE ?= 100
INFERENCE_NODE_VOLUME_SIZE ?= 100
LAMBDA_CR_BUCKET_PREFIX ?= 'pub-cfn-cust-res-pocs'
DEFAULT_SQS_TASK_VISIBILITY ?= 7200
DEFAULT_SQS_TASK_COMPLETED_VISIBILITY ?= 500
INFERENCE_SCALE_PERIODS ?= 1
INFERENCE_SCALE_OUT_THRESHOLD ?= 2
INFERENCE_SCALE_IN_THRESHOLD ?= 2
INFERENCE_NODE_GROUP_NAME ?= 'inference'
NODE_GROUP_NAME ?= 'standard'
INFERENCE_BOOTSTRAP ?= --kubelet-extra-args --node-labels=inference=true,nodegroup=elastic-inference
BOOTSTRAP ?= --kubelet-extra-args --node-labels=inference=false,nodegroup=standard

ROLE_TRUST ?= '{ "Version": "2012-10-17", "Statement": [ { "Effect": "Allow", "Principal": { "Service": "cloudformation.amazonaws.com" }, "Action": "sts:AssumeRole" }, { "Effect": "Allow", "Principal": { "Service": "lambda.amazonaws.com" }, "Action": "sts:AssumeRole" } ] }'

.PHONY: create-role
create-role:
	@aws iam create-role --role-name EksEiBlogPostRole --assume-role-policy-document $(ROLE_TRUST) --output text --query 'Role.Arn'
	@aws iam attach-role-policy --role-name EksEiBlogPostRole --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

.PHONY: update-kubeconfig
update-kubeconfig:
	@aws eks update-kubeconfig --region $(REGION) --name $(CLUSTER_NAME)

.PHONY: deploy-daemonset
deploy-daemonset:
	@kubectl apply -f k8s-daemonset.yml

.PHONY: create-cluster
create-cluster:
	@aws --region $(REGION) cloudformation create-stack \
  --template-body file://stack.cfn.yml  \
  --stack-name  $(CLUSTER_STACK_NAME) \
  --role-arn $(EKS_ADMIN_ROLE) \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
  --parameters \
  ParameterKey=EksClusterName,ParameterValue="$(CLUSTER_NAME)" \
  ParameterKey=AvailabilityZone0,ParameterValue="$(AZ_0)" \
  ParameterKey=AvailabilityZone1,ParameterValue="$(AZ_1)" \
  ParameterKey=AdminUser,ParameterValue="$(USERNAME)" \
  ParameterKey=CreateRoleArn,ParameterValue="$(EKS_ADMIN_ROLE)" \
  ParameterKey=KeyName,ParameterValue="$(SSH_KEY_NAME)" \
  ParameterKey=InferenceNodeGroupName,ParameterValue="$(INFERENCE_NODE_GROUP_NAME)" \
  ParameterKey=InferenceBootstrapArguments,ParameterValue="'$(INFERENCE_BOOTSTRAP)'" \
  ParameterKey=BootstrapArguments,ParameterValue="'$(BOOTSTRAP)'" \
  ParameterKey=NodeGroupName,ParameterValue="$(NODE_GROUP_NAME)" \
  ParameterKey=NodeInstanceType,ParameterValue="$(NODE_INSTANCE_TYPE)" \
  ParameterKey=InferenceNodeInstanceType,ParameterValue="$(INFERENCE_NODE_INSTANCE_TYPE)" \
  ParameterKey=ElasticInferenceType,ParameterValue="$(EI_TYPE)" \
	ParameterKey=NodeAutoScalingGroupMinSize,ParameterValue="$(NODE_ASG_MIN)" \
 	ParameterKey=NodeAutoScalingGroupMaxSize,ParameterValue="$(NODE_ASG_MAX)" \
	ParameterKey=NodeAutoScalingGroupDesiredCapacity,ParameterValue="$(NODE_ASG_DESIRED)" \
  ParameterKey=InferenceNodeAutoScalingGroupMinSize,ParameterValue="$(INFERENCE_NODE_ASG_MIN)" \
  ParameterKey=InferenceNodeAutoScalingGroupMaxSize,ParameterValue="$(INFERENCE_NODE_ASG_MAX)" \
  ParameterKey=InferenceNodeAutoScalingGroupDesiredCapacity,ParameterValue="$(INFERENCE_NODE_ASG_DESIRED)" \
  ParameterKey=NodeVolumeSize,ParameterValue="$(NODE_VOLUME_SIZE)" \
  ParameterKey=InferenceNodeVolumeSize,ParameterValue="$(INFERENCE_NODE_VOLUME_SIZE)" \
  ParameterKey=LambdaCustomResourceBucketPrefix,ParameterValue="$(LAMBDA_CR_BUCKET_PREFIX)" \
  ParameterKey=DefaultTaskQueueVisibilityTimeout,ParameterValue="$(DEFAULT_SQS_TASK_VISIBILITY)" \
  ParameterKey=DefaultTaskCompletedQueueVisibilityTimeout,ParameterValue="$(DEFAULT_SQS_TASK_COMPLETED_VISIBILITY)" \
  ParameterKey=InferenceScaleEvaluationPeriods,ParameterValue="$(INFERENCE_SCALE_PERIODS)" \
  ParameterKey=InferenceQueueDepthScaleOutThreshold,ParameterValue="$(INFERENCE_SCALE_OUT_THRESHOLD)" \
	ParameterKey=InferenceQueueDepthScaleInThreshold,ParameterValue="$(INFERENCE_SCALE_IN_THRESHOLD)"
	@echo open "https://console.aws.amazon.com/cloudformation/home?region=$(REGION)#/stacks to see the details"

