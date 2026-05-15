resource "aws_dynamodb_table" "video_job_table" {
    name         = "video_job_table"
    billing_mode = "PAY_PER_REQUEST"
    hash_key     = "JobId"

    attribute {
        name = "JobId"
        type = "S"
    }

    tags = {
        Name = "video_job_table"
    }
}