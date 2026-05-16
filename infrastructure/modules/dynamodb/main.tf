resource "aws_dynamodb_table" "video_job_table" {
    name         = "video_job_table"
    billing_mode = "PAY_PER_REQUEST"
    hash_key     = "JobId"

    attribute {
        name = "JobId"
        type = "S"
    }

    ttl {
      attribute_name = "TimeToExist"
      enabled        = true
    }

    tags = {
        Name = "video_job_table"
    }
}