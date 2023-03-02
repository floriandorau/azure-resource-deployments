package main

import (
	"fmt"
	"time"

	"github.com/aws/constructs-go/constructs/v10"
	"github.com/aws/jsii-runtime-go"
	"github.com/cdktf/cdktf-provider-azurerm-go/azurerm/v5/appservice"
	"github.com/cdktf/cdktf-provider-azurerm-go/azurerm/v5/appserviceplan"
	"github.com/cdktf/cdktf-provider-azurerm-go/azurerm/v5/keyvault"
	"github.com/cdktf/cdktf-provider-azurerm-go/azurerm/v5/mssqldatabase"
	"github.com/cdktf/cdktf-provider-azurerm-go/azurerm/v5/mssqlserver"
	"github.com/cdktf/cdktf-provider-azurerm-go/azurerm/v5/mssqlvirtualnetworkrule"
	"github.com/cdktf/cdktf-provider-azurerm-go/azurerm/v5/provider"
	"github.com/cdktf/cdktf-provider-azurerm-go/azurerm/v5/resourcegroup"
	"github.com/cdktf/cdktf-provider-azurerm-go/azurerm/v5/subnet"
	"github.com/cdktf/cdktf-provider-azurerm-go/azurerm/v5/virtualnetwork"
	"github.com/hashicorp/cdktf-provider-random-go/random"
	"github.com/hashicorp/terraform-cdk-go/cdktf"
)

func NewMyStack(scope constructs.Construct, stackId string) cdktf.TerraformStack {
	stack := cdktf.NewTerraformStack(scope, &stackId)

	subscriptionId := cdktf.NewTerraformVariable(stack, jsii.String("subscription_id"), &cdktf.TerraformVariableConfig{
		Type:        jsii.String("string"),
		Description: jsii.String("Subscription id where to deploy resources"),
		Nullable:    jsii.Bool(false),
	})

	tenantId := cdktf.NewTerraformVariable(stack, jsii.String("tenant_id"), &cdktf.TerraformVariableConfig{
		Type:        jsii.String("string"),
		Description: jsii.String("Tenant id where to deploy resources"),
		Nullable:    jsii.Bool(false),
	})

	creator := cdktf.NewTerraformVariable(stack, jsii.String("creator"), &cdktf.TerraformVariableConfig{
		Type:        jsii.String("string"),
		Description: jsii.String("Name to use as creator tag for deployed resources"),
		Nullable:    jsii.Bool(false),
	})

	location := cdktf.NewTerraformVariable(stack, jsii.String("location"), &cdktf.TerraformVariableConfig{
		Type:        jsii.String("string"),
		Description: jsii.String("Region where to deploy resources"),
		Nullable:    jsii.Bool(false),
	})

	env := cdktf.NewTerraformVariable(stack, jsii.String("environment"), &cdktf.TerraformVariableConfig{
		Type:        jsii.String("string"),
		Description: jsii.String("Name of the environment where resources belong to"),
		Nullable:    jsii.Bool(false),
	})

	commonTags := cdktf.NewTerraformLocal(stack, jsii.String("common_tags"), map[string]string{
		"Creator":  *creator.StringValue(),
		"Created":  time.Now().Format(time.RFC3339),
		"Env":      *env.StringValue(),
		"Deployed": "CDKTF",
	})

	provider.NewAzurermProvider(stack, jsii.String("azurerm"), &provider.AzurermProviderConfig{
		Features:       &provider.AzurermProviderFeatures{},
		TenantId:       tenantId.StringValue(),
		SubscriptionId: subscriptionId.StringValue(),
	})

	random.NewRandomProvider(stack, jsii.String("random"), &random.RandomProviderConfig{})

	rg := resourcegroup.NewResourceGroup(stack, jsii.String("az-deploy-cdktf-rg"), &resourcegroup.ResourceGroupConfig{
		Name:     jsii.String(fmt.Sprintf("az-deploy-cdktf-%s-rg", *env.StringValue())),
		Location: location.StringValue(),
		Tags:     commonTags.AsStringMap(),
	})

	vnet := virtualnetwork.NewVirtualNetwork(stack, jsii.String("az-cdktf-vnet"), &virtualnetwork.VirtualNetworkConfig{
		Name:              jsii.String(fmt.Sprintf("az-cdktf-%s-vnet", *env.StringValue())),
		AddressSpace:      jsii.Strings("10.0.0.0/16"),
		Location:          rg.Location(),
		ResourceGroupName: rg.Name(),
		Tags:              commonTags.AsStringMap(),
	})

	subnet := subnet.NewSubnet(stack, jsii.String("az-cdktf-db-subnet"), &subnet.SubnetConfig{
		Name:               jsii.String(fmt.Sprintf("az-cdktf-%s-db-subne", *env.StringValue())),
		ResourceGroupName:  rg.Name(),
		VirtualNetworkName: vnet.Name(),
		AddressPrefixes:    jsii.Strings("10.0.0.0/24"),
		ServiceEndpoints:   jsii.Strings("Microsoft.Sql"),
	})

	keyvault.NewKeyVault(stack, jsii.String("keyvault"), &keyvault.KeyVaultConfig{
		Name:                   jsii.String(fmt.Sprintf("az-cdktf-%s-keyvault", *env.StringValue())),
		TenantId:               jsii.String("7c7b9321-129f-49df-9a90-1d150e3f40f1"),
		Location:               rg.Location(),
		ResourceGroupName:      rg.Name(),
		SkuName:                jsii.String("standard"),
		PurgeProtectionEnabled: false,
		Tags:                   commonTags.AsStringMap(),
	})

	mssqlserver_login := random.NewUuid(stack, jsii.String("server-login"), &random.UuidConfig{})
	mssqlserver_password := random.NewPassword(stack, jsii.String("server-password"), &random.PasswordConfig{
		Length: jsii.Number(32),

		Special:    jsii.Bool(true),
		MinSpecial: jsii.Number(5),
	})

	fmt.Printf(*mssqlserver_password.Result())

	mssqlserver := mssqlserver.NewMssqlServer(stack, jsii.String("az-cdktf-sql-server"), &mssqlserver.MssqlServerConfig{
		Name:                       jsii.String(fmt.Sprintf("az-cdktf-%s-sql-server", *env.StringValue())),
		ResourceGroupName:          rg.Name(),
		Location:                   rg.Location(),
		MinimumTlsVersion:          jsii.String("1.2"),
		Version:                    jsii.String("12.0"),
		AdministratorLogin:         mssqlserver_login.Result(),
		AdministratorLoginPassword: mssqlserver_password.BcryptHash(),
		Tags:                       commonTags.AsStringMap(),
	})

	mssqldatabase.NewMssqlDatabase(stack, jsii.String("az-cdktf-sql-db"), &mssqldatabase.MssqlDatabaseConfig{
		Name:        jsii.String(fmt.Sprintf("az-cdktf-%s-sql-db", *env.StringValue())),
		ServerId:    mssqlserver.Id(),
		Collation:   jsii.String("SQL_Latin1_General_CP1_CI_AS"),
		LicenseType: jsii.String("LicenseIncluded"),
		Tags:        commonTags.AsStringMap(),
	})

	mssqlvirtualnetworkrule.NewMssqlVirtualNetworkRule(stack, jsii.String("az-cdktf-network-rule"), &mssqlvirtualnetworkrule.MssqlVirtualNetworkRuleConfig{
		Name:     jsii.String(fmt.Sprintf("%s-%s-network-rule", *mssqlserver.Name(), *env.StringValue())),
		ServerId: mssqlserver.Id(),
		SubnetId: subnet.Id(),
	})

	appservice_name := fmt.Sprintf("az-cdktf-%s-webapp", *env.StringValue())

	appserviceplan := appserviceplan.NewAppServicePlan(stack, jsii.String("appserviceplan"), &appserviceplan.AppServicePlanConfig{
		Name:              jsii.String(fmt.Sprintf("%s-appserviceplan", appservice_name)),
		ResourceGroupName: rg.Name(),
		Location:          rg.Location(),
		Sku: &appserviceplan.AppServicePlanSku{
			Tier: jsii.String("Standard"),
			Size: jsii.String("F1"),
		},
		Tags: commonTags.AsStringMap(),
	})

	appservice.NewAppService(stack, jsii.String("appservice"), &appservice.AppServiceConfig{
		Name:              jsii.String(appservice_name),
		ResourceGroupName: rg.Name(),
		Location:          rg.Location(),
		AppServicePlanId:  appserviceplan.Id(),
		Enabled:           jsii.Bool(false),
		HttpsOnly:         jsii.Bool(true),
		Identity: &appservice.AppServiceIdentity{
			Type: jsii.String("SystemAssigned"),
		},
		Tags: commonTags.AsStringMap(),
	})

	return stack
}

func main() {
	app := cdktf.NewApp(nil)

	NewMyStack(app, "staging")
	NewMyStack(app, "prod")

	app.Synth()
}
