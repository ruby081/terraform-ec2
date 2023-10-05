output "aws_instance" {
  value = aws_instance.server-instance.public_ip
}
/*
output "aws_ami" {
  value = data.aws_ami.latest-aws-linux-image
}
*/
