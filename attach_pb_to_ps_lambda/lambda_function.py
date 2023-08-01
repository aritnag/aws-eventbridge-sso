import json
import boto3
import os

sso_admin_client = boto3.client("sso-admin")
instance_arn = os.environ["instance_arn"]
permission_boundary_name = os.environ["permission_boundary"]


def lambda_handler(event, context):
    if (
        event["source"] == "aws.sso"
        and event["detail"]["eventName"] == "CreatePermissionSet"
    ):
        permission_set_name = event["detail"]["requestParameters"]["name"]
        try:
            permission_set_arn = event["detail"]["responseElements"]["permissionSet"][
                "permissionSetArn"
            ]
            if permission_set_arn is not None:
                sso_admin_client.get_permissions_boundary_for_permission_set(
                    InstanceArn=instance_arn,
                    PermissionSetArn=permission_set_arn,
                )
        except sso_admin_client.exceptions.ResourceNotFoundException:
            print(
                f"The permission set {permission_boundary_name} does not exist.We will attach it now."
            )
            # Attach the permission set details
            sso_admin_client.put_permissions_boundary_to_permission_set(
                InstanceArn=instance_arn,
                PermissionSetArn=permission_set_arn,
                PermissionsBoundary={
                    "CustomerManagedPolicyReference": {
                        "Name": permission_boundary_name,
                    }
                },
            )
        print(
            f"The permission boundary {permission_boundary_name} exists with the permission set {permission_set_name}."
        )
        return {
            "statusCode": 200,
            "body": json.dumps(
                "Permission set Permission Boundary Implementation handled successfully"
            ),
        }
