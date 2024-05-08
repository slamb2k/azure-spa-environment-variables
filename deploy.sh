#!/bin/bash
set -e

# Colours
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# The web app name has to be unique 
UNIQUE_BASE_NAME=<SOME_UNIQUE_STRING>
SUBSCRIPTION=<SUBSCRIPTION_ID>
REGION="australiaeast"

echo -e "\n${GREEN}Installing dependencies...${NC}"
sudo apt install wslu

# The web app name has to be unique. Define it here.
echo -e "\n${CYAN}Authenticating with Azure...${NC}"
az login

# If a subscription was not provided, list the available subscriptions 
# and prompt the user to select one.
if [ -z "$SUBSCRIPTION" ]; then
    echo -e "\n${CYAN}Select a subscription...${NC}"
    az account list --output table
    read -p "Enter the subscription ID: " SUBSCRIPTION </dev/tty
fi

echo -e "\n${CYAN}Activating Azure Subscription: ${SUBSCRIPTION}${NC}"
az account set --subscription $SUBSCRIPTION

echo -e "\n${GREEN}Creating resource group...${NC}"
RESOURCE_GROUP_NAME="rg-${UNIQUE_BASE_NAME}"
echo -e "\n${CYAN}Creating resource group: ${RESOURCE_GROUP_NAME}${NC}"
az group create --name ${RESOURCE_GROUP_NAME} --location $REGION

echo -e "\n${GREEN}Creating app service plan and webapp...${NC}"
APP_PLAN_NAME="asp-${UNIQUE_BASE_NAME}"
WEB_APP_NAME="web-${UNIQUE_BASE_NAME}"
az appservice plan create --name $APP_PLAN_NAME --sku "P1V2" --location $REGION --resource-group $RESOURCE_GROUP_NAME
az webapp create --name $WEB_APP_NAME --plan $APP_PLAN_NAME --runtime "NODE:20LTS" --resource-group $RESOURCE_GROUP_NAME

echo -e "\n${GREEN}Creating production build...${NC}"
rm build -Rf
npm run build

echo -e "\n${YELLOW}Creating base zip deployment package...${NC}"
pushd build
rm -f build.zip 
zip -r ../build.zip .
popd

echo -e "\n${YELLOW}Updating env.js in package zip with TEST environment variables. [env.test.js]${NC}"
cp build/env.test.js build/env.js
pushd build
zip ../build.zip env.js
popd

echo -e "\n${GREEN}Deploying TEST package to webapp: "http://${WEB_APP_NAME}.azurewebsites.net"${NC}"
az webapp deploy --name ${WEB_APP_NAME} --src-path build.zip --type zip --resource-group $RESOURCE_GROUP_NAME

echo -e "\n${GREEN}Opening webapp in default browser...${NC}"
xdg-open "http://${WEB_APP_NAME}.azurewebsites.net"

echo -e "\n${YELLOW}Once you have confirmed the test variables are loaded, click the enter key to deploy the production environment variables.${NC}"
read -p "Press Enter to continue" </dev/tty

echo -e "\n${YELLOW}Updating env.js in package zip with PROD environment variables. [env.prod.js]${NC}"
cp build/env.prod.js build/env.js
pushd build
zip ../build.zip env.js
popd

echo -e "\n${GREEN}Deploying PROD package to webapp: "http://${WEB_APP_NAME}.azurewebsites.net"${NC}"
az webapp deploy --name ${WEB_APP_NAME} --src-path build.zip --type zip --resource-group $RESOURCE_GROUP_NAME

echo -e "\n${GREEN}Opening webapp in default browser...${NC}"
xdg-open "http://${WEB_APP_NAME}.azurewebsites.net"
