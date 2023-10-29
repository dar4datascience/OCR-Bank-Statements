library(pdfminer)
library(stringr)
library(lubridate)
library(purrr)
library(dplyr)
library(tidyr)
library(glue)

month_to_number <- function(year_of_file,
                            date_strings) {
  # Define a mapping of month abbreviations to numeric values
  month_mapping <- c(
    "ENE" = "01",
    "FEB" = "02",
    "MAR" = "03",
    "ABR" = "04",
    "MAY" = "05",
    "JUN" = "06",
    "JUL" = "07",
    "AGO" = "08",
    "SEP" = "09",
    "OCT" = "10",
    "NOV" = "11",
    "DIC" = "12"
  )
  
  # Split the input date strings into day and month parts
  parts <- strsplit(date_strings, "/")
  
  # Extract the day and month from each date string
  days <- as.integer(sapply(parts, `[`, 1))
  month_abbreviations <- sapply(parts, `[`, 2)
  
  # Map the month abbreviations to numeric values
  month_numbers <- month_mapping[month_abbreviations]
  
  # Create a data frame or a list with the results
  result <- data.frame(Day = days, MonthAbbreviation = month_abbreviations, MonthNumber = month_numbers)
  # If you prefer a list, use the following line instead:
  # result <- list(Day = days, MonthAbbreviation = month_abbreviations, MonthNumber = month_numbers)
  
  new_date <- paste(
    year_of_file,
    result$MonthNumber,
    result$Day, sep = "/")
  
  return(new_date)
}

shiny_parse_bbva_debito <- function(datapath, file_name){
  # 
  # bbva_nomina_test <- fs::dir_ls(
  #   here::here("inputs",
  #        "lulu bbva nomina")
  # )
  
  cli::cli_inform(
    glue("Extracting all the text from the pdf: {datapath}")
  )
  
  pdf_data <- read.pdf(datapath, method = "csv") |> 
    pluck("text") |> 
    pluck("text") |> 
    glue_collapse(sep = '')
  
  bbva_text <- pdf_data |> 
    str_extract(pattern = regex("(?s)(?<=Movimientos Realizados)(.*?)(?=\\s*Total de Movimientos)")) |> 
    str_split(pattern = "\\n") |>
    unlist() 
  
  year_of_file <- 
    file_name |> 
    basename() |> 
    str_extract(pattern = "\\d{4}") 
  
  full_bbva_debito_data <- tibble(
    texto = bbva_text
  ) |> 
    filter(str_length(texto) > 0) |>
    mutate(
      texto = str_trim(texto, side = "both")
    ) |>
    separate(texto, 
             into = c("fecha_operacion",
                      "fecha_liquidacion",
                      "descripcion",
                      #   "referencia",
                      "cargos",
                      "abonos",
                      "saldo_operacion",
                      "saldo_liquidacion"
             ),
             sep = "\\s{2,}",
             extra = "merge") |> 
    mutate(
      across(
        where(is.character),
        \(x) str_trim(x, side = "both")
      )
    ) |> 
    select(-c(saldo_operacion,
              saldo_liquidacion,
              abonos)) |>
    rename(
      'pesos' = cargos
    ) |> 
    mutate(
      pesos = pesos |> 
        #remvoe everyting thta isnt a digit number or decimal point
        str_remove_all("[^0-9.]") |>
        as.numeric(),
      descripcion = str_squish(descripcion),
      year_of_file = year_of_file,
      fecha_operacion = month_to_number(year_of_file,
                                        fecha_operacion) |> 
        lubridate::ymd(),
      fecha_liquidacion = month_to_number(year_of_file,
                                          fecha_liquidacion) |> 
        lubridate::ymd()
    ) |> 
    filter(!is.na(fecha_operacion)) |> 
    select(-year_of_file) 
  
  return(full_bbva_debito_data)
}
