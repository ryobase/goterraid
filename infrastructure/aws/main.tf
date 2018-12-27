provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
	region = "${var.region}"
}


# IAM
# =====================================================================================
resource "aws_iam_role" "terra_id_lambda" {
  name = "terra_id_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "terra_id_dynamodb" {
    name        = "terra_id_dynamodb"
    description = "Grants access to all tables prefixed by terra_id_*"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:BatchGetItem",
                "dynamodb:BatchWriteItem",
                "dynamodb:DeleteItem",
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:Query",
                "dynamodb:UpdateItem"
            ],
            "Resource": [
                "arn:aws:dynamodb:*:*:table/terra_id_*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy" "terra_id_cloudwatch_log" {
  name = "terra_id_cloudwatch_log"
  description = "Grant Lambda access to Cloudwatch Log"
  path = "/"

  policy =<<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}



# Policy attachments
# =====================================================================================
resource "aws_iam_role_policy_attachment" "terra_id_role_attachment_1" {
  role = "${aws_iam_role.terra_id_lambda.name}"
  policy_arn = "${aws_iam_policy.terra_id_dynamodb.arn}"
}

resource "aws_iam_role_policy_attachment" "terra_id_role_attachment_2" {
  role = "${aws_iam_role.terra_id_lambda.name}"
  policy_arn = "${aws_iam_policy.terra_id_cloudwatch_log.arn}"
}



# Lambda
# =====================================================================================
resource "aws_lambda_function" "go_terra_id" {
  filename         = "../deploy/function.zip"
  function_name    = "GoTerraId"
  role             = "${aws_iam_role.terra_id_lambda.arn}"
  handler          = "bin/goterraid"
  source_code_hash = "${base64sha256(file("../deploy/function.zip"))}"
  runtime          = "go1.x"
  memory_size      = 128
  timeout = 30

  environment {
    variables = {
      TABLE_NAME = "${var.dynamodb_table_name}"
      DEBUG = "${var.debug_mode}"
    }
  }
}

resource "aws_lambda_permission" "aptgw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.go_terra_id.arn}"
  principal     = "apigateway.amazonaws.com"

  # The /*/*/* part allows invocation from any stage, method and resource path
  # within API Gateway REST API.
  source_arn    = "${aws_api_gateway_deployment.go_terra_id.execution_arn}/*/*"
}


# API Gateway
# =====================================================================================
resource "aws_api_gateway_rest_api" "go_terra_id_api" {
  name = "GoTerraIdApi"
  description = "This is an API for calling Lambda"
}

resource "aws_api_gateway_resource" "service" {
  path_part = "service"
  parent_id = "${aws_api_gateway_rest_api.go_terra_id_api.root_resource_id}"
  rest_api_id = "${aws_api_gateway_rest_api.go_terra_id_api.id}"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = "${aws_api_gateway_rest_api.go_terra_id_api.id}"
  resource_id   = "${aws_api_gateway_resource.service.id}"
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = "${aws_api_gateway_rest_api.go_terra_id_api.id}"
  resource_id = "${aws_api_gateway_resource.service.id}"
  http_method = "${aws_api_gateway_method.method.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.go_terra_id.invoke_arn}"
}

resource "aws_api_gateway_method_response" "200" {
  rest_api_id = "${aws_api_gateway_rest_api.go_terra_id_api.id}"
  resource_id = "${aws_api_gateway_resource.service.id}"
  http_method = "${aws_api_gateway_method.method.http_method}"
  status_code = "200"
}

resource "aws_api_gateway_deployment" "go_terra_id" {
  depends_on = [
    "aws_api_gateway_integration.lambda_integration",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.go_terra_id_api.id}"
  stage_name  = "dev"
}


# DynamoDB
# =====================================================================================
resource "aws_dynamodb_table" "go_terra_id_table" {
  name = "${var.dynamodb_table_name}"
  read_capacity = 2
  write_capacity = 2
  hash_key = "id"
  range_key = "timestamp"

  attribute = [{
    name = "id"
    type = "S"
  },{
    name = "timestamp",
    type = "S"
  }]

  tags {
    Name = "${var.dynamodb_tag_name}"
    Environment = "${var.dynamodb_tag_env}"
  }
}
