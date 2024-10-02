resource "aws_sns_topic" "flyte_topic"{
   name = "${local.name_prefix}-topic"
     delivery_policy             = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF
  lifecycle {
    ignore_changes = [name, name_prefix]
  }
}

## SNS topic policy
resource "aws_sns_topic_policy" "default" {
  arn = aws_sns_topic.flyte_topic.arn

  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "__default_policy_ID"

  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    resources = [
      aws_sns_topic.flyte_topic.arn,
    ]

    sid = "__default_statement_ID"
  }
}
## SQS Subscriptions
resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.flyte_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.terraform_queue.arn
}

#----------------
# Configure an SQS queue
resource "aws_sqs_queue" "terraform_queue" {
  name = "${local.name_prefix}-queue"
}
 
 ## SQS Queue policy
resource "aws_sqs_queue_policy" "default" {

  policy    = data.aws_iam_policy_document.sqs_queue_policy.json
  queue_url = aws_sqs_queue.terraform_queue.id
}

data "aws_iam_policy_document" "sqs_queue_policy" {
  statement {
    actions = ["SQS:SendMessage"]
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    resources = [aws_sqs_queue.terraform_queue.arn]

    sid = "__default_statement_ID"
  }
   statement {
    # Accept the risk
    #tfsec:ignore:aws-sqs-no-wildcards-in-policy-documents
    actions = ["SQS:SendMessage"]
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    resources = [
      aws_sqs_queue.terraform_queue.arn,
    ]

    sid = "sns_access"
  }

  statement {
    # Accept the risk
    #tfsec:ignore:aws-sqs-no-wildcards-in-policy-documents
    actions = ["SQS:SendMessage"]
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [
      aws_sqs_queue.terraform_queue.arn,
    ]

    sid = "events_access"
  }
}
