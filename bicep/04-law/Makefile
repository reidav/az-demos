$(eval RG_NAME = $(shell jq .parameters.rgName.value ../01-resource-group/parameters-main.json))

default: deploy

deploy:
	@echo 'Deploying $(RG_NAME) ...'
	@az deployment group create --template-file main.bicep -g $(RG_NAME) --parameters ./parameters-main.json

clean:
	@echo 'Deleting $(RG_NAME) ...'
	@az group delete --resource-group $(RG_NAME) --yes