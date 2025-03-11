resource "aws_iam_role" "bountyhunter_task_execution_role" {
  name               = "BountyhunterTaskExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "bountyhunter_task_execution_policy" {
  name        = "BountyhunterTaskExecutionPolicy"
  description = "Policy to allow ECS tasks to access required AWS resources"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:CreateLogGroup",
        "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = [ 
          "${aws_cloudwatch_log_group.nmap_service_log_group.arn}:log-stream:*",
          "${aws_cloudwatch_log_group.dnsrecon_service_log_group.arn}:log-stream:*",
          "${aws_cloudwatch_log_group.ffuf_service_log_group.arn}:log-stream:*",
          "${aws_cloudwatch_log_group.whois_service_log_group.arn}:log-stream:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bountyhunter_task_execution_policy_attachment" {
  role       = aws_iam_role.bountyhunter_task_execution_role.name
  policy_arn = aws_iam_policy.bountyhunter_task_execution_policy.arn
}

resource "aws_iam_role" "bountyhunter_task_role" {
  name               = "BountyhunterTaskRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "bountyhunter_task_policy" {
  name        = "BountyhunterTaskPolicy"
  description = "Policy to allow ECS tasks to access required AWS resources"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::bounty-hunter",
          "arn:aws:s3:::bounty-hunter/*"
        ]
      },
      {
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Effect   = "Allow"
        Resource = [
          aws_sqs_queue.dnsrecon_queue.arn,
          aws_sqs_queue.ffuf_queue.arn,
          aws_sqs_queue.nmap_queue.arn,
          aws_sqs_queue.whois_queue.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bountyhunter_task_policy_attachment" {
  role       = aws_iam_role.bountyhunter_task_role.name
  policy_arn = aws_iam_policy.bountyhunter_task_policy.arn
}


resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}



resource "aws_iam_policy" "lambda_sqs_policy" {
  name   = "lambda_sqs_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "sqs:SendMessage",
          "sqs:SendMessageBatch"
        ],
        Resource = [ 
          aws_sqs_queue.dnsrecon_queue.arn,
          aws_sqs_queue.ffuf_queue.arn,
          aws_sqs_queue.nmap_queue.arn,
          aws_sqs_queue.whois_queue.arn
        ]
      },
      {
        Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:CreateLogGroup",
        "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = aws_cloudwatch_log_group.sqs_sender_log_group.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_attachment" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
}

resource "aws_iam_user" "api_user" {
  name = "api_caller_user"
}

resource "aws_iam_policy" "api_execution_policy" {
  name   = "api_invoke_policy"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "execute-api:Invoke",
            "Resource": "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_apigatewayv2_api.http_api.id}/*/*/*"
        }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "api_invoke_attachment" {
  user       = aws_iam_user.api_user.name
  policy_arn = aws_iam_policy.api_execution_policy.arn
}

resource "aws_iam_role" "api_gw_role" {
  name = "api_gw_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "api_gw_policy" {
  name        = "api_gw_policy"
  description = "Policy for API Gateway"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "${aws_cloudwatch_log_group.api_gw_logs.arn}:*"
    },
    {
      Effect   = "Allow"
      Action   = "lambda:InvokeFunction"
      Resource = aws_lambda_function.sqs_sender.arn
    }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_gw_attachment" {
  role       = aws_iam_role.api_gw_role.name
  policy_arn = aws_iam_policy.api_gw_policy.arn
}