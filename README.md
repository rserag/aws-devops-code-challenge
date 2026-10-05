# AWS Infrastructure — DevOps Code Challenge

This project implements Tasks 1 and 2 using a shared Terraform foundation in `eu-north-1`.

## Structure

```text
bootstrap/          Manual remote-state bootstrap instructions
modules/network/    VPC, subnet tiers, routing and VPC flow logs
modules/compute/    Private EC2, Systems Manager endpoints and IAM
modules/rds/        PostgreSQL RDS, database networking and credentials
modules/audit/      Account CloudTrail and unauthorized API alarm
workload/           Environment-specific infrastructure
account-security/   Shared account-level audit infrastructure
```

The workload root uses `stg` and `prod` workspaces. The account-security root uses the `default` workspace so that environments share one account-level trail.

## Prerequisites

- Terraform 1.10 or later, below 2.0.
- AWS CLI configured with an appropriate deployment identity.
- Permissions to provision the resources and access the remote state.
- An available Amazon Linux 2023 x86_64 AMI in `eu-north-1`.
- Root-account MFA enabled, no root access keys, and an administrative identity for routine work. These are account prerequisites and are not configured by this Terraform project.

Verify the deployment identity:

```bash
aws sts get-caller-identity
```

## Remote State and Locking

Follow `bootstrap/iac_state.md` to create the state bucket before initializing Terraform.

The state bucket uses encryption, versioning, public-access blocking and a policy requiring HTTPS. Both root modules use native S3 state locking.

Update the bucket name in both `backend.tf` files when deploying to another account.

State locations are:

```text
environments/stg/terraform.tfstate
environments/prod/terraform.tfstate
account-security/terraform.tfstate
```

The challenge explicitly requests DynamoDB locking. This implementation intentionally uses `use_lockfile = true` because HashiCorp has deprecated DynamoDB-based locking. This is a documented deviation from the requirement. See the [Terraform S3 backend documentation](https://developer.hashicorp.com/terraform/language/backend/s3).

State can contain sensitive information. Restrict access to the backend bucket.

## Deploy Shared Account Security

From the project directory:

```bash
cd account-security
terraform init
terraform workspace select default
terraform validate
terraform plan -out=account-security.tfplan
terraform apply account-security.tfplan
terraform output
```

Deploy this root once per account.

It creates a multi-region CloudTrail recording read and write management events, an encrypted log bucket, CloudWatch log delivery, and an alarm for denied API calls.

## Deploy Staging

From the project directory:

```bash
cd workload
terraform init
terraform workspace list
```

Create the workspace on the first deployment:

```bash
terraform workspace new stg
```

For subsequent deployments:

```bash
terraform workspace select stg
```

Set the pinned AMI in `stg.tfvars`, then run:

```bash
terraform fmt -check -recursive
terraform validate
terraform plan -var-file=stg.tfvars -out=stg.tfplan
terraform apply stg.tfplan
terraform output
```

Verify idempotence:

```bash
terraform plan -var-file=stg.tfvars
```

Expected result after a successful deployment: `No changes`.

The AMI is pinned to prevent image releases from causing unexpected EC2 replacements. Updating it is an explicit configuration change.

## Environments

The workload supports:

| Setting | Staging | Production |
| --- | --- | --- |
| VPC CIDR | `10.20.0.0/16` | `10.30.0.0/16` |
| RDS Multi-AZ | Disabled | Enabled |
| RDS backup retention | 1 day | 7 days |
| RDS deletion protection | Disabled | Enabled |
| Final RDS snapshot | Skipped | Required |
| VPC flow-log retention | 7 days | 30 days |

Only staging has been deployed and tested. Production configuration is provided but has not been deployed.

Before deploying production, prepare a `prod.tfvars` file with a suitable pinned AMI and explicitly select the `prod` workspace. Variable files must be supplied with `-var-file`; workspace selection does not load them automatically.

Workspaces separate resource state within the same AWS account. They do not provide account-level isolation.

## Network and Access Design

The VPC spans two Availability Zones and contains public, application and database subnet tiers.

Public subnets have a route to the internet gateway. Application and database subnets have no internet default route. Each private subnet has a separate route table to support future routing changes.

There is no NAT gateway. The private EC2 instance uses Systems Manager interface endpoints for management.

Security groups allow:

- EC2 outbound HTTPS to the Systems Manager endpoints.
- Endpoint inbound HTTPS from the EC2 security group.
- EC2 outbound PostgreSQL on port 5432 to the database security group.
- Database inbound PostgreSQL from the EC2 security group.

EC2 has no inbound security-group rules and no public IP. RDS is not publicly accessible.

## Security Controls

- EC2 uses an IAM role with the permissions needed for Session Manager.
- EC2 requires IMDSv2.
- EBS and RDS storage are encrypted.
- State and audit S3 buckets use encryption and block public access.
- The audit bucket uses versioning and disables ACLs.
- CloudTrail records management events across regions and enables log-file validation.
- VPC flow logs capture accepted and rejected traffic.
- RDS manages its master password through Secrets Manager; no database password is supplied in Terraform configuration.
- CloudWatch detects management-event errors matching `*UnauthorizedOperation` or `AccessDenied*`.

The alarm enters `ALARM` when at least one matching event occurs in a five-minute period. Notification destinations default to an empty list, so email or other notifications are not configured.

AWS Config, the remaining optional bonus, is not implemented. CloudTrail data-event logging is also outside this implementation.

## Outputs and Validation

Workload outputs include the VPC ID and CIDR, subnet IDs and CIDRs, EC2 private IP and DNS, RDS connection information and secret ARN, and the flow-log destination.

Account-security outputs include the trail ARN, audit bucket name, CloudWatch log group and alarm name.

Validation performed during staging testing:

- Terraform formatting and configuration validation passed.
- A subsequent workload plan reported no changes.
- Session Manager access to the private instance worked.
- EC2 could reach the RDS endpoint on port 5432.
- VPC flow-log records were observed.
- CloudTrail delivery and the unauthorized API alarm were verified.

The database connectivity check verified TCP reachability; it did not test SQL authentication or queries.

## Reusing the Modules

Modules accept inputs for resource names, network settings, instance configuration and tags. The workload root demonstrates their composition.

For another deployment, update backend bucket names, provider region, subnet Availability Zones, CIDRs and pinned AMIs as appropriate. Run `terraform init` separately in each root.

## Cleanup

To remove staging resources, select the staging workspace and review the destroy plan:

```bash
cd workload
terraform workspace select stg
terraform plan -destroy -var-file=stg.tfvars -out=stg-destroy.tfplan
terraform apply stg-destroy.tfplan
```

Account-security resources are shared. Remove them only when account audit logging is no longer needed.

The audit bucket has `force_destroy = false`. Terraform will refuse to delete it while object versions remain. If permanent deletion of the audit logs is intended, empty all object versions and delete markers before retrying the destroy.

Production RDS deletion requires disabling deletion protection through a reviewed configuration change and preserving the required final snapshot.

The manually bootstrapped state bucket is not removed by either Terraform root.