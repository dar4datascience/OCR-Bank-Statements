library(pdftools)
library(dplyr)
library(here)
library(glue)
library(stringr)
library(purrr)
library(lubridate)

source(
  here("Logic",
       "hsbc_processor.R")
)

# test
# 
# file_path <- "2023-10-06_Estado de cuenta.pdf"
# 
# hsbc_relevant_content <- extract_hsbc_relevant_text(file_path)
# 
# hsbc_expenditures <- extract_hsbc_expenditures(hsbc_relevant_content)
# 
# hsbc_expenditures_df <- hsbc_parse_expenditures_2_df(hsbc_expenditures) |> 
#   filter(!is.na(Cost))
# 
# hsbc_pagos_extracted <- extract_hsbc_pagos(hsbc_relevant_content)
# 
# hsbc_pagos_df <- hsbc_parse_pagos_2_df(hsbc_pagos_extracted)
# 
# # combine pagos and expenditures
# full_hsbc <- hsbc_expenditures_df |> 
#   bind_rows(hsbc_pagos_df) 

hsbc_2now_pdfs <- fs::dir_ls(
  here("inputs",
       "hsbc prod"),
  glob = "*.pdf"
)

hsbc_2now_financial_df <- hsbc_2now_pdfs |> 
  map(fully_parse_2_df_hsbc_financial) |> 
  list_rbind() |> 
  mutate(
    source = "HSBC 2NOW"
  )



hsbc_viva_pdf <- fs::dir_ls(
  here("inputs",
       "hsbc prod",
       "viva")
)

hsbc_viva_financial_df <- hsbc_viva_pdf |> 
  map(fully_parse_2_df_hsbc_financial) |> 
  list_rbind() |> 
  mutate(
    source = "HSBC Viva"
  )


# Full HSBC Credit Data ---------------------------------------------------

hsbc_credit_cards_data <- hsbc_2now_financial_df |> 
  bind_rows(hsbc_viva_financial_df) |> 
  # clean concepto column
  mutate(
    Concept = str_remove_all(Concept,
                             "[A-Z]{3} \\d+\\w+") |> 
      str_replace_all("\\b[\\d,\\.]+\\b", "") |> 
      str_trim(side = "both"),
    main_category = word(Concept, 1),
    Date = str_trim(Date, side = "both")
  ) |> 
  # clean date column
  mutate(
    parsed_Date = case_when(
      str_detect(Date, "^\\d{2}/\\d{2}/\\d{4} \\d{2}:\\d{2}:\\d{2}$") ~ dmy_hms(Date),
      str_detect(Date, "^\\d{2} [A-Z]{3}$") ~
        month_to_number(Date) |> 
        ymd(),
      TRUE ~ NA
    ),
    parsed_Date = as_date(parsed_Date)
  ) |> 
  select(
    Date,
    parsed_Date,
    everything()
    )



# Upload ------------------------------------------------------------------

googlesheets4::gs4_auth(email = "daniel.amieva@dar4datascience.com")

clean_hsbc_credit_cards_data <- hsbc_credit_cards_data |> 
  select(
    parsed_Date,
    Concept,
    main_category,
    Cost,
    source
  ) |> 
  arrange(parsed_Date) |> 
  mutate(
    pago_tdc = str_detect(Concept, "pagotc")
  )

googlesheets4::sheet_append("https://docs.google.com/spreadsheets/d/1przfdI8MDLWf9rYPgOY9T0XLzEbhb9-xM1Gs-K6dgnY/edit#gid=589164612",
                            clean_hsbc_credit_cards_data,
                            sheet = "Finanzas HSBC Credit")
