resource "aws_db_subnet_group" "this" {
  name       = "technova-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, { Name = "technova-db-subnet-group" })
}

resource "aws_db_instance" "this" {
  identifier             = "technova-db"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp3"
  db_name                = "technova"
  username               = "postgres"
  password               = var.db_password
  port                   = 5432
  publicly_accessible    = false
  multi_az               = false
  storage_encrypted      = true
  skip_final_snapshot    = true
  deletion_protection    = false
  vpc_security_group_ids = [var.rds_security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.this.name

  tags = merge(var.tags, { Name = "technova-db" })
}
