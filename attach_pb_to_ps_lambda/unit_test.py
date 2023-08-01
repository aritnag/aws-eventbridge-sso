import unittest
from unittest import mock
from unittest.mock import MagicMock
import os
from botocore.exceptions import ClientError


@mock.patch.dict(
    os.environ,
    {
        "instance_arn": "arn:aws:sso:::instance/ssoins-65084d522b795ab7",
        "permission_boundary": "PlaygrounTechPermissionBoundary",
    },
)
class TestLambdaHandler(unittest.TestCase):
    def test_os_environment(self):
        self.assertEqual(
            os.environ["instance_arn"], "arn:aws:sso:::instance/ssoins-65084d522b795ab7"
        )
        self.assertEqual(
            os.environ["permission_boundary"], "PlaygrounTechPermissionBoundary"
        )

    @mock.patch("boto3.client")
    def test_event_get_event_bridge_update_lambda_execution(self, mock_boto):
        _dir = "./events"
        events = [f for f in os.listdir(_dir) if os.path.isfile(os.path.join(_dir, f))]
        for file in events:
            with open(os.path.join(_dir, file), "r") as ofile:
                event = eval(ofile.read())

                context = MagicMock()

                instance_arn = event["detail"]["requestParameters"]["instanceArn"]
                permission_boundary_name = event["detail"]["responseElements"][
                    "permissionSet"
                ]["permissionSetArn"]
                # Mock boto3 SSO Admin client
                mock_sso_admin_client = mock.Mock()
                mock_boto.return_value.client.return_value = mock_sso_admin_client

                # Call the lambda_handler function with the mock event and context
                from lambda_function import (
                    lambda_handler,
                )

                with mock.patch.dict(
                    "os.environ",
                    {
                        "instance_arn": instance_arn,
                        "permission_boundary": permission_boundary_name,
                    },
                ):
                    response = lambda_handler(event, context)

                    mock_sso_admin_client.get_permissions_boundary_for_permission_set.return_value = {
                        "PermissionsBoundary": {
                            "PermissionsBoundaryType": "CUSTOMER_MANAGED",
                            "PermissionsBoundaryArn": "arn:aws:iam::123456789012:policy/BoundaryPolicy",
                        }
                    }
                    response = lambda_handler(event, None)
                    self.assertEqual(response["statusCode"], 200)
                    self.assertIn(
                        "Permission set Permission Boundary Implementation handled successfully",
                        response["body"],
                    )

                    # Test exception scenario
                    mock_sso_admin_client.get_permissions_boundary_for_permission_set.side_effect = ClientError(
                        {}, "ResourceNotFoundException"
                    )
                    response = lambda_handler(event, None)
                    self.assertEqual(response["statusCode"], 200)


if __name__ == "__main__":
    unittest.main()
