resource "aws_vpc" "vera_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "vera_gw" {
  vpc_id = aws_vpc.vera_vpc.id

  tags = {
    Name = "${var.project_name}-gw"
  }
}


resource "aws_nat_gateway" "vera_nat_gateway" {
  subnet_id     = aws_subnet.vera_pub_subnet.id
  allocation_id = aws_eip.nat.id
  tags = {
    Name = "${var.project_name}-nat-gw"
  }
}


resource "aws_subnet" "vera_pub_subnet" {
  vpc_id                  = aws_vpc.vera_vpc.id
  cidr_block              = var.public_subnet_cidrs
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-pub-subnet"
  }
}

resource "aws_subnet" "vera_pvt_subnet_1" {
  vpc_id                  = aws_vpc.vera_vpc.id
  cidr_block              = var.private_subnet_1_cidrs
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-pvt-subnet-1"
  }
}

resource "aws_subnet" "vera_pvt_subnet_2" {
  vpc_id                  = aws_vpc.vera_vpc.id
  cidr_block              = var.private_subnet_2_cidrs
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-pvt-subnet-2"
  }
}

resource "aws_route_table" "vera_pub_route_table" {
  vpc_id = aws_vpc.vera_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vera_gw.id
  }

  tags = {
    Name = "${var.project_name}-pub-route-table"
  }
}

resource "aws_route_table" "vera_pvt_route_table" {
  vpc_id = aws_vpc.vera_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.vera_nat_gateway.id
  }

  tags = {
    Name = "${var.project_name}-pvt-route-table"
  }
}



resource "aws_route_table_association" "vera_pub_route_table" {
  subnet_id      = aws_subnet.vera_pub_subnet.id
  route_table_id = aws_route_table.vera_pub_route_table.id
}

resource "aws_route_table_association" "vera_pvt_route_table" {
  subnet_id      = aws_subnet.vera_pvt_subnet_1.id
  route_table_id = aws_route_table.vera_pvt_route_table.id
}

resource "aws_route_table_association" "vera_pvt_route_table_2" {
  subnet_id      = aws_subnet.vera_pvt_subnet_2.id
  route_table_id = aws_route_table.vera_pvt_route_table.id
}




resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}


resource "aws_security_group" "allow_ssh" {
  name        = "${var.project_name}-allow-ssh"
  description = "Allow SSH access to the instance"
  vpc_id      = aws_vpc.vera_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-allow-ssh"
  }
}

resource "aws_security_group" "frontend_web_sg" {
  name        = "${var.project_name}-frontend-web-sg"
  description = "Allow HTTP and HTTPS access to the instance"
  vpc_id      = aws_vpc.vera_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.allow_ssh.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-frontend-web-sg"
  }
}

resource "aws_security_group" "backend_web_sg" {
  name        = "${var.project_name}-backend-web-sg"
  description = "Allow HTTP and HTTPS access to the instance from frontend web sg"
  vpc_id      = aws_vpc.vera_vpc.id

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_web_sg.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.allow_ssh.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-backend-web-sg"
  }
}


resource "aws_security_group" "database_sg" {
  name        = "${var.project_name}-database-sg"
  description = "Allow access to the database from backend web sg"
  vpc_id      = aws_vpc.vera_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_web_sg.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.allow_ssh.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-database-sg"
  }
}


resource "aws_instance" "bastion_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.vera_pub_subnet.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "${var.project_name}-bastion-instance"
    Role = "bastion"
  }
}


resource "aws_instance" "frontend_web_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.vera_pub_subnet.id
  vpc_security_group_ids = [aws_security_group.frontend_web_sg.id]

  tags = {
    Name = "${var.project_name}-frontend-web-instance"
    Role = "nginx"
  }
}

resource "aws_instance" "backend_web_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.vera_pvt_subnet_1.id
  vpc_security_group_ids = [aws_security_group.backend_web_sg.id]

  tags = {
    Name = "${var.project_name}-backend-web-instance"
    Role = "django"
  }
}

resource "aws_instance" "database_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.vera_pvt_subnet_2.id
  vpc_security_group_ids = [aws_security_group.database_sg.id]

  tags = {
    Name = "${var.project_name}-database-instance"
    Role = "postgresql"
  }
}


