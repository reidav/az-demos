RG_NAME=rg-azdemoapim01
DEP_LOCATION=westeurope

default: deploy

deploy:
	@echo 'Deploying ...'
	@az deployment group create -f ./main.bicep -g $(RG_NAME) -p environment=dev -p uamsi=12345678-1234-1234-1234-123456789012

clean:
	@echo 'Deleting ...'
	@az group delete --resource-group $(RG_NAME) --yes