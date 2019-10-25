#!/bin/bash

aws cloudformation delete-stack \
    --stack-name 'serverlesspizza-infrastructure-pipeline' \
    --region eu-west-1 \
    --profile aws-serverlesspizza-devops

aws cloudformation delete-stack \
    --stack-name 'serverlesspizza-certificate' \
    --region us-east-1 \
    --profile aws-serverlesspizza-nonprod

aws cloudformation delete-stack \
    --stack-name 'serverlesspizza-certificate' \
    --region us-east-1 \
    --profile aws-serverlesspizza-prod
