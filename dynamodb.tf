resource "aws_dynamodb_table" "plunder_guest_data" {
  name           = "PlunderCoveGuestData"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "GuestID"

  attribute {
    name = "GuestID"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = "PlunderCoveGuestData"
    Environment = "Production"
    Project     = "PlunderCove"
  }
}