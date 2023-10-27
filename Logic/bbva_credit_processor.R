source(
  here::here("Logic",
             "parse_bbva_credit_financial.R")
)
library(purrr)


bbva_financial_pdf <- fs::dir_ls(
  here::here(
    "inputs",
    "bbva prod"
  )
)
safe_parse_bbva_credit_2_df <- safely(parse_bbva_credit_2_df)

safe_bbva_parse <- bbva_financial_pdf |> 
  map(safe_parse_bbva_credit_2_df) 

full_bbva_credit_data <- safe_bbva_parse |> 
  map("result") |> 
  list_rbind() |> 
  mutate(
    pago_tdc = str_detect(Concept, "TDC")
  )

errors_bbva_credit_data <- safe_bbva_parse |> 
  map("error") |> 
  discard(is.null) 


googlesheets4::gs4_auth(email = "daniel.amieva@dar4datascience.com")

# 
# googlesheets4::sheet_write(                            full_bbva_credit_data,
#                                                        "https://docs.google.com/spreadsheets/d/1przfdI8MDLWf9rYPgOY9T0XLzEbhb9-xM1Gs-K6dgnY/edit#gid=589164612",
#                             sheet = "Finanzas BBVA Credit")
# googlesheets4::sheet_append("https://docs.google.com/spreadsheets/d/1przfdI8MDLWf9rYPgOY9T0XLzEbhb9-xM1Gs-K6dgnY/edit#gid=589164612",
#                             clean_hsbc_credit_cards_data,
#                             sheet = "Finanzas BBVA Credit")
