resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  description = "Security group for ECS tasks in private subnet"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = []
  }
}

resource "aws_sqs_queue" "dnsrecon_queue" {
  name = "dnsrecon-queue"
}

resource "aws_sqs_queue" "ffuf_queue" {
  name = "ffuf-queue"
}

resource "aws_sqs_queue" "nmap_queue" {
  name = "nmap-queue"
}

resource "aws_sqs_queue" "whois_queue" {
  name = "whois-queue"
}

resource "aws_cloudwatch_log_group" "nmap_service_log_group" {
  name = "/bountyhunter/nmap-service"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "dnsrecon_service_log_group" {
  name = "/bountyhunter/dnsrecon-service"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "ffuf_service_log_group" {
  name = "/bountyhunter/ffuf-service"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "whois_service_log_group" {
  name = "/bountyhunter/whois-service"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "sqs_sender_log_group" {
  name = "/aws/lambda/sqs_sender"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "api_gw_logs" {
  name = "/aws/apigateway/http-api-bounty-hunter"
  retention_in_days = 7
}

resource "aws_ecs_cluster" "bountyhunter_cluster" {
  name = "bountyhunter-cluster"
}

resource "aws_ecs_task_definition" "bountyhunter_task" {
  family                   = "bountyhunter-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  task_role_arn            = aws_iam_role.bountyhunter_task_role.arn
  execution_role_arn       = aws_iam_role.bountyhunter_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "nmap-service"
      image = var.nmap_image
      environment = [
        {
          name  = "QUEUE_URL"
          value = aws_sqs_queue.nmap_queue.url
        },
        {
          name  = "AWS_REGION"
          value = var.region
        },
        {
          name  = "BUCKET_NAME"
          value = var.bucket_name
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.nmap_service_log_group.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "nmap-service"
        }
      }
    },
    {
      name  = "dnsrecon-service"
      image = var.dnsrecon_image
      environment = [
        {
          name  = "QUEUE_URL"
          value = aws_sqs_queue.dnsrecon_queue.name
        },
        {
          name  = "AWS_REGION"
          value = var.region
        },
        {
          name  = "BUCKET_NAME"
          value = var.bucket_name
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.dnsrecon_service_log_group.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "dnsrecon-service"
        }
      }
    },
    {
      name  = "ffuf-service"
      image = var.ffuf_image
      environment = [
        {
          name  = "QUEUE_URL"
          value = aws_sqs_queue.ffuf_queue.name
        },
        {
          name  = "AWS_REGION"
          value = var.region
        },
        {
          name  = "BUCKET_NAME"
          value = var.bucket_name
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ffuf_service_log_group.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ffuf-service"
        }
      }
    },
    {
      name  = "whois-service"
      image = var.whois_image
      environment = [
        {
          name  = "QUEUE_URL"
          value = aws_sqs_queue.whois_queue.name
        },
        {
          name  = "AWS_REGION"
          value = var.region
        },
        {
          name  = "BUCKET_NAME"
          value = var.bucket_name
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.whois_service_log_group.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "whois-service"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "bountyhunter_service" {
  name            = "bountyhunter-service"
  cluster         = aws_ecs_cluster.bountyhunter_cluster.id
  task_definition = aws_ecs_task_definition.bountyhunter_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.bountyhunter-private.id]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }
}

data "archive_file" "lambda_function" {
  type        = "zip"
  source_file  = "${path.cwd}/../api-backend/lambda_function.py"
  output_path = "${path.cwd}/lambda_function.zip"
}

resource "aws_lambda_function" "sqs_sender" {
  function_name    = "sqs_sender"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  role             = aws_iam_role.lambda_exec.arn
  filename         = "lambda_function.zip"
  timeout         = 15

  environment {
    variables = {
      QUEUE_URL_NMAP = aws_sqs_queue.nmap_queue.url,
      QUEUE_URL_DNSRECON = aws_sqs_queue.dnsrecon_queue.url,
      QUEUE_URL_FFUF = aws_sqs_queue.ffuf_queue.url,
      QUEUE_URL_WHOIS = aws_sqs_queue.whois_queue.url
    }
  }

  logging_config {
    log_group = aws_cloudwatch_log_group.sqs_sender_log_group.name
    log_format = "JSON"
  }

  depends_on = [data.archive_file.lambda_function, aws_cloudwatch_log_group.sqs_sender_log_group]
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = "http-api-bounty-hunter"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "stage_prod" {
  api_id = aws_apigatewayv2_api.http_api.id
  name   = "prod"
  deployment_id = aws_apigatewayv2_deployment.deployment.id

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw_logs.arn
    format          = jsonencode({
      requestId      = "$context.requestId"
      extendedRequestId = "$context.extendedRequestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      responseLength = "$context.responseLength"
      error          = "$context.error.message"
      integration_error = "$context.integrationErrorMessage"
    })
  }

}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.sqs_sender.invoke_arn
  credentials_arn = aws_iam_role.api_gw_role.arn
}

resource "aws_apigatewayv2_route" "lambda_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /scan"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
  authorization_type = "AWS_IAM"
}

resource "aws_apigatewayv2_deployment" "deployment" {
  api_id = aws_apigatewayv2_api.http_api.id

  depends_on = [ 
    aws_apigatewayv2_api.http_api,
    aws_apigatewayv2_route.lambda_route,
    aws_apigatewayv2_integration.lambda_integration,
  ]
}

resource "aws_lambda_permission" "api_gateway_lambda" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sqs_sender.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"

}