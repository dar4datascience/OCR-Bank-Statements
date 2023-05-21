library(pdftools)
library(magrittr)
library(glue)
library(stringr)
library(tesseract)

# parse rappy financial statements
# rappy_test <- file.path(
#   here::here('inputs', '202210-rappicard.pdf')
# )
rappy_test <- file.path(
  here::here('inputs/rappi prod', '202208-rappicard.pdf')
)


# pdf_text uses lobpoopler
rappy_test_text <- pdf_text(rappy_test)


############ Rapppy deppppppp

# Load the stringr package for text manipulation
library(stringr)
library(tibble)
text <- rappy_test_text

start_marker <- "\\n\\n\\n\\n\\n     Movimientos"
end_marker <- "( TC\\* Tasa de conversión\\n\\n\\n\\n\\n| Compras diferidas\n\n)"
# Find the starting index of the desired text
start_index <- str_locate(text, start_marker)[, "start"]

# Find the ending index of the desired text
end_index <- str_locate(text, end_marker)[, "start"]

# Check if the start and end markers are found
if (!is.na(start_index) && !is.na(end_index)) {
  # Adjust the start index to exclude the marker
  start_index <- start_index + nchar(start_marker)
  
  # Extract the desired text using str_sub
  extracted_text <- str_sub(text, start_index, end_index - 1)
  
  # Print the extracted text
  cat(extracted_text)
} else {
  # Display a message if the markers are not found
  cat("Markers not found in the input string.")
}


###### clean string
# Function to extract strings matching the pattern
extract_strings_with_pattern <- function(text) {
  # Pattern to match strings with the desired pattern
  pattern <- "T[Cc]\\d{2}\\.\\d{2}\\n\\n"
  
  # Extract strings matching the pattern
  extracted_strings <- str_extract_all(text, pattern)[[1]]
  
  return(extracted_strings)
}




semi_clean_text <- extracted_text %>% 
  remove_strings_with_pattern() %>% 
  str_remove_all(., "Extranjero\\n") %>% 
  #remove dollars
  str_remove_all(., "USD \\d+.\\d+") %>% 
  # remove zeors
  str_remove_all(., "\\$0\\.00")


semi_clean_text

# Remove leading and trailing whitespace from each row
rows <- trimws(rows)

# Remove empty rows
rows <- rows[rows != ""]

# Split each row into columns based on whitespace
columns <- strsplit(rows, "\\s+") 


#special remove function
remove_unnecessary_chars <- function(input_string) {
  # Remove "$" from the string
  cleaned_string <- str_replace_all(input_string, "\\$", "")
  
  # Remove "," from the string
  cleaned_string <- str_replace_all(cleaned_string, ",", "")
  
  # Remove "." from the string
  cleaned_string <- str_replace_all(cleaned_string, "\\.", "")
  
  return(cleaned_string)
}


#get gasto in periodo
gasto_en_periodo <- purrr::pluck(columns, -1)
clean_gasto_en_periodo <- gasto_en_periodo %>% 
  dplyr::last() %>% 
  # clean string
  remove_unnecessary_chars() %>% 
  as.numeric()

# remove last recrod and first record and third cause i establish columns
penalast_record <- length(columns) - 1
neccesary_columns <- columns[3:penalast_record]

str_rappy_df <- function(columns_string){
  fechas <- columns_string %>% 
    purrr::pluck(., 1, 1)
  
  montos <- columns_string %>% 
    purrr::pluck(., -1, 1) %>% 
    # clean string
    remove_unnecessary_chars()
  
  conceptos <- columns_string %>% 
    glue::glue_collapse(., sep = "") %>% 
    str_remove(., "\\d{4}-\\d{2}-\\d{2}") %>% 
    str_remove("\\$\\d+.\\d+") %>% 
    # clean string
    remove_unnecessary_chars() 
  
  
  print(fechas)
  print(montos)
  print(conceptos)
  
  df <- tibble(
    "fecha" = fechas,
    "monto" = montos,
    "concepto" = conceptos
  )
  
}

# Create a dataframe from the columns
records_rappy <- neccesary_columns %>% 
  purrr::map_dfr(
    ~str_rappy_df(.x)
  )

# Rename the columns
colnames(records_rappy) <- c("Fecha", "Comercio", "MXN")

library(dplyr)
df_clean_rappy <- records_rappy %>% 
  mutate(
    Comercio = str_remove(Comercio, "\\$") %>% 
      str_remove(., ","),
    Fecha = Fecha %>% 
      lubridate::parse_date_time(., "ymd")
  ) %>% 
  tidyr::fill(Fecha, .direction = "updown")

#add test to equal gasto en periodo to suma de gastos en df