## Creating an AWS S3 bucket with replication to another region using CloudFormation

AWS S3 buckets can be configured to replicate all objects put in them to another bucket in a different region.
This is called ```Cross Region Replication```.

Why this is useful is that objects stored in a bucket are kept only in the region that they were created in.
Other regions may be able to access them if allowed but if a regional outage were to occur the contents of the buckets in that region may not be accessible.

Note that because S3 buckets have a global namespace it is not possible to have a bucket with the same name in 2 different regions.

Because of this it is useful to name a bucket with a suffix of the region that the bucket was created in.
Doing that allows you to have uniquely named buckets that differ in name by only the region making the functions accessing the contents easier to write a manage.

This is an example of using CloudFormation to create both a bucket to store objects in and a bucket to replicate those objects to.
The CloudFormation stacks will be called ```aws-s3-crr-primary``` and ```aws-s3-crr-dr```.
Because the stack names are fixed you cannot use this script as is to create multiple buckets.
To do that change the script to use unique names for each stack.

The regions to use are also set the script to us-east-1 for the primary and us-west-1 for the replica.

The contents of this repository consists of a shell script to create and delete the buckets and the 2 CloudFormation templates to define how to create the buckets.

* aws-s3-create-bucket-replicated.sh - shell script to create the CloudFormation stacks
* aws-s3-crr-primary.yaml - primary bucket definition
* aws-s3-crr-dr.yaml - replica bucket definition

Note that that to enable the automatic copying of bucket contents a policy and role are attached to the source bucket.
Both buckets must also have versioning enabled.
Both buckets also have encryption enabled as an example.

The replica bucket stack, defined by aws-s3-crr-dr.yaml, only requires that versioning be enabled.
Other than that it is entirely normal.

To get started run the script with a create argument and the name of a bucket to create.
This will create the replication bucket in another region and suffix the region name to the bucket.
When that operation has completed the main bucket will be created again with the region name suffixed.

Example:

```
$ ./aws-s3-create-bucket-replicated.sh create my-unique-bucket-01
validating aws-s3-crr-primary.yaml
{
    "CapabilitiesReason": "The following resource(s) require capabilities: [AWS::IAM::Role]",
    "Description": "s3 crr testing\n",
    "Parameters": [
        {
            "NoEcho": false,
            "ParameterKey": "REGIONDEST"
        },
        {
            "NoEcho": false,
            "ParameterKey": "NAME"
        }
    ],
    "Capabilities": [
        "CAPABILITY_IAM"
    ]
}

validating aws-s3-crr-dr.yaml
{
    "Description": "Create a simple encrypted S3 bucket and suffix the region to the name\n",
    "Parameters": [
        {
            "NoEcho": false,
            "ParameterKey": "NAME"
        }
    ]
}

creating replication bucket
{
    "StackId": "arn:aws:cloudformation:us-west-1:xxx:stack/aws-s3-crr-dr/2667dbb0-6cf8-11e8-9a36-500cc17864e6"
}
checking status
checking status
checking status
checking status
checking status
checking status
checking status
creating primary bucket
{
    "StackId": "arn:aws:cloudformation:us-east-1:xxx:stack/aws-s3-crr-primary/3fc1b9f0-6cf8-11e8-9fe0-500c2854b635"
}
```

After the CloudFormation stacks are successfully created any files copied to the source region bucket should automatically appear in the destination region bucket.

The script can also be run with a delete argument and will delete both stacks created which will cause the buckets created to be deleted as well.

Note, before trying to delete the CloudFormation stacks the bucket contents in both regions must be deleted.
This script does not do it itself so it must be done manually.

```
$ ./aws-s3-create-bucket-replicated.sh delete my-unique-bucket-01
validating aws-s3-crr-primary.yaml
{
    "CapabilitiesReason": "The following resource(s) require capabilities: [AWS::IAM::Role]",
    "Description": "s3 crr testing\n",
    "Parameters": [
        {
            "NoEcho": false,
            "ParameterKey": "REGIONDEST"
        },
        {
            "NoEcho": false,
            "ParameterKey": "NAME"
        }
    ],
    "Capabilities": [
        "CAPABILITY_IAM"
    ]
}

validating aws-s3-crr-dr.yaml
{
    "Description": "Create a simple encrypted S3 bucket and suffix the region to the name\n",
    "Parameters": [
        {
            "NoEcho": false,
            "ParameterKey": "NAME"
        }
    ]
}

deleting stack aws-s3-crr-primary
deleting stack aws-s3-crr-dr
```
