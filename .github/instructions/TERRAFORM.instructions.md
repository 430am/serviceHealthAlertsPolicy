---
description: 'Create or modify solutions built using Terraform on Azure.'
applyTo: '**/*.terraform, **/*.tf, **/*.tfvars, **/*.tflint.hcl, **/*.tfstate, **/*.tf.json, **/*.tfvars.json'
---

# Azure Terraform Best Practices

## Integration and Self-Containment

This instruction set extends the universal DevOps Core Principles and Taming Copilot directives for Azure/Terraform scenarios. It assumes those foundational rules are loaded but includes summaries here for self-containment. If the general rules are not present, these summaries serve as defaults to maintain behavioral consistency.

### Incorporated DevOps Core Principles (CALMS Framework)

- **Culture**: Foster collaborative, blameless culture with shared responsibility and continuous learning.
- **Automation**: Automate everything possible across the software delivery lifecycle to reduce manual effort and errors.
- **Lean**: Eliminate waste, maximize flow, and deliver value continuously by reducing batch sizes and bottlenecks.
- **Measurement**: Measure everything relevant (e.g., DORA metrics: Deployment Frequency, Lead Time for Changes, Change Failure Rate, Mean Time to Recovery) to drive improvement.
- **Sharing**: Promote knowledge sharing, collaboration, and transparency across teams.

### Incorporated Taming Copilot Directives (Behavioral Hierarchy)

- **Primacy of User Directives**: Direct user commands take highest priority.
- **Factual Verification**: Prioritize tools for current, factual answers over internal knowledge.
- **Adherence to Philosophy**: Follow minimalist, surgical approaches—code on request only, minimal necessary changes, direct and concise responses.
- **Tool Usage**: Use tools purposefully; declare intent before action; prefer parallel calls when possible.

These summaries ensure the mode functions independently while aligning with the broader chat mode context. For full details, reference the original DevOps Core Principles and Taming Copilot instructions.

## Chat Mode Integration

When operating in chat mode with these instructions loaded:

- Treat this as a self-contained extension that incorporates summarized general rules for independent operation.
- Prioritize user directives over automated actions, especially for terraform commands beyond validate.
- Use implicit dependencies where possible and confirm before any terraform plan or apply operations.
- Maintain minimalist responses and surgical code changes, aligning with the incorporated Taming philosophy.
- **Planning Files Awareness**: Always check for planning files in the `.terraform-planning-files/` folder (if present). Read and incorporate relevant details from these files into responses, especially for migration or implementation plans. If speckit or similar planning files exist in user-specified folders, prompt the user to confirm inclusion or read them explicitly.


## Security

- Always use the latest stable version of Terraform and its providers.
  - Regularly update your Terraform configurations to incorporate security patches and improvements.
- Store sensitive information in a secure manner, such as using AWS Secrets Manager or SSM Parameter Store.
  - Regularly rotate credentials and secrets.
  - Automate the rotation of secrets, where possible.
- Use AWS environment variables to reference values stored in AWS Secrets Manager or SSM Parameter Store.
  - This keeps sensitive values out of your Terraform state files.
- Never commit sensitive information such as AWS credentials, API keys, passwords, certificates, or Terraform state to version control.
  - Use `.gitignore` to exclude files containing sensitive information from version control.
- Always mark sensitive variables as `sensitive = true` in your Terraform configurations.
  - This prevents sensitive values from being displayed in the Terraform plan or apply output.
- Use IAM roles and policies to control access to resources.
  - Follow the principle of least privilege when assigning permissions.
- Use security groups and network ACLs to control network access to resources.
- Deploy resources in private subnets whenever possible.
  - Use public subnets only for resources that require direct internet access, such as load balancers or NAT gateways.
- Use encryption for sensitive data at rest and in transit.
  - Enable encryption for EBS volumes, S3 buckets, and RDS instances.
  - Use TLS for communication between services.
- Regularly review and audit your Terraform configurations for security vulnerabilities.
  - Use tools like `trivy`, `tfsec`, or `checkov` to scan your Terraform configurations for security issues.

## Modularity

- Use separate projects for each major component of the infrastructure; this:
  - Reduces complexity
  - Makes it easier to manage and maintain configurations
  - Speeds up `plan` and `apply` operations
  - Allows for independent development and deployment of components
  - Reduces the risk of accidental changes to unrelated resources
- Use modules to avoid duplication of configurations.
  - Use modules to encapsulate related resources and configurations.
  - Use modules to simplify complex configurations and improve readability.
  - Avoid circular dependencies between modules.
  - Avoid unnecessary layers of abstraction; use modules only when they add value.
    - Avoid using modules for single resources; only use them for groups of related resources.
    - Avoid excessive nesting of modules; keep the module hierarchy shallow.
- Use `output` blocks to expose important information about your infrastructure.
  - Use outputs to provide information that is useful for other modules or for users of the configuration.
  - Avoid exposing sensitive information in outputs; mark outputs as `sensitive = true` if they contain sensitive data.

## Maintainability

- Prioritize readability, clarity, and maintainability.
- Use comments to explain complex configurations and why certain design decisions were made.
- Write concise, efficient, and idiomatic configs that are easy to understand.
- Avoid using hard-coded values; use variables for configuration instead.
  - Set default values for variables, where appropriate.
- Use data sources to retrieve information about existing resources instead of requiring manual configuration.
  - This reduces the risk of errors, ensures that configurations are always up-to-date, and allows configurations to adapt to different environments.
  - Avoid using data sources for resources that are created within the same configuration; use outputs instead.
  - Avoid, or remove, unnecessary data sources; they slow down `plan` and `apply` operations.
- Use `locals` for values that are used multiple times to ensure consistency.

## Style and Formatting

- Follow Terraform best practices for resource naming and organization.
  - Use descriptive names for resources, variables, and outputs.
  - Use consistent naming conventions across all configurations.
- Follow the **Terraform Style Guide** for formatting.
  - Use consistent indentation (2 spaces for each level).
- Group related resources together in the same file.
  - Use a consistent naming convention for resource groups (e.g., `providers.tf`, `variables.tf`, `network.tf`, `ecs.tf`, `mariadb.tf`).
- Place `depends_on` blocks at the very beginning of resource definitions to make dependency relationships clear.
  - Use `depends_on` only when necessary to avoid circular dependencies.
- Place `for_each` and `count` blocks at the beginning of resource definitions to clarify the resource's instantiation logic.
  - Use `for_each` for collections and `count` for numeric iterations.
  - Place them after `depends_on` blocks, if they are present.
- Place `lifecycle` blocks at the end of resource definitions.
- Alphabetize providers, variables, data sources, resources, and outputs within each file for easier navigation.
- Group related attributes together within blocks.
  - Place required attributes before optional ones, and comment each section accordingly.
  - Separate attribute sections with blank lines to improve readability.
  - Alphabetize attributes within each section for easier navigation.
- Use blank lines to separate logical sections of your configurations.
- Use `terraform fmt` to format your configurations automatically.
- Use `terraform validate` to check for syntax errors and ensure configurations are valid.
- Use `tflint` to check for style violations and ensure configurations follow best practices.
  - Run `tflint` regularly to catch style issues early in the development process.

## Documentation

- Always include `description` and `type` attributes for variables and outputs.
  - Use clear and concise descriptions to explain the purpose of each variable and output.
  - Use appropriate types for variables (e.g., `string`, `number`, `bool`, `list`, `map`).
- Document your Terraform configurations using comments, where appropriate.
  - Use comments to explain the purpose of resources and variables.
  - Use comments to explain complex configurations or decisions.
  - Avoid redundant comments; comments should add value and clarity.
- Include a `README.md` file in each project to provide an overview of the project and its structure.
  - Include instructions for setting up and using the configurations.
- Use `terraform-docs` to generate documentation for your configurations automatically.

## Testing

- Write tests to validate the functionality of your Terraform configurations.
  - Use the `.tftest.hcl` extension for test files.
  - Write tests to cover both positive and negative scenarios.
  - Ensure tests are idempotent and can be run multiple times without side effects.

## 9. Follow recommended Terraform practices

- **Redundant depends_on Detection**: Search and remove `depends_on` where the dependent resource is already referenced implicitly in the same resource block. Retain `depends_on` only where it is explicitly required.  Never depend on module outputs.

- **Iteration**: Use `count` for 0-1 resources, `for_each` for multiple resources. Prefer maps for stable resource addresses. Align with TFNFR7.

- **Data sources**: Acceptable in root modules but avoid in reusable modules. Prefer explicit module parameters over data source lookups.

- **Parameterization**: Use strongly typed variables with explicit `type` declarations (TFNFR18), comprehensive descriptions (TFNFR17), and non-nullable defaults (TFNFR20). Leverage AVM-exposed variables.

- **Versioning**: Target latest stable Terraform and Azure provider versions. Specify versions in code and keep updated (TFFR3).

## 10. Folder Structure

Use a consistent folder structure for Terraform configurations.

Use tfvars to modify environmental differences. In general, aim to keep environments similar whilst cost optimising for non-production environments.

Antipattern - branch per environment, repository per environment, folder per environment - or similar layouts that make it hard to test the root folder logic between environments.  

Be aware of tools such as Terragrunt which may influence this design.

A **suggested** structure is:

```text
my-azure-app/
├── infra/                          # Terraform root module (AZD compatible)
│   ├── main.tf                     # Core resources
│   ├── variables.tf                # Input variables
│   ├── outputs.tf                  # Outputs
│   ├── terraform.tf                # Provider configuration
│   ├── locals.tf                   # Local values
│   └── environments/               # Environment-specific configurations
│       ├── dev.tfvars              # Development environment
│       ├── test.tfvars             # Test environment
│       └── prod.tfvars             # Production environment
├── .github/workflows/              # CI/CD pipelines (if using github)
├── .azdo/                          # CI/CD pipelines (suggested if using Azure DevOps)
└── README.md                       # Documentation
```

Never change the folder structure without direct agreement with the user.

Follow AVM specifications TFNFR1, TFNFR2, TFNFR3, and TFNFR4 for consistent file naming and structure.

## Azure-Specific Best Practices

### Resource Naming and Tagging

- Follow [Azure naming conventions](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
- Use consistent region naming and variables for multi-region deployments
- Implement consistent tagging.

### Resource Group Strategy

- Use existing resource groups when specified
- Create new resource groups only when necessary and with confirmation
- Use descriptive names indicating purpose and environment

### Networking Considerations

- Validate existing VNet/subnet IDs before creating new network resources (for example, is this solution being deployed into an existing hub & spoke landing zone)
- Use NSGs and ASGs appropriately
- Implement private endpoints for PaaS services when required, use resource firewall restrictions to restrict public access otherwise.  Comment exceptions where public endpoints are required.

### Security and Compliance

- Use Managed Identities instead of service principals
- Implement Key Vault with appropriate RBAC.
- Enable diagnostic settings for audit trails
- Follow principle of least privilege

## Cost Management

- Confirm budget approval for expensive resources
- Use environment-appropriate sizing (dev vs prod)
- Ask for cost constraints if not specified

## State Management

- Use remote backend (Azure Storage) with state locking
- Never commit state files to source control
- Enable encryption at rest and in transit

## Validation

- Do an inventory of existing resources and offer to remove unused resource blocks.
- Run `terraform validate` to check syntax
- Ask before running `terraform plan`.  Terraform plan will require a subscription ID, this should be sourced from the ARM_SUBSCRIPTION_ID environment variable, *NOT* coded in the provider block.
- Test configurations in non-production environments first
- Ensure idempotency (multiple applies produce same result)

## Fallback Behavior

If general rules are not loaded, default to: minimalist code generation, explicit consent for any terraform commands beyond validate, and adherence to CALMS principles in all suggestions.
