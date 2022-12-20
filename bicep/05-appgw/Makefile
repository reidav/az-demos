$(eval RG_NAME = $(shell jq .parameters.rgName.value ../01-resource-group/parameters-main.json))
$(eval KV_UAI_PREFIX_NAME = $(shell jq .parameters.keyVaultUaiPrefixName.value ../03-keyvault/parameters-main.json))

default: deploy

deploy:
	@echo 'Deploying $(RG_NAME) ...'
	@az deployment group create --template-file main.bicep -g $(RG_NAME) --parameters ./parameters-main.json -p keyVaultUaiPrefixName=$(KV_UAI_PREFIX_NAME)

clean:
	@echo 'Deleting $(RG_NAME) ...'
	@az group delete --resource-group $(RG_NAME) --yes