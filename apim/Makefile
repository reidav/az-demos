$(eval ENV = $(shell jq .parameters.env.value parameters-apim.json))
$(eval LOCATION = $(shell jq .parameters.location.value parameters-apim.json))

default: deploy

deploy:
	@echo 'Deploying ...'
	@az deployment sub create -f ./main.bicep --name $(ENV)  --location $(LOCATION) --parameters ./parameters-apim.json

clean:
	@echo 'Deleting $(RG_NAME) ...'
	@az group delete --resource-group $(RG_NAME) --yes