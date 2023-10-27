library(pdftools)
library(stringr)
library(lubridate)
library(purrr)
library(dplyr)
library(tidyr)
library(glue)

parse_baz_financial_nomina <- function(path_2_baz_pdf){
  cli::cli_inform(
    glue("Extracting all the text from the pdf: {path_2_baz_pdf}")
  )
  
  baz_text <- 
    pdf_text(path_2_baz_pdf,
             upw = Sys.getenv("RFC")
    ) |> 
    glue::glue_collapse(sep = "") 
  
  # BAZ tiene 3 partes. Movimientos internos, Depositos, Retiros
  
  
  # Alcancia Parse ----------------------------------------------------------
  cli::cli_inform(
    glue("Extracting Alcancia from the pdf: {path_2_baz_pdf}")
  )
  
  baz_alcancia_text <- baz_text |>
    str_extract("(?s)Movimientos del mes(.*?)Total Depósitos del mes") |> 
    str_split(pattern = "\\n") |> 
    unlist()
  
  
  
  baz_alcancia_df <- tibble(
    text = baz_alcancia_text
  ) |> 
    filter(str_length(text) > 0) |>
    mutate(
      text = str_trim(text, side = "both")
    ) |> 
    separate(text,
             into = c("Fecha", "Concepto", "Monto_de_la_Operación", "Nombre_del_sueño"), 
             sep = "\\s{2,}") |> 
    mutate(across(everything(), str_squish)) |> 
    mutate(
      Monto_de_la_Operación = as.numeric(gsub("[^0-9.]", "", Monto_de_la_Operación)),
      Fecha = dmy(Fecha)
    ) |> 
    filter(
      !is.na(Fecha)
    ) |> 
    mutate(
      source = "alcancia"
    )
  
  
  
  # Retiros Parse -----------------------------------------------------------
  
  cli::cli_inform(
    glue("Extracting Retiros from the pdf: {path_2_baz_pdf}")
  )
  # retiros
  # Split the text based on "Total de Retiros del mes"
  baz_retiros_text <- baz_text |>
    str_extract("(?s)Total de Retiros del mes(.*?)Comisiones que aplicaron en el mes en mi cuenta a la vista") |> 
    str_split(pattern = "\\n") |> 
    unlist()
  
  baz_retiros_df <- tibble(
    text = baz_retiros_text
  ) |> 
    filter(str_length(text) > 0) |>
    mutate(
      text = str_trim(text, side = "both")
    ) |> 
    separate(text,
             into = c("Fecha", "Concepto", "Monto_de_la_Operación", "Lugar_o_Canal_de_Operación"), 
             sep = "\\s{2,}") |> 
    mutate(across(everything(), str_squish)) |> 
    mutate(
      Monto_de_la_Operación = as.numeric(gsub("[^0-9.]", "", Monto_de_la_Operación)),
      Fecha = dmy(Fecha)
    ) |> 
    filter(
      !is.na(Fecha)
    ) |> 
    mutate(
      source = "retiros"
    )
  
  
  # Abonos Parse ------------------------------------------------------------
  
  cli::cli_inform(
    glue("Extracting Abonos from the pdf: {path_2_baz_pdf}")
  )
  
  #ABAONOS
  baz_abonos_text <- baz_text |>
    str_extract("(?s)Total Depósitos del mes(.*?)Cuánto recibí de interés en el mes en mi cuenta a la vista") |> 
    str_split(pattern = "\\n") |> 
    unlist()
  
  
  baz_abonos_df <- tibble(
    text = baz_abonos_text
  ) |> 
    filter(str_length(text) > 0) |>
    separate(text,
             into = c("Fecha", "Concepto", "Monto_de_la_Operación", "Lugar_o_Canal_de_Operación"), 
             sep = "\\s{2,}") |> 
    mutate(across(everything(), str_squish)) |> 
    mutate(
      Monto_de_la_Operación = as.numeric(gsub("[^0-9.]", "", Monto_de_la_Operación)),
      Fecha = dmy(Fecha)
    ) |> 
    filter(
      !is.na(Fecha)
    ) |>
    mutate(
      source = "abonos"
    )
  
  
  # Combine -----------------------------------------------------------------
  cli::cli_inform(
    glue("Combining all the data from the pdf: {path_2_baz_pdf}")
  )
  full_baz_df <- baz_alcancia_df |> 
    bind_rows(
      baz_retiros_df,
      baz_abonos_df
    ) 
  
  return(full_baz_df)
}



