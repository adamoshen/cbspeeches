token <- AzureAuth::get_azure_token(
  resource = "https://cbspeeches1.dfs.core.windows.net/",
  tenant = "adamshen1live.onmicrosoft.com",
  app = "04b07795-8ddb-461a-bbee-02f9e1bf7b46",
  auth_type = ifelse(rstudioapi::isAvailable(), "authorization_code", "device_code")
)
