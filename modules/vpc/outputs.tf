output "vpc_id" {
  value = aws_vpc.opsfleet_vpc.id
}

output "pub_1_id" {
  value = aws_subnet.pub_sub_1.id
}

output "pub_2_id" {
  value = aws_subnet.pub_sub_2.id
}

output "priv_1_id" {
  value = aws_subnet.priv_sub_1.id
}

output "priv_2_id" {
  value = aws_subnet.priv_sub_2.id
}

output "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  value       = [aws_subnet.pub_sub_1.id, aws_subnet.pub_sub_2.id, aws_subnet.priv_sub_1.id, aws_subnet.priv_sub_2.id]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs for the EKS node group"
  value       = [aws_subnet.priv_sub_1.id, aws_subnet.priv_sub_2.id]
}



