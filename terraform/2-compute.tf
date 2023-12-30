locals {
  instances = {
    cp = {
      ami           = data.aws_ami.ubuntu.id
      instance_type = "t4g.small"
    }
    worker1 = {
      ami           = data.aws_ami.ubuntu.id
      instance_type = "t4g.small"
    }
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  owners = ["099720109477"]
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_security_group" "node" {
  name        = "cluster-node-security-group"
  description = "Allow traffic to nodes"

  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096

  provisioner "local-exec" {
    when    = create
    command = "rm -f ${path.module}/externals/cp.pem && echo -n '${tls_private_key.pk.private_key_pem}' > ${path.module}/externals/cp.pem && chmod 0600 ${path.module}/externals/cp.pem"
  }
}

resource "aws_key_pair" "cp" {
  key_name   = "cp"
  public_key = tls_private_key.pk.public_key_openssh
}

resource "aws_instance" "this" {
  for_each = local.instances

  ami           = each.value.ami
  instance_type = each.value.instance_type

  security_groups = [aws_security_group.node.id]
  subnet_id       = aws_subnet.public.id

  associate_public_ip_address = true

  key_name = aws_key_pair.cp.key_name

  user_data = <<EOF
# Install prerequisites for ansible
sudo apt-get update && sudo apt-get install -y python3-pip
EOF

  tags = {
    Name = each.key
  }
}

resource "null_resource" "delete_known_hosts" {
  triggers = {
    instances = join(",", [for instance in aws_instance.this : instance.public_ip])
  }

  provisioner "local-exec" {
      command = "rm -f ${path.module}/externals/known_hosts"
  }
}

resource "null_resource" "add_known_hosts" {
  depends_on = [null_resource.delete_known_hosts]

  triggers = {
    instances = join(",", [for instance in aws_instance.this : instance.public_ip])
  }

  for_each = aws_instance.this

  provisioner "local-exec" {
    command     = "sleep 30; ssh-keyscan ${aws_instance.this[each.key].public_ip} >> ${path.module}/externals/known_hosts"
  }
}
