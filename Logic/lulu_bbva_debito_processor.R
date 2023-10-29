library(purrr)
library(reactable)
source(
  here::here("Logic", "parse_bbva_debito.R")
)

bbva_debito_pdfs <- fs::dir_ls(
  here::here("inputs",
       "lulu bbva nomina")
)

records_bbva_pdfs <- bbva_debito_pdfs |> 
  map_chr(
    ~basename(
      .x
    )
  ) |> 
  str_extract(pattern = "\\d{6}") 


tbl_bbva_debito_pdfs <- tibble(
  date = lubridate::ym(records_bbva_pdfs)
) |> 
  mutate(
    month = lubridate::month(date, label = TRUE, abbr = FALSE),
    mes_order = lubridate::month(date),
    year = lubridate::year(date),
    existe = 1
  ) |> 
  arrange(mes_order, year) |>
  select(-c(mes_order,
            date)) |> 
  mutate(
    existe = if_else(
      existe == 1,
      "💲",
      "🛑"
    )
  ) |> 
  tidyr::pivot_wider(
    names_from = month,
    values_from = existe
  ) |> 
  arrange(desc(year)) |>
  # table with icons change number with icon
  reactable(
    height = 338,
    pagination = FALSE,
    bordered = TRUE,
    striped = TRUE,
    highlight = TRUE,
    sortable = TRUE,
    #align all center
    defaultColDef = colDef(
      align = "center"
    )
  )
  


safe_parse_bbva_debito <- safely(parse_bbva_debito)


parsed_data <- bbva_debito_pdfs |>
  map(safe_parse_bbva_debito) 

bbva_debito_parsed <- parsed_data |>
  map("result") |>
  list_rbind() 

errors_df <- parsed_data |>
  map("error") |>
  list_rbind()




# 
# googlesheets4::gs4_auth(email = "daniel.amieva@dar4datascience.com")
# 
# 
# googlesheets4::sheet_write(                            bbva_debito_parsed,
#                                                        "https://docs.google.com/spreadsheets/d/17byRKCdvydT69Dm7ZftPOdEfpfrCQckpBPGMViySzKY/edit#gid=865252867")
