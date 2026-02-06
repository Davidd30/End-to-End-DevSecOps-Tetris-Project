resource "aws_s3_bucket" "terraform_state" {
  bucket        = "beshoy-eks-state-unique-id" # غير الاسم ده لاسم فريد
  force_destroy = true # عشان لو حبيت تمسحها بعدين بسهولة
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}
