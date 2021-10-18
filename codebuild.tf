resource "aws_iam_role" "cicd_source" {
  name_prefix = "serverless-todo-cicd-source-"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17"
      "Statement" : [
        {
          "Effect" : "Allow"
          "Principal" : {
            "Service" : "codebuild.amazonaws.com"
          },
          "Action" : "sts:AssumeRole"
        }
      ]
  })
}

resource "aws_iam_role_policy" "cicd_source" {
  name_prefix = "serverless-todo-cicd-source-"
  role        = aws_iam_role.cicd_source.id

  policy = jsonencode({
    "Version" : "2012-10-17"
    "Statement" : [
      {
        "Action" : "*"
        "Resource" : "*"
        "Effect" : "Allow"
      }
    ]
  })
}

resource "aws_codebuild_project" "source" {
  name         = "serverless-todo-cicd-build"
  service_role = aws_iam_role.cicd_source.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    type         = "LINUX_CONTAINER"
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
  }

  source {
    type = "CODEPIPELINE"
  }
}
