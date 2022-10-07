terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.30.0"
    }
  }
}

provider aws {
    region = "us-east-2"
}

resource "aws_security_group" "gophish-admin-sg" { # You can change this to be any port you want, just make sure you change the port in the jq command used in the userdata script.
  name = "gophish-admin-sg"
  ingress {
    from_port = 3333
    to_port = 3333
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # It is recommended that this is not public facing as this is the admin panel for the application! Also change the IP in the jq command used in userdata script.
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["127.0.0.1/32"] # SSH should never be open to the internet!!!! Add your public IP so that only divices from your network may connect.
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "gophish-listener-sg" {
  name = "gophish-listener-sg"
  vpc_id = "vpc-000f8a3563cd060fc"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "gophish-priv-key" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "gophish-key-pair" {
  key_name = "gophish-key"
  public_key = tls_private_key.gophish-priv-key.public_key_openssh

  provisioner "local-exec" {
    command = "echo \"${tls_private_key.gophish-priv-key.private_key_pem}\" > ./gophish-key.pem && chmod 400 gophish-key.pem"
  }
}

resource "aws_instance" "gophish-web" {
  ami = "ami-02f3416038bdb17fb"
  instance_type = "t2.medium"
  availability_zone = "us-east-2a"
  subnet_id = "" # Delete this to use the default AWS Subnet.
  security_groups = ["${aws_security_group.gophish-admin-sg.id}", "${aws_security_group.gophish-listener-sg.id}"]
  associate_public_ip_address = true
  metadata_options {
    http_endpoint = "enabled"
    http_tokens = "required"
  }
  key_name = aws_key_pair.gophish-key-pair.key_name
  user_data = <<-EOF
  #!/bin/bash
  sudo apt-get update && sudo apt-get upgrade -y
  sudo apt-get --assume-yes install unzip
  sudo apt-get --assume-yes install sqlite3
  sudo apt-get --assume-yes install jq
  cd /home/ubuntu
  wget https://github.com/gophish/gophish/releases/download/v0.12.1/gophish-v0.12.1-linux-64bit.zip
  unzip gophish-v0.12.1-linux-64bit.zip
  cd gophish-v0.12.1-linux-64bit
  sudo chmod +x gophish
  tmp=$(mktemp)
  jq '.admin_server.listen_url = "0.0.0.0:3333"' config.json > "$tmp" && mv "$tmp" config.json
  sudo ./gophish &
  disown %1
  EOF

  tags = {
    Name = "gophish-web"
  }
}