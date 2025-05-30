resource "aws_security_group" "bastion" {
  name   = "${local.stack_name}_bastion"
  vpc_id = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "bastion_allow_jrasell_ssh" {
  security_group_id = aws_security_group.bastion.id
  cidr_ipv4         =  "81.152.169.68/32"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "bastion_egress_all_ipv4" {
  security_group_id = aws_security_group.bastion.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "bastion_egress_all_ipv6" {
  security_group_id = aws_security_group.bastion.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "nomad" {
  name   = "${local.stack_name}_nomad"
  vpc_id = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "nomad_allow_bastion_all" {
  security_group_id            = aws_security_group.nomad.id
  referenced_security_group_id = aws_security_group.bastion.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "nomad_allow_self_all" {
  security_group_id            = aws_security_group.nomad.id
  referenced_security_group_id = aws_security_group.nomad.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_egress_rule" "nomad_egress_all_ipv4" {
  security_group_id = aws_security_group.nomad.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "nomad_egress_all_ipv6" {
  security_group_id = aws_security_group.nomad.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
}
