source(
  here::here("Logic",
       "parse_banco_azteca_nomina.R")
)

baz_nomina_pdfs <- fs::dir_ls(
  here::here(
  "inputs/baz prod"
  ),
  glob = "*.pdf"
)

baz_nomina_data <- baz_nomina_pdfs |> 
  map(parse_baz_financial_nomina) |> 
  list_rbind()


googlesheets4::gs4_auth(email = "daniel.amieva@dar4datascience.com")

# 
# googlesheets4::sheet_write(                            baz_nomina_data,
#                                                        "https://docs.google.com/spreadsheets/d/1przfdI8MDLWf9rYPgOY9T0XLzEbhb9-xM1Gs-K6dgnY/edit#gid=589164612",
#                             sheet = "Finanzas Banco Azteca")

# googlesheets4::sheet_append("https://docs.google.com/spreadsheets/d/1przfdI8MDLWf9rYPgOY9T0XLzEbhb9-xM1Gs-K6dgnY/edit#gid=589164612",
#                             clean_hsbc_credit_cards_data,
#                             sheet = "Finanzas Invex Credit")
