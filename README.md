# Service Health Alerts and Policy

Azure Monitor Action Group and Azure Policy assignment examples in Bicep and
Terraform for Azure Service Health alerts.

The `actionGroup` examples create only an Action Group. The `policyDefinition`
examples assign Microsoft's built-in policy to deploy a Service Health alert rule
that uses that existing Action Group. They do not create a custom policy
definition. Creating the Action Group alone does not enable notifications;
existing subscriptions need policy remediation or a manually created alert rule.

## Repository contents

| File | Purpose |
| --- | --- |
| [actionGroup/bicep/main.bicep](actionGroup/bicep/main.bicep) | Resource-group-scoped Action Group using `Microsoft.Insights/actionGroups@2023-01-01`. |
| [actionGroup/terraform/main.tf](actionGroup/terraform/main.tf) | Equivalent Action Group configuration using the AzureRM provider. |
| [policyDefinition/bicep/main.bicep](policyDefinition/bicep/main.bicep) | Subscription-scoped built-in policy assignment and managed-identity role assignment. |
| [policyDefinition/terraform/main.tf](policyDefinition/terraform/main.tf) | Equivalent policy and role assignments using the AzureRM provider. |
| [policyDefinition/terraform/tests/main.tftest.hcl](policyDefinition/terraform/tests/main.tftest.hcl) | Mocked policy parameter and input validation tests; no Azure access required. |
| [.github/CODEOWNERS](.github/CODEOWNERS) | Lists `@430am` as the owner for every path. |
| [.github/instructions/](.github/instructions/) | Contributor guidance for Bicep, Terraform, documentation, and minimal changes. |

There are no CI workflows, committed parameter files, Terraform
backend configuration, provider lock file, or `.gitignore` in this repository.

## Prerequisites

- An Azure subscription and an existing resource group.
- Permission to create or update `Microsoft.Insights/actionGroups` in that resource
  group, for example through the Contributor role.
- Azure CLI for the examples below, authenticated to the intended subscription.
- For Bicep: the Bicep CLI available through Azure CLI (`az bicep version`).
- For Terraform: Terraform `>= 1.5.0` and AzureRM `>= 5.0.0`, as declared in the
  configuration.

Choose **one** implementation for each resource. An Action Group created by either
tool can be used by either policy example, but do not manage the same Action
Group or policy assignment with both tools.

## Action Group default behavior

- Action Group name: `ag-serviceHealth`.
- Short name: `svcHlth`. Azure permits at most 12 characters.
- Email receivers: `OpsDL` (`azure-alerts@example.com`) and `SupportDL`
  (`support@example.com`). These are placeholders; replace them before deployment.
- ARM role receivers: subscription Contributors and Owners.
- Every default receiver enables the common alert schema.
- Bicep explicitly sets the location to `global` and enables the group. Terraform
  relies on the provider defaults for location and enabled status.

ARM role receivers use **role definition GUIDs**, not role assignment IDs. Adding
a role receiver does not grant permissions or create role assignments. Check that
the intended recipients meet Azure's role-email eligibility requirements; do not
assume every member of a group or every resource-group-scoped role assignment will
receive notifications. See [Action Groups](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/action-groups).

## Deploy an Action Group with Bicep

Run from the repository root. Replace the subscription, resource group, and email
placeholders. An empty `armRoleReceivers` array disables role-based notifications
in this example; omit that override to retain the default Owner and Contributor
receivers.

```bash
az login
az account set --subscription "<subscription-id>"

az bicep build --file actionGroup/bicep/main.bicep --stdout > /dev/null

az deployment group validate \
  --resource-group "<existing-resource-group>" \
  --template-file actionGroup/bicep/main.bicep \
  --parameters \
    actionGroupName=ag-serviceHealth \
    actionGroupShortName=svcHlth \
    emailRecivers='[{"name":"OpsDL","emailAddress":"replace-me@example.com","useCommonAlertSchema":true}]' \
    armRoleReceivers='[]'

az deployment group create \
  --name service-health-action-group \
  --resource-group "<existing-resource-group>" \
  --template-file actionGroup/bicep/main.bicep \
  --parameters \
    actionGroupName=ag-serviceHealth \
    actionGroupShortName=svcHlth \
    emailRecivers='[{"name":"OpsDL","emailAddress":"replace-me@example.com","useCommonAlertSchema":true}]' \
    armRoleReceivers='[]'
```

The parameter is currently spelled **`emailRecivers`** in the template. Use that
exact spelling; `emailReceivers` is not a declared parameter.

### Bicep inputs and output

| Parameter | Type | Default / requirement |
| --- | --- | --- |
| `actionGroupName` | `string` | `ag-serviceHealth` |
| `actionGroupShortName` | `string` | `svcHlth`; maximum length 12 enforced by a decorator |
| `emailRecivers` | `array` | Two placeholder receivers; objects use `name`, `emailAddress`, and `useCommonAlertSchema` |
| `armRoleReceivers` | `array` | Contributor and Owner receivers; objects use `name`, `roleId`, and `useCommonAlertSchema` |

Output: `actionGroupResourceId`, the full Azure resource ID of the Action Group.
Both receiver arrays can be overridden with `[]`.

## Deploy an Action Group with Terraform

### Configuration and commands

Authenticate and select the subscription:

```bash
az login
az account set --subscription "<subscription-id>"
export ARM_SUBSCRIPTION_ID="$(az account show --query id --output tsv)"
cd actionGroup/terraform
```

Create a local `terraform.tfvars` with your resource group and actual email
address. This example disables the default role receivers:

```hcl
resource_group_name = "<existing-resource-group>"

email_receivers = [
  {
    name                    = "OpsDL"
    email_address           = "replace-me@example.com"
    use_common_alert_schema = true
  }
]

arm_role_receivers = []
```

Review the plan before applying:

```bash
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform output -raw action_group_id
```

Terraform uses local state unless you configure a backend. This repository has
no ignore rules: keep `.terraform/`, state files, saved plans, credentials, and
local receiver configuration out of commits. State and plans can contain email
addresses and other deployment data. For shared use, configure a remote backend
with access controls and locking before deployment. Commit the generated
`.terraform.lock.hcl` when adopting Terraform to make provider selection
reproducible; the current version constraint has no upper bound.

### Terraform inputs and output

| Variable | Type | Default / requirement |
| --- | --- | --- |
| `resource_group_name` | `string` | Required; the resource group must already exist |
| `action_group_name` | `string` | `ag-serviceHealth` |
| `action_group_short_name` | `string` | `svcHlth`; Azure/provider limit is 12 characters, with no explicit variable validation in this configuration |
| `email_receivers` | `list(object)` | Two placeholder receivers; required fields: `name` (string), `email_address` (string), `use_common_alert_schema` (bool) |
| `arm_role_receivers` | `list(object)` | Contributor and Owner receivers; required fields: `name` (string), `role_id` (string), `use_common_alert_schema` (bool) |

Output: `action_group_id`, the full Azure resource ID of the Action Group.
Both receiver lists can be overridden with `[]`.

## Assign the Service Health policy

Both [policy examples](policyDefinition/) assign
[Configure subscriptions to enable service health alert monitoring rule](https://github.com/Azure/azure-policy/blob/master/built-in-policies/policyDefinitions/Monitoring/ServiceHealthSubscriptionLevelAlertRules_DINE.json),
definition ID `98903777-a9f6-47f5-90a9-acaf62ab01a8`, at the selected subscription.
They reuse the built-in definition rather than maintaining a copy.

Both examples:

- Create an enforced `service-health-alerts` policy assignment with a
  system-assigned managed identity.
- Set `effect` to `DeployIfNotExists` and `enableAlertRule` to the string `"true"`.
- Pass the supplied resource ID as the one-element `actionGroups` array.
- Set `createNewActionGroup` to the string `"false"` so policy does not create
  another Action Group or change the existing group's receivers.
- Grant the identity **Monitoring Policy Contributor**
  (`47be4a87-7950-4631-9daf-b664a405f074`) at subscription scope, as required by
  the built-in definition for remediation.

The remaining built-in parameters use their defaults. In definition version
1.5.0, remediation creates `rg-serviceHealthAlert` if needed and deploys
`ServiceHealthSubscriptionAlertRule` covering Service Issues, Planned Maintenance,
Health Advisories, and Security Advisories. The `location` input sets the identity
and policy-created resource group's region; it does not filter affected service
regions. Built-in defaults can change when Microsoft updates the definition.

The deployment principal needs permission to create subscription policy
assignments and grant the remediation role, such as Owner or an appropriate
combination of policy and role-based access control permissions. Contributor
alone cannot grant the role assignment. Use an existing, accessible Action Group,
preferably in the target subscription, with verified real receivers.

### Obtain the existing Action Group ID

Run from the repository root after deploying the Action Group. For Bicep:

```bash
ACTION_GROUP_ID="$(az deployment group show \
  --name service-health-action-group \
  --resource-group "<existing-resource-group>" \
  --query properties.outputs.actionGroupResourceId.value --output tsv)"
```

Or, for Terraform:

```bash
ACTION_GROUP_ID="$(terraform -chdir=actionGroup/terraform output -raw action_group_id)"
```

The value must be a full resource ID, not a group name:
`/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Insights/actionGroups/<action-group-name>`.
Either output works with either policy implementation.

### Bicep policy assignment

Run from the repository root, authenticated to the target subscription:

```bash
az account set --subscription "<subscription-id>"

az bicep build --file policyDefinition/bicep/main.bicep --stdout > /dev/null

az deployment sub create \
  --name service-health-policy \
  --location centralus \
  --template-file policyDefinition/bicep/main.bicep \
  --parameters actionGroupResourceId="$ACTION_GROUP_ID" location=centralus

POLICY_ASSIGNMENT_ID="$(az deployment sub show \
  --name service-health-policy \
  --query properties.outputs.policyAssignmentId.value --output tsv)"
```

### Terraform policy assignment

This is a separate root configuration and state from the Action Group example.
Run from the repository root:

```bash
az account set --subscription "<subscription-id>"
export ARM_SUBSCRIPTION_ID="$(az account show --query id --output tsv)"
export TF_VAR_action_group_resource_id="$ACTION_GROUP_ID"

terraform -chdir=policyDefinition/terraform init
terraform -chdir=policyDefinition/terraform validate
terraform -chdir=policyDefinition/terraform plan -out=tfplan
terraform -chdir=policyDefinition/terraform apply tfplan

POLICY_ASSIGNMENT_ID="$(terraform -chdir=policyDefinition/terraform output -raw policy_assignment_id)"
```

Review the saved plan before applying. Set `TF_VAR_location` or a local tfvars file
to use a region other than `centralus`. The same local-state and sensitive-file
precautions described for the Action Group example apply here.

### Policy inputs and outputs

| Bicep parameter | Terraform variable | Requirement / default |
| --- | --- | --- |
| `actionGroupResourceId` | `action_group_resource_id` | Required full resource ID of the already deployed Action Group |
| `location` | `location` | `centralus`; assignment identity and remediation resource-group region |

Outputs are `policyAssignmentId` / `policy_assignment_id` and
`policyAssignmentPrincipalId` / `policy_assignment_principal_id`.

### Remediate the existing subscription

Assignment creation does not immediately deploy the alert rule for an existing
subscription. After deployment and role-assignment propagation, create a
remediation task. Both examples leave this as an explicit operational step rather
than racing the identity's new permissions:

```bash
az policy remediation create \
  --name service-health-alerts-remediation \
  --policy-assignment "$POLICY_ASSIGNMENT_ID" \
  --resource-discovery-mode ReEvaluateCompliance

az policy remediation show --name service-health-alerts-remediation
```

These commands use the currently selected subscription. Review task/deployment
status in Azure Policy and verify the alert exists, is enabled, and references the
expected Action Group. Policy evaluation, RBAC propagation, and remediation are
asynchronous; a successful assignment deployment is not proof of alert creation.
If remediation fails, inspect its deployment error before retrying.

Policy-created alert rules and resource groups are not resources in these
Terraform states or Bicep templates. Deleting the assignment does not delete
remediated resources. Avoid changing built-in rule/resource-group names without
reviewing the definition's duplicate-alert warnings, and do not separately manage
the policy-created alert rule with another IaC deployment.

### Local policy checks

```bash
az bicep build --file policyDefinition/bicep/main.bicep --stdout > /dev/null
terraform -chdir=policyDefinition/terraform init -backend=false
terraform -chdir=policyDefinition/terraform validate
terraform -chdir=policyDefinition/terraform fmt -check -recursive
terraform -chdir=policyDefinition/terraform test
```

The mocked tests require Terraform `>= 1.7.0`; deployment configuration retains
the `>= 1.5.0` minimum. Tests check policy parameters, identity/role configuration,
and invalid inputs without an Azure login. They do not run a real Azure plan or
verify policy remediation. See [Remediate non-compliant resources](https://learn.microsoft.com/en-us/azure/governance/policy/how-to/remediate-resources)
for the identity and remediation lifecycle.

## Verify notifications

1. Deploy an Action Group with real receivers.
2. Open it in **Azure Monitor > Alerts > Action groups**. Complete any required
   email verification and use **Test** to check delivery. A successful deployment
   is not proof that a notification can be delivered.
3. Deploy and remediate the policy example above, or manually create a Service
   Health alert in the portal and associate the deployed Action Group. Do not
   create a duplicate manual rule if policy already deployed the desired rule.
4. Check the rule is enabled and its scope and conditions cover the events you
   want to receive.

See [Create Service Health alerts](https://learn.microsoft.com/en-us/azure/service-health/alerts-activity-log-service-notifications-portal)
for the portal workflow. Service Health alerts and Resource Health alerts are
different; the policy examples configure Service Health monitoring only.

If no email arrives, check the real receiver address, any verification requirement,
spam filtering, role-receiver eligibility, and the alert rule's enabled status,
scope, and conditions. With both receiver arrays empty, the group has no
notification recipients.

## Review and contribution notes

- Bicep compilation passed during this review. No Azure deployment or notification
  test was performed.
- Terraform provider initialization, `terraform validate`, and
  `terraform fmt -check` passed with Terraform 1.17.1 and AzureRM 5.12.0.
  Validation used an isolated temporary directory with the backend disabled;
  no plan, apply, or Azure runtime test was performed.
- The Bicep policy compiled and passed generated-template assertions for policy
  parameters and identity/RBAC wiring. The Terraform policy passed three mocked
  tests, including invalid-input cases; no real Azure plan was run.
- Policy examples assign a built-in definition and grant remediation permissions;
  alert creation occurs through Azure Policy, not during local validation.
- [CODEOWNERS](.github/CODEOWNERS) declares ownership; it does not enable branch
  protection. Require pull requests and code-owner review through branch
  protection or a ruleset to enforce approvals. Account for bypass permissions;
  an author cannot approve their own pull request. Repository protection settings
  were not inspected in this review.
- Follow the guidance in [.github/instructions/](.github/instructions/) and update
  this README when inputs, outputs, prerequisites, or deployment behavior change.
  Run Bicep compilation or Terraform validation as appropriate before proposing
  infrastructure changes, and test notification delivery in a non-production
  environment.
