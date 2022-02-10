data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
        "edgelambda.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "edge_lambda_role" {
  name_prefix        = "edge_lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_lambda_function" "edge_lambda_request" {
  function_name = "wellcomeimages_edge_lambda_request"
  role          = aws_iam_role.edge_lambda_role.arn
  runtime       = "nodejs8.10"
  handler       = "edge_lambda_origin.handler"

  filename         = "../lambdas/edge_lambda_origin.zip"
  source_code_hash = filebase64sha256("../lambdas/edge_lambda_origin.zip")
  publish          = true
}
