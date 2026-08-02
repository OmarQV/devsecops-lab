terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "bucket_seguro" {
  bucket = "mi-bucket-devsecops-demo-12345"

  # La replicación entre regiones requiere un segundo bucket,
  # una segunda región y permisos IAM adicionales.
  # checkov:skip=CKV_AWS_144:La replicación multirregión está fuera del alcance del laboratorio local

  # Las notificaciones requieren un destino SNS, SQS o Lambda.
  # checkov:skip=CKV2_AWS_62:No existe un consumidor de eventos en esta demostración

  # El logging requiere un bucket independiente para almacenar registros.
  # checkov:skip=CKV_AWS_18:El destino centralizado de logs está fuera del alcance del laboratorio
}

# Bloquear completamente el acceso público.
resource "aws_s3_bucket_public_access_block" "bucket_seguro" {
  bucket = aws_s3_bucket.bucket_seguro.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Activar versionado.
resource "aws_s3_bucket_versioning" "bucket_seguro" {
  bucket = aws_s3_bucket.bucket_seguro.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Cifrar los objetos utilizando AWS KMS.
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_seguro" {
  bucket = aws_s3_bucket.bucket_seguro.id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = "alias/aws/s3"
    }
  }
}

# Configurar ciclo de vida para versiones antiguas
# y cargas multipart incompletas.
resource "aws_s3_bucket_lifecycle_configuration" "bucket_seguro" {
  bucket = aws_s3_bucket.bucket_seguro.id

  depends_on = [
    aws_s3_bucket_versioning.bucket_seguro
  ]

  rule {
    id     = "retencion-segura"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

resource "aws_security_group" "sg_seguro" {
  name        = "sg_ssh_restringido"
  description = "Permite SSH únicamente desde la red privada autorizada"

  # El laboratorio define la política de red, pero no crea una
  # instancia EC2 o interfaz de red a la cual asociarla.
  # checkov:skip=CKV2_AWS_5:Security Group de demostración sin recurso de cómputo

  ingress {
    description = "Acceso SSH desde la red privada corporativa"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}
