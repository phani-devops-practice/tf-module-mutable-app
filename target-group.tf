resource "aws_lb_target_group" "target-group" {
  name     = "${var.COMPONENT}-${var.ENV}"
  port     = var.PORT
  protocol = "HTTP"
  vpc_id   = var.VPC_ID

  health_check {
    enabled              = true
    healthy_threshold    = 2
    unhealthy_threshold  = 2
    interval             = 6
    path                 = "/health"
    timeout              = 5
  }
}

resource "aws_lb_target_group_attachment" "attach" {
  count            = var.INSTANCE_COUNT
  target_group_arn = aws_lb_target_group.target-group.arn
  target_id        = aws_spot_instance_request.instance.*.spot_instance_id[count.index]
  port             = var.PORT
}

resource "aws_lb_listener" "frontend" {
  count             = var.LB_TYPE == "public" ? 1:0
  load_balancer_arn = var.LB_ARN
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-east-1:645019601948:certificate/58b6d583-1afa-4c0c-8914-5967c8be9fcd"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-group.arn
  }
}

resource "random_integer" "priority" {
  min = 1
  max = 50000
}

resource "aws_lb_listener_rule" "backend" {
  count        = var.LB_TYPE == "private" ? 1 : 0
  listener_arn = var.PRIVATE_LISTENER_ARN
  priority     = random_integer.priority.result

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-group.arn
  }

  condition {
    host_header {
      values = ["${var.COMPONENT}-${var.ENV}.roboshop.internal"]
    }
  }
}

