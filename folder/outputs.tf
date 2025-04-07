output "public_ec2_ip" {
  description = "public_ec2_ip"
   value = aws_instance.apache_server_1.public_ip
  
}

output "private_ec2_ip" {
  description = "private_ec2_ip"
   value = aws_instance.apache_server_2.private_ip
  
}