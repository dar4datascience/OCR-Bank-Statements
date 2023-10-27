parse_invex_financial_records <- function(input_string) {
  # Split the input string into lines
  lines <- unlist(strsplit(input_string, "\n"))
  
  # Initialize empty vectors to store the extracted values
  dates <- character(0)
  descriptions <- character(0)
  values <- numeric(0)
  
  # Loop through the lines and extract the desired information
  for (line in lines) {
    # Use regular expressions to match date, description, and value
    if (grepl("\\d{2}/\\d{2}/\\d{4}", line)) {
      date <- gsub(" ", "", regmatches(line, regexpr("\\d{2}/\\d{2}/\\d{4}", line)))
      desc_value <- gsub(" ", "", regmatches(line, regexpr("\\$[0-9,.]+", line)))
      description <- gsub(date, "", line)
      description <- gsub(desc_value, "", description)
      value <- as.numeric(gsub("[$,]", "", desc_value))
      
      # Append the extracted values to the vectors
      dates <- c(dates, date)
      descriptions <- c(descriptions, description)
      values <- c(values, value)
    }
  }
  
  # Create a data frame with the extracted values
  transactions_df <- data.frame(
    Fecha = dates,
    Descripción = descriptions,
    Importe = values
  ) |> 
    #CLEAN DATA
    janitor::clean_names() |>
    mutate(
      descripcion = str_replace(descripcion, "\\$[0-9,]+(\\.[0-9]+)?", "")
    ) |>
    mutate(descripcion = str_trim(descripcion)) |> 
    mutate(
      fecha = dmy(fecha)
    )
  
  return(transactions_df)
}


extract_invex_transacciones_data <- function(invex_pdf_file_path){
  
  invex_relevant_data_text <- pdf_text(invex_pdf_file_path) %>% 
    glue::glue_collapse() %>% 
    #between Detalle de transacciones\n\n and Promociones a Meses Sin Intereses\n\n
    str_extract(pattern=regex("(?s)(?<=Detalle de transacciones)(.*?)(?=\\s*Promociones a Meses Sin Intereses)"))
}


parse_invex_financial_2_df <- function(invex_pdf_file_path){
  #name of pdf file
  cli::cli_inform(
    glue::glue("Extracting relevant text from Invex PDF file: {invex_pdf_file_path}")
  )
  invex_relevant_data_text <- invex_pdf_file_path |>  extract_invex_transacciones_data()
  
  invex_tbl_transaccions <- invex_relevant_data_text |>
    parse_invex_financial_records()
  
}

# invex_test <- file.path(
#   here::here('inputs', '2022-12-invex.pdf')
# )
# 


# invex_test_text <- pdf_text(invex_test) %>% 
#   glue::glue_collapse() %>% 
#   #between Detalle de transacciones\n\n and Promociones a Meses Sin Intereses\n\n
#   str_extract(pattern=regex("(?s)(?<=Detalle de transacciones)(.*?)(?=\\s*Promociones a Meses Sin Intereses)"))



# invex_tbl_transaccions <- invex_test_text |>
#   parse_invex_financial_records() 
