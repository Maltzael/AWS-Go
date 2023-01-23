resource "aws_docdb_subnet_group" "subnet_group_docDb" {
  subnet_ids = [for subnet in aws_subnet.private_subnet : subnet.id]
  tags = {
    Name =  "${local.vpc_name}-subnet-group-docDb"
  }
}

### DocumentDB deployment and vpc with subnets###
resource "aws_docdb_cluster" "docDb" {
  cluster_identifier      = local.clusterId
  engine                  = local.engineDocumentDb
  master_username         = local.userNameDocumentDb
  master_password         = local.passwordDocumentDb
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  skip_final_snapshot     = true
  db_subnet_group_name    = aws_docdb_subnet_group.subnet_group_docDb.name
  vpc_security_group_ids  = [aws_default_security_group.default_security_group.id]
}

resource "aws_docdb_cluster_instance" "cluster_instances" {
  count              = 1
  identifier         = "docdb-cluster-demo-${count.index}"
  cluster_identifier = aws_docdb_cluster.docDb.id
  instance_class     = "db.t3.medium"
}
