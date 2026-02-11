# This block defines the version of TFLint itself
tflint {
  required_version = ">= 0.54.0"
}

config {
  # Inspects code inside local module folders
  call_module_type = "local"
  # Useful for local dev: formats output nicely in your VS Code terminal
  format = "compact"
}

# The Terraform plugin provides basic language rules (deprecated syntax, unused variables)
# It is now recommended to explicitly enable this.
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# AWS-specific rules for provider best practices
plugin "aws" {
  enabled = true
  version = "0.45.0" # Updated to latest stable 2026 version
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
