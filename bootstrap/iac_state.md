# Terraform Remote State on S3 - Manual Bootstrap

This documents the one-time bootstrap of a Terraform S3 backend using the AWS CLI.

The setup gives us:

- encrypted S3 state storage
- S3 versioning
- full public-access blocking
- HTTPS-only access
- native S3 state locking
- initial Terraform remote-state configuration

No DynamoDB table is used. Terraform's native S3 lock file is the current approach.

## Prerequisites

- AWS CLI v2 configured and authenticated
- Terraform 1.10+ for native S3 locking
- permissions to create and configure an S3 bucket

Check the current identity before doing anything:

```bash
aws sts get-caller-identity
```

Set the values used below:

```bash
export AWS_REGION="eu-north-1"
export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export STATE_BUCKET="tf-state-rafayel-task-${AWS_ACCOUNT_ID}-${AWS_REGION}"
```

The account ID is included because S3 bucket names are globally unique.

---

## 1. Create the state bucket


```bash
aws s3api create-bucket \
    --bucket "$STATE_BUCKET" \
    --region "$AWS_REGION" \
    --create-bucket-configuration LocationConstraint="$AWS_REGION"
```

Verify:

```bash
aws s3api head-bucket --bucket "$STATE_BUCKET"
```

No output means it worked.

---

## 2. Enable versioning

Terraform state is not something I want to trust to a single mutable object. Enable versioning so an older state can be recovered if somebody breaks or deletes the current one.

```bash
aws s3api put-bucket-versioning \
  --bucket "$STATE_BUCKET" \
  --versioning-configuration Status=Enabled
```

Verify:

```bash
aws s3api get-bucket-versioning \
  --bucket "$STATE_BUCKET"
```

Expected:

```json
{
  "Status": "Enabled"
}
```

---

## 3. Configure encryption

S3 encrypts new objects with SSE-S3 by default anyway, but I prefer making the backend requirement explicit instead of relying on an AWS default.

```bash
aws s3api put-bucket-encryption \
  --bucket "$STATE_BUCKET" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

Verify:

```bash
aws s3api get-bucket-encryption \
  --bucket "$STATE_BUCKET"
```


---

## 4. Block public access


```bash
aws s3api put-public-access-block \
  --bucket "$STATE_BUCKET" \
  --public-access-block-configuration \
  'BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true'
```

Verify:

```bash
aws s3api get-public-access-block \
  --bucket "$STATE_BUCKET"
```

All four values should be `true`.

---

## 5. Require HTTPS

Block any S3 request that is not using TLS.

Create the bucket policy:

```bash
cat >/tmp/terraform-state-bucket-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${STATE_BUCKET}",
        "arn:aws:s3:::${STATE_BUCKET}/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
EOF
```

Apply it:

```bash
aws s3api put-bucket-policy \
  --bucket "$STATE_BUCKET" \
  --policy file:///tmp/terraform-state-bucket-policy.json
```

Verify:

```bash
aws s3api get-bucket-policy \
  --bucket "$STATE_BUCKET" \
  --query Policy \
  --output text
```

Clean up the temporary file:

```bash
rm -f /tmp/terraform-state-bucket-policy.json
```

---

## 6. Enable S3 state locking

There is nothing else to provision in AWS.

Enable locking in the backend configuration with:

```hcl
use_lockfile = true
```

The identity running Terraform needs:

- `s3:ListBucket` on the bucket
- `s3:GetObject` and `s3:PutObject` on the state object
- `s3:GetObject`, `s3:PutObject`, and `s3:DeleteObject` on the `.tflock` object


---

## 7. Configure the Terraform backend

Add this to the Terraform root module, normally in `backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket               = "BUCKET_NAME"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "environments"
    region               = "eu-north-1"
    encrypt              = true
    use_lockfile         = true
  }
}
```
