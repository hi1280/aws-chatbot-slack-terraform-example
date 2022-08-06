terraform {
  backend "s3" {
    bucket = "hi1280-tfstate-main"
    key    = "aws-chatbot.tfstate"
    region = "ap-northeast-1"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.25.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "0.29.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "ap-northeast-1"
}

provider "awscc" {
  region = "ap-northeast-1"
}

locals {
  readonly_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "awscc_chatbot_slack_channel_configuration" "example" {
  configuration_name = "example"
  iam_role_arn       = aws_iam_role.chatbot.arn
  slack_channel_id   = "example"
  slack_workspace_id = "XXXXXXXXX"
  guardrail_policies = [
    aws_iam_policy.chatbot.arn,
    local.readonly_policy_arn
  ]
  sns_topic_arns = [aws_sns_topic.chatbot.arn]
}

resource "aws_iam_role" "chatbot" {
  name = "AWSChatbot-Role"

  assume_role_policy = <<-EOS
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "chatbot.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOS
}

resource "aws_iam_policy" "chatbot" {
  name   = "chatbot"
  policy = file("./iam/chatbot.json")
}

resource "aws_iam_role_policy_attachment" "chatbot" {
  policy_arn = aws_iam_policy.chatbot.arn
  role       = aws_iam_role.chatbot.name
}

resource "aws_iam_role_policy_attachment" "chatbot_readonly" {
  policy_arn = local.readonly_policy_arn
  role       = aws_iam_role.chatbot.name
}

resource "aws_sns_topic" "chatbot" {
  name = "chatbot"
}