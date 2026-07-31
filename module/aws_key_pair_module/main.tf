resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = var.EC2_INSTANCE_PEM_FILE_NAME
  public_key = tls_private_key.key.public_key_openssh
  provisioner "local-exec" { # Create "myKey.pem" to your computer!!
    command = "pwd; echo '${tls_private_key.key.private_key_pem}' > ./${var.EC2_INSTANCE_PEM_FILE_NAME}.pem"
  }
  tags = var.tags
}