#!/bin/sh
# aws-s3-create-bucket-replicated.sh

# This is an example of how to create an AWS s3 bucket that is replicated to another region

# fail on any error
#set -e

usage() {
  echo "Usage $0 (create|delete) bucket-name"
}

if test $# -ne 2
then
    usage
    exit 1
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
    aws cloudformation validate-template --template-body file://$i
    echo

  done

}

create() {

  # user is responsible for ensuring that the buckets to be created do not already exist


  echo "creating replication bucket"

  # the destination region bucket must be created first
  aws cloudformation create-stack --stack-name $STACKREP \
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

  aws cloudformation create-stack --stack-name $STACKMAIN --template-body file://$STACKMAIN.yaml \
      --region $REGIONSRC \
      --capabilities CAPABILITY_NAMED_IAM \
      --parameters ParameterKey=NAME,ParameterValue="$NAME" ParameterKey=REGIONDEST,ParameterValue="$REGIONDEST"


}

delete() {

    # user is responsible for ensuring that the buckets to be deleted have already been emptied

    echo "deleting stack $STACKMAIN"
    aws cloudformation delete-stack --stack-name $STACKMAIN --region $REGIONSRC

    sleep 5

    echo "deleting stack $STACKREP"
    aws cloudformation delete-stack --stack-name $STACKREP --region $REGIONDEST


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
