resource "aws_s3_object" "this_content" {
  for_each = {
    for path in fileset(var.content_path, "**") :
    path => path
  }

  bucket       = aws_s3_bucket.this_website.id
  key          = each.key
  source       = "${var.content_path}/${each.value}"
  etag         = filemd5("${var.content_path}/${each.value}")
  content_type = lookup(var.mime_types, regex("[^.]+$", each.key), "application/octet-stream")
}