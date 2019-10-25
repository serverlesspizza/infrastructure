#!/bin/bash

function waitForStackCreateComplete() {
	echo "Waiting for stack $1 to update in $2 account...."
	aws cloudformation wait stack-update-complete --stack-name $1 --region $3 --profile $2

	if [ "$?" != "0" ]; then
		echo "ERROR: Stack $1 failed to create in $2 account"
		exit 1
	fi

	echo "Stack $1 created in $2 account."
}

# Added hosted zone IDs to SSM
aws ssm put-parameter --name hosted_zone_id --value Z05239482ED1LABEJRIRN --type String --overwrite --region us-east-1 --profile aws-serverlesspizza-nonprod
aws ssm put-parameter --name hosted_zone_id --value Z039670837H4PA0U0UPFC --type String --overwrite --region us-east-1 --profile aws-serverlesspizza-prod

# Create the certificate in us-east-1
aws cloudformation update-stack --stack-name 'serverlesspizza-certificate' \
	--template-body file://../cfn-certificate.yml \
	--region us-east-1 \
	--parameters ParameterKey=Environment,ParameterValue=dev \
	--capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
	--profile aws-serverlesspizza-nonprod

aws cloudformation update-stack --stack-name 'serverlesspizza-certificate' \
	--template-body file://../cfn-certificate.yml \
	--region us-east-1 \
	--parameters ParameterKey=Environment,ParameterValue=prod \
	--capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
	--profile aws-serverlesspizza-prod

waitForStackCreateComplete 'serverlesspizza-certificate' 'aws-serverlesspizza-nonprod' 'us-east-1'
waitForStackCreateComplete 'serverlesspizza-certificate' 'aws-serverlesspizza-prod' 'us-east-1'

DEV_CERTIFICATE_ARN=`aws cloudformation list-exports --query "Exports[?Name=='CertificateArn'].Value" --output text --profile aws-serverlesspizza-nonprod --region us-east-1`
PROD_CERTIFICATE_ARN=`aws cloudformation list-exports --query "Exports[?Name=='CertificateArn'].Value" --output text --profile aws-serverlesspizza-prod --region us-east-1`
aws ssm put-parameter --name certificate_arn --value $DEV_CERTIFICATE_ARN --type String --overwrite --region eu-west-1 --profile aws-serverlesspizza-nonprod
aws ssm put-parameter --name certificate_arn --value $PROD_CERTIFICATE_ARN --type String --overwrite --region eu-west-1 --profile aws-serverlesspizza-prod

# Create the pipeline
aws cloudformation update-stack --stack-name 'serverlesspizza-infrastructure-pipeline' \
	--template-body file://cfn_codepipeline.yml \
	--region eu-west-1 \
	--parameters ParameterKey=GitHubToken,ParameterValue=$AWS_GITHUB_TOKEN \
		ParameterKey=ModuleName,ParameterValue=infrastructure \
	--capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
	--profile aws-serverlesspizza-devops
