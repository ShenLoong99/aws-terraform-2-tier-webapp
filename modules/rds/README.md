<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_db_instance.mysql](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_subnet_group.rds_subnet_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allocated_storage"></a> [allocated\_storage](#input\_allocated\_storage) | The allocated storage in gigabytes | `number` | `20` | no |
| <a name="input_aws_db_subnet_group_name"></a> [aws\_db\_subnet\_group\_name](#input\_aws\_db\_subnet\_group\_name) | The name of the DB subnet group | `string` | `"main-rds-subnet-group"` | no |
| <a name="input_aws_db_subnet_group_tags"></a> [aws\_db\_subnet\_group\_tags](#input\_aws\_db\_subnet\_group\_tags) | Tags for the DB subnet group | `map(string)` | <pre>{<br/>  "Name": "My DB Subnet Group"<br/>}</pre> | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | The name of the database | `string` | `"webapp_2_tier_db"` | no |
| <a name="input_db_password"></a> [db\_password](#input\_db\_password) | The password for the database | `string` | n/a | yes |
| <a name="input_engine"></a> [engine](#input\_engine) | The database engine | `string` | `"mysql"` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | List of private subnet IDs | `list(string)` | n/a | yes |
| <a name="input_rds_sg_id"></a> [rds\_sg\_id](#input\_rds\_sg\_id) | The ID of the RDS security group | `string` | n/a | yes |
| <a name="input_username"></a> [username](#input\_username) | The username for the database | `string` | `"admin"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_db_host"></a> [db\_host](#output\_db\_host) | The connection endpoint for the database |
| <a name="output_db_instance_endpoint"></a> [db\_instance\_endpoint](#output\_db\_instance\_endpoint) | The connection endpoint for the RDS instance |
| <a name="output_db_name"></a> [db\_name](#output\_db\_name) | The name of the database |
| <a name="output_db_port"></a> [db\_port](#output\_db\_port) | The port for the database |
| <a name="output_db_username"></a> [db\_username](#output\_db\_username) | The master username for the database |
<!-- END_TF_DOCS -->