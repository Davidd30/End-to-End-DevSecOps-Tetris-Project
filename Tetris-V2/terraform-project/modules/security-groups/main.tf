# 1. Security Group للـ Load Balancer (ALB)
resource "aws_security_group" "alb_sg" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = var.vpc_id

  # السماح بمرور الـ Web Traffic (HTTP) من أي مكان في العالم
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # السماح بخروج أي بيانات من الـ ALB (عشان يعرف يكلم الـ Nodes)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.cluster_name}-alb-sg" }
}

# 2. Security Group للـ Worker Nodes (العمال)
resource "aws_security_group" "nodes_sg" {
  name        = "${var.cluster_name}-nodes-sg"
  description = "Security group for all nodes in the cluster"
  vpc_id      = var.vpc_id

  # السحر هنا: بنسمح بالدخول "فقط" لو جاي من الـ Security Group بتاع الـ ALB
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # السماح للـ Nodes تكلم بعضها وتخرج تجيب صور من Docker Hub مثلاً
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-nodes-sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}