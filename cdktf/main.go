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

func NewMyStack(scope constructs.Construct, id string) cdktf.TerraformStack {
	stack := cdktf.NewTerraformStack(scope, &id)

	location := jsii.String("westeurope")

	tags := make(map[string]*string)
	tags["creator"] = jsii.String("f13233")
	tags["created"] = jsii.String(time.Now().Format(time.RFC3339))
	tags["deployed"] = jsii.String("CDKTF")

	provider.NewAzurermProvider(stack, jsii.String("azurerm"), &provider.AzurermProviderConfig{
		Features:       &provider.AzurermProviderFeatures{},
		TenantId:       jsii.String("7c7b9321-129f-49df-9a90-1d150e3f40f1"),
		SubscriptionId: jsii.String("6cb9dfe0-8839-4cc4-9e5a-3fd69da52b27"),
	})

	random.NewRandomProvider(stack, jsii.String("random"), &random.RandomProviderConfig{})

	rg := resourcegroup.NewResourceGroup(stack, jsii.String("az-deploy-demo-cdktf-rg"), &resourcegroup.ResourceGroupConfig{
		Name:     jsii.String("az-deploy-demo-cdktf-rg"),
		Location: location,
		Tags:     &tags,
	})

	vnet := virtualnetwork.NewVirtualNetwork(stack, jsii.String("az-cdktf-vnet"), &virtualnetwork.VirtualNetworkConfig{
		Name:              jsii.String("az-cdktf-vnet"),
		AddressSpace:      jsii.Strings("10.0.0.0/16"),
		Location:          rg.Location(),
		ResourceGroupName: rg.Name(),
		Tags:              &tags,
	})

	subnet := subnet.NewSubnet(stack, jsii.String("az-cdktf-db-subnet"), &subnet.SubnetConfig{
		Name:               jsii.String("az-cdktf-db-subnet"),
		ResourceGroupName:  rg.Name(),
		VirtualNetworkName: vnet.Name(),
		AddressPrefixes:    jsii.Strings("10.0.0.0/24"),
		ServiceEndpoints:   jsii.Strings("Microsoft.Sql"),
	})

	keyvault.NewKeyVault(stack, jsii.String("keyvault"), &keyvault.KeyVaultConfig{
		Name:                   jsii.String("az-cdktf-keyvault"),
		TenantId:               jsii.String("7c7b9321-129f-49df-9a90-1d150e3f40f1"),
		Location:               rg.Location(),
		ResourceGroupName:      rg.Name(),
		SkuName:                jsii.String("standard"),
		PurgeProtectionEnabled: false,
		Tags:                   &tags,
	})

	mssqlserver_login := random.NewUuid(stack, jsii.String("server-login"), &random.UuidConfig{})
	mssqlserver_password := random.NewPassword(stack, jsii.String("server-password"), &random.PasswordConfig{
		Length: jsii.Number(32),

		Special:    jsii.Bool(true),
		MinSpecial: jsii.Number(5),
	})

	fmt.Printf(*mssqlserver_password.Result())

	mssqlserver := mssqlserver.NewMssqlServer(stack, jsii.String("az-cdktf-sql-server"), &mssqlserver.MssqlServerConfig{
		Name:                       jsii.String("az-cdktf-sql-server"),
		ResourceGroupName:          rg.Name(),
		Location:                   rg.Location(),
		MinimumTlsVersion:          jsii.String("1.2"),
		Version:                    jsii.String("12.0"),
		AdministratorLogin:         mssqlserver_login.Result(),
		AdministratorLoginPassword: mssqlserver_password.BcryptHash(),
		Tags:                       &tags,
	})

	mssqldatabase.NewMssqlDatabase(stack, jsii.String("az-cdktf-sql-db"), &mssqldatabase.MssqlDatabaseConfig{
		Name:        jsii.String("az-cdktf-sql-db"),
		ServerId:    mssqlserver.Id(),
		Collation:   jsii.String("SQL_Latin1_General_CP1_CI_AS"),
		LicenseType: jsii.String("LicenseIncluded"),
		Tags:        &tags,
	})

	mssqlvirtualnetworkrule.NewMssqlVirtualNetworkRule(stack, jsii.String("az-cdktf-network-rule"), &mssqlvirtualnetworkrule.MssqlVirtualNetworkRuleConfig{
		Name:     jsii.String(*mssqlserver.Name() + "-network-rule"),
		ServerId: mssqlserver.Id(),
		SubnetId: subnet.Id(),
	})

	appservice_name := "az-cdktf-webapp"

	appserviceplan := appserviceplan.NewAppServicePlan(stack, jsii.String("appserviceplan"), &appserviceplan.AppServicePlanConfig{
		Name:              jsii.String(appservice_name + "-appserviceplan"),
		ResourceGroupName: rg.Name(),
		Location:          rg.Location(),
		Sku: &appserviceplan.AppServicePlanSku{
			Tier: jsii.String("Standard"),
			Size: jsii.String("F1"),
		},
		Tags: &tags,
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
		Tags: &tags,
	})

	return stack
}

func main() {
	app := cdktf.NewApp(nil)

	NewMyStack(app, "cdktf")

	app.Synth()
}
