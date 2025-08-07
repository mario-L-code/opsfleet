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

output "private_subnets" {
  value = [
    aws_subnet.priv_sub_1.id,
    aws_subnet.priv_sub_2.id,
  ]
}

output "public_subnets" {
  value = [
    aws_subnet.pub_sub_1.id,
    aws_subnet.pub_sub_2.id,
  ]
}


# output "sg1_id" {
#   value = aws_security_group.opsfleet_sg.id
# }

# output "sg2_id" {
#   value = aws_security_group.opsfleet_sg_2.id
# }
