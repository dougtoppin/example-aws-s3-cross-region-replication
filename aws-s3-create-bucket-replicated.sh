#!/bin/sh

# exit on any error
set -e

# aws-s3-create-bucket-replicated.sh

# This is an example of how to create an AWS s3 bucket that is replicated to another region

# fail on any error
#set -e

usage() {
  echo "Usage $0 (create|delete) bucket-name [ aws-profile ]"
}

if test $# -lt 2
then
    usage
    exit 1
fi

AWSPROFILE=""

if test $# -eq 3
then
	# if a third argument was provided assume it is the aws profile to use for the operations
	AWSPROFILE=" --profile $3 "
	echo "using aws profile 3"
fi


# what to do
ACTION="$1"

# bucket name to be created, note that this will have source and destination regions suffixed to it
NAME=$2

# detination region to replicate to
REGIONDEST=us-west-1

# source region to create bucket to be replicated
REGIONSRC=us-east-1

NAMEDEST=$NAME-$REGIONDEST
NAMESRC=$NAME-$REGIONSRC

STACKMAIN=aws-s3-crr-primary
STACKREP=aws-s3-crr-dr

validate() {

  # always check for template validity before we do anything
  for i in $STACKMAIN.yaml $STACKREP.yaml
  do

    echo "validating $i"
    aws $AWSPROFILE cloudformation validate-template --template-body file://$i
    echo

	# cfn-lint (pip install cfn-lint) is a very good linter for templates,
	# if it is available then also run it
    if [ -x $(which cfn-lint) ]; then
    	echo "running cfn-lint"
    	cfn-lint $i
    else
    	echo "cfn-lint not found, continuing"
    fi

  done

}

create() {

  # user is responsible for ensuring that the buckets to be created do not already exist


  echo "creating replication bucket"

  # the destination region bucket must be created first
  aws  $AWSPROFILE cloudformation create-stack --stack-name $STACKREP \
      --template-body file://$STACKREP.yaml \
      --region "$REGIONDEST" \
      --parameters ParameterKey=NAME,ParameterValue="$NAMEDEST"

  STATUS=""

  while :; do
      if test "$STATUS" == "CREATE_COMPLETE"
      then
        break
      fi
      echo "checking status"
      STATUS=$(aws cloudformation describe-stacks --stack-name $STACKREP --query Stacks[].StackStatus --output text --region $REGIONDEST)
      sleep 5
  done

  echo "creating primary bucket"

  aws $AWSPROFILE  cloudformation create-stack --stack-name $STACKMAIN --template-body file://$STACKMAIN.yaml \
      --region $REGIONSRC \
      --capabilities CAPABILITY_NAMED_IAM \
      --parameters ParameterKey=NAME,ParameterValue="$NAME" ParameterKey=REGIONDEST,ParameterValue="$REGIONDEST"


}

delete() {

    # user is responsible for ensuring that the buckets to be deleted have already been emptied

    echo "deleting stack $STACKMAIN"
    aws $AWSPROFILE cloudformation delete-stack --stack-name $STACKMAIN --region $REGIONSRC

    sleep 5

    echo "deleting stack $STACKREP"
    aws $AWSPROFILE cloudformation delete-stack --stack-name $STACKREP --region $REGIONDEST


}

validate

case "$ACTION" in
  create)
    create $NAME
    ;;

  delete)
    delete
    ;;

  *)
    usage
    exit 1
  ;;

esac
