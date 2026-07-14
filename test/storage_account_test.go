//go:build terratest

package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestTerraformAzureStorageAccount applies the fixture under test/fixtures/storage-account,
// which sources THIS module at PR HEAD (../../..), in Azure Government. It asserts security
// posture via Terraform outputs (read back through a data source — no Azure SDK auth needed)
// and destroys everything.
func TestTerraformAzureStorageAccount(t *testing.T) {
	t.Parallel()

	// Unique per run AND per repo: "stci" is this repo's fleet-unique prefix
	// (cross-repo collision avoidance on the shared Azure Gov test subscription).
	uniqueID := strings.ToLower(random.UniqueId())
	name := fmt.Sprintf("stci%s", uniqueID)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// The fixture pins the module at PR HEAD via source = "../../..".
		TerraformDir: "fixtures/storage-account",
		Vars: map[string]interface{}{
			"name":                name,
			"resource_group_name": fmt.Sprintf("rg-terratest-%s", uniqueID),
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// The data-source read is deferred to apply time, and Terraform core does not
	// persist Optional-non-Computed attributes (min_tls_version) from a deferred
	// read. A refresh-only apply re-reads the data source against the now-existing
	// account and persists the full attribute set.
	terraform.RunTerraformCommand(t, terraformOptions, terraform.FormatArgs(terraformOptions, "apply", "-refresh-only", "-input=false", "-auto-approve")...)

	assert.Equal(t, name, terraform.Output(t, terraformOptions, "storage_account_name"))
	// usgovcloudapi.net proves we hit Azure Government, not public Azure.
	assert.Contains(t, terraform.Output(t, terraformOptions, "primary_blob_endpoint"), ".blob.core.usgovcloudapi.net")
	assert.Equal(t, "true", terraform.Output(t, terraformOptions, "https_traffic_only_enabled"))
	assert.Equal(t, "TLS1_2", terraform.Output(t, terraformOptions, "min_tls_version"))
}
