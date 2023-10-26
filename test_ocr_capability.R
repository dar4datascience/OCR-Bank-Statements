# using package pdftools
here::i_am('test_ocr_capability.R')
################
#pdftools 
library(pdftools)
library(magrittr)
library(here)
library(glue)
library(stringr)
library(tesseract)

hsbc_pdftools_test <- pdf_text(
  here("inputs", "2023-10-06_Estado de cuenta.pdf")
) |> 
  glue::glue_collapse(sep = "|")

# The regular expression to match the content between two words
bonificaciones_seccion <- "(?s)DETALLE DE MOVIMIENTOS(.*?)DETALLE DE COMPRAS"

# Match the regular expression against the string and extract the matched content
matched_content <- hsbc_pdftools_test |> 
  str_extract(pattern = bonificaciones_seccion)

# Define a regular expression pattern to match each line of expenditure
extract_expenditures_by_line <-
  "\\d{2} [A-Z]{3}\\s+[A-Z0-9\\* ]+\\s+[-\\d,\\.]+\\s*"

matched_content |> 
  str_extract_all(pattern = extract_expenditures_by_line)

missing_regex <- "\\d{2} [A-Z]{3}\\s+[A-Z0-9\\* ]+\\s+\\d+(?:,\\d{3})*(?:\\.\\d{2})?"

extracted_strings <- matched_content |> 
  str_extract_all(pattern = missing_regex)



# Initialize an empty dataframe
df <- data.frame(Date = character(0), Concept = character(0), Cost = character(0), stringsAsFactors = FALSE)

# Function to split a string into date, concept, and cost
split_string <- function(string) {
  parts <- strsplit(string, "\\s+", perl = TRUE)[[1]]
  date <- parts[1]
  concept <- paste(parts[2:(length(parts) - 1)], collapse = " ")
  cost <- parts[length(parts)]
  return(c(date, concept, cost))
}

# Iterate through extracted strings and split into columns
for (string in unlist(extracted_strings)) {
  split_result <- split_string(string)
  
  # Append to the dataframe
  df <- df %>% add_row(Date = split_result[1], Concept = split_result[2], Cost = split_result[3])
}

# Print the resulting dataframe
print(df)

# depositos
# Regular expression to match the desired format
# Regular expression to match the desired format
regex_pattern <- "\\d{2}/\\d{2}/\\d{4}\\s+\\d{2}:\\d{2}:\\d{2}\\s+[A-Z0-9\\* ]+\\s+(pagotc\\s+-?\\s?\\d+(?:,\\d{3})*(?:\\.\\d{2}))"


matched_content |> 
  str_extract_all(pattern = regex_pattern)
  
# 
# rappy_test <- file.path(
#   here::here('inputs', '202210-rappicard.pdf')
# )
# 
# bbva_test <- file.path(
#   here::here('inputs', '202212-BBVACred.pdf')
# )
# 
# invex_test <- file.path(
#   here::here('inputs', '2022-12-invex.pdf')
# )
# 
# #using pdf tools package. does a good job. shit part is regex
# # pdf_text uses lobpoopler
# rappy_test_text <- pdf_text(rappy_test)
# 
# bbva_test_text <- pdf_text(bbva_test)
# 
# invex_test_text <- pdf_text(invex_test) %>% 
#   glue::glue_collapse() %>% 
#   #between Detalle de transacciones\n\n and Promociones a Meses Sin Intereses\n\n
#   str_extract(pattern=regex("(?s)(?<=Detalle de transacciones)(.*?)(?=\\s*Promociones a Meses Sin Intereses)"))
# 
# # pdf_ocr_text uses tesseract. doesnt work well with rappy because its a huge long pdf
# #tesa_rappy_test_text <- pdf_ocr_text(rappy_test)
# 
# # diferencia entre hojas
# tesa_bbva_test_text <- pdf_ocr_text(bbva_test,
#                                     language='spa')
# # # here lines cannot be recognized due to image size being too small
# # tesa_invex_test_text <- pdf_ocr_text(invex_test,
# #                                      language='spa')
# 
# 
# 
# 
# # References
# # tabula: https://python.plainenglish.io/how-to-parse-data-tables-from-a-pdf-bank-statement-with-python-ebc3b8dd8990
# # pdftools and tidytext>:https://www.charlesbordet.com/en/extract-pdf/#extract-the-right-information