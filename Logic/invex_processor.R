library(pdftools)
library(dplyr)
library(here)
library(glue)
library(stringr)
library(purrr)
library(lubridate)

here::i_am(
  "Logic/invex_processor.R"
)

source(
  here("Logic",
       "parse_invex_financial.R")
)

invex_financial_pdf <- fs::dir_ls(
  here(
    "inputs",
    "invex prod"
  )
)

full_invex_financial_data <- invex_financial_pdf |>
  map(
    \(invex_pdf)
    parse_invex_financial_2_df(invex_pdf)
  ) |> 
  list_rbind() 


# Upload to Google Drive --------------------------------------------------
clean_invex_financial_data <- full_invex_financial_data |> 
  mutate(
    pago_tdc = str_detect(descripcion, "SU PAGO POR SPEI")
    )

googlesheets4::gs4_auth(email = "daniel.amieva@dar4datascience.com")


googlesheets4::sheet_write(                            clean_invex_financial_data,
                                                       "https://docs.google.com/spreadsheets/d/1przfdI8MDLWf9rYPgOY9T0XLzEbhb9-xM1Gs-K6dgnY/edit#gid=589164612",
                            sheet = "Finanzas Invex Credit")
# googlesheets4::sheet_append("https://docs.google.com/spreadsheets/d/1przfdI8MDLWf9rYPgOY9T0XLzEbhb9-xM1Gs-K6dgnY/edit#gid=589164612",
#                             clean_hsbc_credit_cards_data,
#                             sheet = "Finanzas Invex Credit")
