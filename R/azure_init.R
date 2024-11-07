# If you have not set up your Azure credentials, you will need to run
# AzureRMR::create_azure_login(tenant = "adamshen1live.onmicrosoft.com")
AzureRMR::get_azure_login(
  tenant = "adamshen1live.onmicrosoft.com",
  auth_type = "device_code"
)

token <- AzureAuth::get_azure_token(
  resource = "https://cbspeeches1.dfs.core.windows.net/",
  tenant = "adamshen1live.onmicrosoft.com",
  app = "04b07795-8ddb-461a-bbee-02f9e1bf7b46",
  auth_type = "device_code"
)
