data "aws_ssoadmin_instances" "aws_account_sso" {
}

data "archive_file" "lambda_function_code" {
  type        = "zip"
  source_dir  = "${path.module}/attach_pb_to_ps_lambda"
  output_path = "${random_uuid.lambda_pb_src_hash.result}.zip"
  depends_on = [
    null_resource.install_pip_packages
  ]
  excludes = [
    "__pycache__",
    "venv",
  ]
}

resource "aws_lambda_function" "attach_pb_to_ps" {
  filename         = data.archive_file.lambda_function_code.output_path
  function_name    = "attach_pb_to_ps"
  role             = aws_iam_role.lambda_function_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.lambda_function_code.output_base64sha256
  memory_size      = 128
  timeout          = 60
  environment {
    variables = {
      instance_arn        = tolist(data.aws_ssoadmin_instances.aws_account_sso.arns)[0]
      permission_boundary = var.permission_boundary_name
    }
  }
}

locals {
  lambda_function_directory = "${path.module}/attach_pb_to_ps_lambda"
  requirements_file         = "${local.lambda_function_directory}/requirements.txt"
}

resource "null_resource" "install_pip_packages" {
  provisioner "local-exec" {
    command = "pip3 install -r ${local.requirements_file} -t ${local.lambda_function_directory}"
  }
  triggers = {
    dependencies_versions = filemd5(local.requirements_file)
    source_versions       = filemd5("${local.lambda_function_directory}/lambda_function.py")
  }
}

resource "random_uuid" "lambda_pb_src_hash" {
  keepers = {
    "lambda_function.py" = filemd5("${local.lambda_function_directory}/lambda_function.py")
    "requirements.txt"   = filemd5("${local.lambda_function_directory}/requirements.txt")
  }
}

data "aws_iam_policy_document" "lambda_function_trust_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "lambda_function_role" {
  name               = "attach_pb_to_ps"
  assume_role_policy = data.aws_iam_policy_document.lambda_function_trust_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_function_policy_attachment_basic_role" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_function_role.name
}
resource "aws_iam_role_policy_attachment" "lambda_function_policy_attachment_cf_acess" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchEventsFullAccess"
  role       = aws_iam_role.lambda_function_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_policy_attachment_ct_trail" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudTrail_FullAccess"
  role       = aws_iam_role.lambda_function_role.name
}

data "aws_iam_policy_document" "lambda_function_inline_policy" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "sso:AttachCustomerManagedPolicyReferenceToPermissionSet",
      "sso:DescribePermissionsPolicies",
      "sso:ListPermissionSets",
      "sso:PutPermissionsPolicy",
      "sso:PutPermissionsBoundaryToPermissionSet",
      "sso:DescribePermissionSetProvisioningStatus",
      "sso:DeletePermissionSet",
      "sso:DescribePermissionSet",
      "sso:GetPermissionSet",
      "sso:AttachManagedPolicyToPermissionSet",
      "sso:CreatePermissionSet",
      "sso:UpdatePermissionSet",
      "sso:GetPermissionsBoundaryForPermissionSet",
    ]
  }
}
resource "aws_iam_policy" "lambda_function_inline_policy" {
  name        = "lambda_function_inline_policy"
  description = "Inline policy for Lambda function"
  policy      = data.aws_iam_policy_document.lambda_function_inline_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_function_policy_attachment_inline_policy" {
  policy_arn = aws_iam_policy.lambda_function_inline_policy.arn
  role       = aws_iam_role.lambda_function_role.name
}
resource "aws_cloudwatch_event_rule" "attach_pb_to_ps" {
  name        = "attach_pb_to_ps"
  description = "Event Rule which will be triggered when the AWS SSO Permission Sets are created"
  event_pattern = jsonencode({
    source = [
      "aws.sso"
    ]
    detail-type = [
      "AWS API Call via CloudTrail"
    ]
    detail = {
      "eventSource" : ["sso.amazonaws.com"],
      "eventName" : ["CreatePermissionSet"]
    }
  })
}

resource "aws_cloudwatch_event_target" "detect_missing_pb_permissionsets" {
  rule = aws_cloudwatch_event_rule.attach_pb_to_ps.name
  arn  = aws_lambda_function.attach_pb_to_ps.arn
}


resource "aws_lambda_permission" "attach_pb_to_ps" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.attach_pb_to_ps.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.attach_pb_to_ps.arn
}
