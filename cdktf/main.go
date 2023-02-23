package main

import (
	"time"

	"github.com/aws/constructs-go/constructs/v10"
	"github.com/aws/jsii-runtime-go"
	"github.com/cdktf/cdktf-provider-azurerm-go/azurerm/v5/mssqlserver"
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
	tags["created"] = jsii.String(time.Now().Format("YYYY-MM-DDTHH:mm:ss"))
	tags["deployed"] = jsii.String("CDKTF")

	provider.NewAzurermProvider(stack, jsii.String("azurerm"), &provider.AzurermProviderConfig{
		Features:       &provider.AzurermProviderFeatures{},
		TenantId:       jsii.String("7c7b9321-129f-49df-9a90-1d150e3f40f1"),
		SubscriptionId: jsii.String("6cb9dfe0-8839-4cc4-9e5a-3fd69da52b27"),
	})

	rg := resourcegroup.NewResourceGroup(stack, jsii.String("az-deploy-demo-cdktf-rg"), &resourcegroup.ResourceGroupConfig{
		Name:     jsii.String("az-deploy-demo-cdktf-rg"),
		Location: location,
		Tags:     &tags,
	})

	vnet := virtualnetwork.NewVirtualNetwork(stack, jsii.String("az-cdktf-vnet"), &virtualnetwork.VirtualNetworkConfig{
		Name:              jsii.String("az-cdktf-vnet"),
		AddressSpace:      &[]*string{jsii.String("10.0.0.0/16")},
		Location:          rg.Location(),
		ResourceGroupName: rg.Name(),
		Tags:              &tags,
	})

	subnet.NewSubnet(stack, jsii.String("az-cdktf-db-subnet"), &subnet.SubnetConfig{
		Name:               jsii.String("az-cdktf-db-subnet"),
		ResourceGroupName:  rg.Name(),
		VirtualNetworkName: vnet.Name(),
		AddressPrefixes:    &[]*string{jsii.String("10.0.0.0/24")},
	})

	mssqlserver_login := random.NewUuid(scope, jsii.String("server-login"), &random.UuidConfig{})
	mssqlserver_password := random.NewPassword(scope, jsii.String("server-password"), &random.PasswordConfig{
		Length:     jsii.Number(32),
		Special:    jsii.Bool(true),
		MinSpecial: jsii.Number(5),
	})

	mssqlserver.NewMssqlServer(stack, jsii.String("az-cdktf-sql-server"), &mssqlserver.MssqlServerConfig{
		Name:                       jsii.String("az-cdktf-sql-server"),
		ResourceGroupName:          rg.Name(),
		Location:                   rg.Location(),
		MinimumTlsVersion:          jsii.String("1.2"),
		Version:                    jsii.String("12.0"),
		AdministratorLogin:         mssqlserver_login.ToString(),
		AdministratorLoginPassword: mssqlserver_password.ToString(),
		Tags:                       &tags,
	})

	return stack
}

func main() {
	app := cdktf.NewApp(nil)

	NewMyStack(app, "cdktf")

	app.Synth()
}
