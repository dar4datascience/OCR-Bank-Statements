extract_hsbc_relevant_text <- function(filepath_2_pdf) {
  hsbc_text <- pdf_text(filepath_2_pdf) |>
    glue_collapse(sep = "|")
  
  # The regular expression to match the content between two words
  # bonificaciones_seccion <-
  #   "(?s)DETALLE DE MOVIMIENTOS(.*?)DETALLE DE COMPRAS"
    bonificaciones_seccion <-
    "(?s)DETALLE DE MOVIMIENTOS(.*?)considere esta información para evitar que su pago se considere pago vencido."
  
  # Match the regular expression against the string and extract the matched content
  relevant_content <- hsbc_text |>
    str_extract(pattern = bonificaciones_seccion)
  
  return(relevant_content)
}

extract_hsbc_expenditures <- function(hsbc_relevant_content) {
  extract_expenditures_by_line <-
    "\\d{2} [A-Z]{3}\\s+[A-Z0-9\\* ]+\\s+\\d+(?:,\\d{3})*(?:\\.\\d{2})?"
  
  hsbc_relevant_content |>
    str_extract_all(pattern = extract_expenditures_by_line)
  
}

extract_hsbc_pagos <- function(hsbc_relevant_content) {
  extract_pagos_de_tc <-
    "\\d{2}/\\d{2}/\\d{4}\\s+\\d{2}:\\d{2}:\\d{2}\\s+[A-Z0-9\\* ]+\\s+(pagotc\\s+-?\\s?\\d+(?:,\\d{3})*(?:\\.\\d{2}))"
  
  hsbc_relevant_content |>
    str_extract_all(pattern = extract_pagos_de_tc)
  
}

adhoc_split_string <- function(string) {
  # Extract date (e.g., "03 OCT")
  date <- str_extract(string, "\\d{2}\\s+[A-Z]{3}") |> 
    glue_collapse(sep = " ")
  
  # Extract cost (e.g., "1,190.51")
  cost <- str_extract(string, "-?\\s?\\d+(?:,\\d{3})*(?:\\.\\d{2})") |> 
    gsub(pattern = ",", replacement = "") |>
    as.numeric()
  
  # Remove date and cost from the string to get the concept
  concept <- str_replace(string, paste(date, cost, sep = "|"), "") |> 
    str_trim(side = "both")
  
  return(list(Date = date, Concepto = concept, Cost = cost))
}

hsbc_parse_expenditures_2_df <- function(hsbc_expenses_extracted) {
  # Initialize an empty dataframe
  df <-
    data.frame(
      Date = character(0),
      Concept = character(0),
      Cost = double(0),
      stringsAsFactors = FALSE
    )
  
  
  # Iterate through extracted strings and split into columns
  for (string in unlist(hsbc_expenses_extracted)) {
    split_result <- adhoc_split_string(string)
    
    # Append to the dataframe
    df <- df |>
      add_row(Date = unlist(split_result[1]),
              Concept = unlist(split_result[2]),
              Cost = unlist(split_result[3])
      )
  
  }
  
  return(df)
  
}

hsbc_parse_pagos_2_df <- function(hsbc_pagos_extracted) {
  # Extract the relevant information from each line
  data <- lapply(hsbc_pagos_extracted, function(line) {
    parts <- unlist(strsplit(line, "\\s+"))
    date <- paste(parts[1], parts[2])
    concept <- paste(parts[3:6], collapse = " ")
    # Remove commas from the numeric value
    value <- as.numeric(gsub(",", "", parts[length(parts)]))
    data.frame(Date = date, Concept = concept, Cost = value)
  })
  
  # Combine the list of data frames into a single data frame
  df <- do.call(rbind, data)
  
  return(df)
  
}

fully_parse_2_df_hsbc_financial <- function(file_path_2_pdf){
  cli::cli_inform("Extracting relevant text from HSBC PDF")
  hsbc_relevant_content <- extract_hsbc_relevant_text(file_path_2_pdf)
  
  cli::cli_inform("Extracting expenditures from HSBC PDF")
  hsbc_expenditures <- extract_hsbc_expenditures(hsbc_relevant_content)
  
  cli::cli_inform("Parsing expenditures from HSBC PDF")
  hsbc_expenditures_df <- hsbc_parse_expenditures_2_df(hsbc_expenditures) |> 
    filter(!is.na(Cost))
  
  cli::cli_inform("Extracting pagos from HSBC PDF")
  
  hsbc_pagos_extracted <- extract_hsbc_pagos(hsbc_relevant_content)
  
  # if there are no pagos, then return only the expenditures
  if (length(unlist(hsbc_pagos_extracted)) == 0) {
    return(hsbc_expenditures_df)
  }
  
  cli::cli_inform("Parsing pagos from HSBC PDF")
  
  hsbc_pagos_df <- hsbc_parse_pagos_2_df(hsbc_pagos_extracted)
  
  cli::cli_inform("Combining pagos and expenditures from HSBC PDF")
  # combine pagos and expenditures
  full_hsbc <- hsbc_expenditures_df |> 
    bind_rows(hsbc_pagos_df) 
  
  return(full_hsbc)
  
}

month_to_number <- function(date_strings) {
  # Define a mapping of month abbreviations to numeric values
  month_mapping <- c(
    "ENE" = 1, "FEB" = 2, "MAR" = 3, "ABR" = 4,
    "MAY" = 5, "JUN" = 6, "JUL" = 7, "AGO" = 8,
    "SEP" = 9, "OCT" = 10, "NOV" = 11, "DIC" = 12
  )
  # Split the input date strings into day and month parts
  parts <- strsplit(date_strings, " ")
  
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
    "2023",
    result$MonthNumber,
    result$Day, sep = "/")
  
  return(new_date)
}
