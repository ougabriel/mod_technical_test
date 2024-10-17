output "cluster_id" {
  value = aws_eks_cluster.gab.id
}

output "node_group_id" {
  value = aws_eks_node_group.gab.id
}

output "vpc_id" {
  value = aws_vpc.gab_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.gab_subnet[*].id
}

##ec2

output "ec2_instance_ids" {
  description = "The IDs of the EC2 instances"
  value       = aws_instance.gab_ec2_instance[*].id
}

output "ec2_instance_public_ips" {
  description = "The public IPs of the EC2 instances"
  value       = aws_instance.gab_ec2_instance[*].public_ip
}

output "ec2_instance_private_ips" {
  description = "The private IPs of the EC2 instances"
  value       = aws_instance.gab_ec2_instance[*].private_ip
}

output "key_pair_name" {
  description = "The name of the EC2 key pair"
  value       = aws_key_pair.gab_key_pair.key_name
}
}
