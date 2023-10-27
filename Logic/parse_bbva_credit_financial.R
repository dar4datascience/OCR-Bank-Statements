
library(pdftools)
library(dplyr)
library(glue)
library(stringr)
library(tidyr)

parse_bbva_credit_2_df <- function(path_2_bbva_pdfs){

  cli::cli_inform(
    glue("Parsing BBVA Credit PDF: {path_2_bbva_pdfs}")
  )

bbva_credit_text <- pdf_text(path_2_bbva_pdfs) |> 
  glue_collapse(sep = '|') |> 
  str_extract(pattern=regex("(?s)(?<=Movimientos Efectuados)(.*?)(?=\\s*Resumen Informativo de Beneficios)")) |> 
  str_split(pattern = "\\n") |>
  unlist() 


cli::cli_inform(
  glue("Extracting data from BBVA Credit PDF: {path_2_bbva_pdfs}")
)


full_bbva_financial_data <- tibble(
  texto = bbva_credit_text
) |> 
  filter(str_length(texto) > 0) |>
  mutate(
    texto = str_trim(texto, side = "both")
  ) |>
  separate(texto, 
           into = c("Date1",
                    "Date2",
                    "Concept",
                    "RFC",
                    "REFERENCIA",
                    "CARGOS",
                    "ABONOS"),
           sep = "\\s{2,}",
           extra = "merge") |> 
  mutate(
    across(
      where(is.character),
      str_trim,
      side = "both"
    )
  ) |> 
  mutate(
    # detect in Referencias if there is a number that doest start with *
    CARGOS = if_else(
      str_detect(REFERENCIA, regex("\\d+\\.\\d+")),
      str_extract(REFERENCIA, regex("\\d+\\.\\d+")),
      CARGOS
    ),
    # REFERENCIA2 = if_else(
    #   str_detect(REFERENCIA, regex("\\d+\\.\\d+")),
    #   RFC,
    #   REFERENCIA
    # ),
    RFC = if_else(
      str_detect(REFERENCIA, regex("\\d+\\.\\d+")),
      NA_character_,
      RFC
    )
  ) |> 
  mutate(
    CARGOS = CARGOS |> 
      #remvoe everyting thta isnt a digit number or decimal point
      str_remove_all("[^0-9.]") |>
      as.numeric(),
    Concept = str_squish(Concept),
    Date1 = lubridate::dmy(Date1),
    Date2 = lubridate::dmy(Date2)
  ) |> 
  rename(
    fecha_auth = Date1,
    fecha_apli = Date2
  ) |> 
  filter(!is.na(fecha_auth)) |> 
  select(-ABONOS) |>
  rename(
    "Pesos" = CARGOS
  )



return(full_bbva_financial_data)

}
