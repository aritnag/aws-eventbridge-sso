# General

This is an demostration of Attaching custom policies AWS SSO Permission Sets using AWS Event Bridge and AWS Lambda.

## Tech Stacks

- AWS Components
  - AWS SSO to enable governance inside the account
  - AWS Eventbridge to trigger rule based on the implementation
  - AWS Cloudtrail to monitor API calls within the AWS account
- IaaC ( Terraform)

### Solution Design

- Solution Design of the Construct: ![Alt text](solution_design/AWS_EventBridge.png?raw=true "AWS_EventBridge")


### Replace the following values

- AWS Account ID
- AWS Permission boundary name

