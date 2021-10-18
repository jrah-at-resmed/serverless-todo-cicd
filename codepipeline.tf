resource "aws_codestarconnections_connection" "cicd_pipeline" {
  name          = "serverless-todo-app"
  provider_type = "GitHub"
}

resource "aws_s3_bucket" "cicd_pipeline" {
  bucket_prefix = "serverless-todo-cicd-"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
}

resource "aws_iam_role" "cicd_pipeline" {
  name_prefix = "serverless-todo-cicd-"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17"
    "Statement" : [{
      "Effect" : "Allow"
      "Principal" : {
        "Service" : "codepipeline.amazonaws.com"
      },
      "Action" : "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cicd_pipeline" {
  name_prefix = "serverless-todo-cicd-"
  role        = aws_iam_role.cicd_pipeline.id

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

resource "aws_codepipeline" "main" {
  name     = "serverless-todo-cicd-pipeline"
  role_arn = aws_iam_role.cicd_pipeline.arn

  artifact_store {
    location = aws_s3_bucket.cicd_pipeline.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.cicd_pipeline.arn
        FullRepositoryId = "jrah-at-resmed/serverless-todo-app"
        BranchName       = "master"
        DetectChanges    = false
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = "serverless-todo-cicd-build"
      }
    }
  }
}
