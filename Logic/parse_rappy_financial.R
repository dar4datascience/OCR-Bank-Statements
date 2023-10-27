## Functions to parse Rappi Financial Statements 2022:2023
remove_TC_pattern <- function(text) {
  # Pattern to match strings with the desired pattern
  pattern <- "T[Cc]\\d{2}\\.\\d{2}\\n\\n"
  
  # Extract strings matching the pattern
  clean_strings <- str_remove_all(text, pattern)[[1]]
  
  return(clean_strings)
}
extract_seccion_movimientos <- function(string){
  start_marker <- "\\n\\n\\n\\n\\n     Movimientos"
  end_marker <- "(  Total pagos del periodo | TC\\* Tasa de conversión\\n\\n\\n\\n\\n| Compras diferidas\n\n)"
  
  # Find the starting index of the desired text
  start_index <- str_locate(string, start_marker)[, "start"]
  
  # Find the ending index of the desired text
  end_index <- str_locate(string, end_marker)[, "start"]
  
  # Check if the start and end markers are found
  if (!is.na(start_index) && !is.na(end_index)) {
    # Adjust the start index to exclude the marker
    start_index <- start_index + nchar(start_marker)
    
    # Extract the desired text using str_sub
    extracted_text <- str_sub(string, start_index, end_index - 1)
    
    # Print the extracted text
    #cat(extracted_text)
  } else {
    # Display a message if the markers are not found
    cat("Markers not found in the input string.")
  }
  
}

remove_marcas_extranjero <- function(string_extracted_text){
  semi_clean_text <- string_extracted_text %>% 
    remove_TC_pattern() %>% 
    str_remove_all(., "Extranjero\\n") %>% 
    #remove dollars
    str_remove_all(., "USD \\d+.\\d+") %>% 
    # remove zeors
    str_remove_all(., "\\$0\\.00")
}

split_trim_remove_n_split <- function(semi_clean_text){
  # Split the string into rows based on line jumps
  rows <- strsplit(semi_clean_text, "\n")[[1]]
  # Remove leading and trailing whitespace from each row
  rows <- trimws(rows)
  # Remove empty rows
  rows <- rows[rows != ""]
  # Split each row into columns based on whitespace
  columns <- strsplit(rows, "\\s+") 
 # print(columns)
  return(columns)
}
#special remove function
remove_unnecessary_chars <- function(input_string) {
 # print(input_string)
  # Remove "$" from the string
  cleaned_string <- str_replace_all(input_string, "\\$", "")
  
  # Remove "," from the string
  cleaned_string <- str_replace_all(cleaned_string, ",", "")
  
  return(cleaned_string)
}
get_gasto_periodo <- function(text_by_columns){
  #print(text_by_columns)
  #get gasto in periodo
  gasto_en_periodo <- purrr::pluck(text_by_columns, -1)
  clean_gasto_en_periodo <- gasto_en_periodo %>% 
    dplyr::last() %>% 
    # clean string
    remove_unnecessary_chars() %>% 
    as.numeric()
  
  return(clean_gasto_en_periodo)
}
remove_unnecesarry_columns <- function(text_by_columns){
  # remove last recrod and first record and third cause i establish columns
  penalast_record <- length(text_by_columns) - 1
  neccesary_columns_string <- text_by_columns[3:penalast_record]
  #print(text_by_columns)
  #print(neccesary_columns_string)
  return(neccesary_columns_string)
}

structure_rappy_df <- function(neccesary_columns_string){
  #print(neccesary_columns_string)
  fechas <- neccesary_columns_string %>% 
    purrr::pluck(., 1, 1)
  #print(fechas)
  
  montos <- neccesary_columns_string %>% 
    purrr::pluck(., -1, 1) %>% 
    # clean string
    remove_unnecessary_chars()
  
  conceptos <- neccesary_columns_string %>% 
    glue::glue_collapse(., sep = "") %>% 
    str_remove(., "\\d{4}-\\d{2}-\\d{2}") %>% 
    str_remove("\\$\\d+.\\d+") %>% 
    # clean string
    remove_unnecessary_chars() %>% 
    str_remove("\\.\\d{2}")
  
  
  # print(fechas)
  # print(montos)
  # print(conceptos)
  
  df <- tibble(
    "fecha" = fechas,
    "monto" = montos,
    "concepto" = conceptos
  )
  
  return(df)
  
}
create_records_rappi_df <- function(neccesary_columns){
  # Create a dataframe from the columns
  records_rappy <- neccesary_columns %>% 
    purrr::map_dfr(
      ~structure_rappy_df(.x)
    )
  
  # Rename the columns
  colnames(records_rappy) <- c("Fecha", "Monto", "Comercio")
  
  return(records_rappy)
  
}
final_clean_df <- function(records_rappy){
  df_clean_rappy <- records_rappy %>% 
    mutate(
      Comercio = str_remove(Comercio, "\\$") %>% 
        str_remove(., ","),
      Fecha = Fecha %>% 
        lubridate::parse_date_time(., "ymd", quiet = TRUE),
      Monto = as.numeric(Monto)
    ) %>% 
    tidyr::fill(Fecha, .direction = "updown") %>% 
    filter(!stringr::str_detect(Comercio, "^TC")) %>% 
    #remove pago por spei and negative_numbers:puedes extraer el valor de monto pagado ala tc en otro momento
    filter(Monto>0,
           !is.na(Monto))
  
  return(df_clean_rappy)
}
validate_gasto_total_vs_suma_montos <- function(clean_gasto_en_periodo, df_clean_rappy){
  suma_montos <- df_clean_rappy %>% 
    summarize(
      total_gasto = sum(Monto, na.rm = TRUE)
    )
  
  rule_validacion <- round(clean_gasto_en_periodo, digits = 2) == round(suma_montos$total_gasto, digits = 2)
  
  if(rule_validacion==FALSE){
    print("Los montos no son iguales. La diferencia del monto total vs la suma de montos es de: ")
    diferencia <- round(clean_gasto_en_periodo, digits = 2) - round(suma_montos$total_gasto, digits = 2)
    print(diferencia)
  }else{
    print("Los montos coinciden! Te mereces un gansito!")
  }
  
}


##### Final Function ##########
extract_financial_data_into_df <- function(pdf_path){
  print("pdf_text")
  # apply pdf text extraction
  # pdf_text uses lobpoopler
  rappy_test_text <- pdf_text(pdf_path)
  print("extract seccion movimientos")
  extracted_text <- rappy_test_text %>% 
    extract_seccion_movimientos()
  print("remove marcas extranjero")
  semi_clean_text <- extracted_text %>% 
    remove_marcas_extranjero()
  
  print("split trim remove n split")
  text_by_columns <- semi_clean_text %>% 
    split_trim_remove_n_split()
  
  #print(text_by_columns)
  
  print("get gasto periodo")
  # you need this for validation
  clean_gasto_en_periodo <- text_by_columns %>% 
    get_gasto_periodo() 
  
  print("remove unnecesarry columns")
  # continue parsing
  neccesary_columns_string <- text_by_columns %>% 
    remove_unnecesarry_columns()
  print("create records rappi df")
  records_rappy <- neccesary_columns_string %>% 
    create_records_rappi_df()
  print("final clean df")
  df_clean_rappy <- records_rappy %>% 
    final_clean_df()
  print("validate gasto total")
  #validate
  validate_gasto_total_vs_suma_montos(clean_gasto_en_periodo,df_clean_rappy)
  
  return(df_clean_rappy)
}
