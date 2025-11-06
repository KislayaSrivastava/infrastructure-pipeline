# Development Environment - Main Configuration

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # Terraform Cloud backend configuration
  cloud {
    organization = "SKS-Infrastructure-Corporation"

    workspaces {
      name = "infrastructure-pipeline-dev"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repository  = "infrastructure-pipeline"
    }
  }
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Local variables
locals {
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project_name             = var.project_name
  environment              = var.environment
  vpc_cidr                 = var.vpc_cidr
  availability_zones       = local.availability_zones
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_subnet_cidrs     = var.private_subnet_cidrs
  enable_nat_gateway       = true
  enable_vpc_flow_logs     = true
  flow_logs_retention_days = 10

  tags = local.common_tags
}

# Compute Module
module "compute" {
  source = "../../modules/compute"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  ami_id             = data.aws_ami.amazon_linux.id
  instance_type      = var.instance_type
  min_size           = var.min_size
  max_size           = var.max_size
  desired_capacity   = var.desired_capacity
  health_check_path  = "/health"
  ssh_cidr_blocks    = [] # Empty for dev, restrict in production

  tags = local.common_tags

  depends_on = [module.vpc]
}

# Database Module
module "database" {
  source = "../../modules/database"

  project_name            = var.project_name
  environment             = var.environment
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  allowed_security_groups = [module.compute.ec2_security_group_id]
  db_name                 = var.db_name
  db_username             = var.db_username
  db_engine_version       = var.db_engine_version
  db_instance_class       = var.db_instance_class
  db_allocated_storage    = var.db_allocated_storage
  enable_multi_az         = false # Single AZ for dev
  backup_retention_period = 7

  tags = local.common_tags

  depends_on = [module.vpc]
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"

  project_name               = var.project_name
  environment                = var.environment
  aws_region                 = var.aws_region
  alarm_email_addresses      = var.alarm_email_addresses
  alb_arn_suffix             = split("/", module.compute.alb_arn)[1]
  target_group_arn_suffix    = split(":", module.compute.target_group_arn)[5]
  db_instance_id             = module.database.db_instance_id
  db_connections_threshold   = 50
  application_log_group_name = "/aws/application/${var.project_name}-${var.environment}"
  enable_cost_budget         = true
  monthly_budget_limit       = "50"

  tags = local.common_tags

  depends_on = [module.compute, module.database]
}
