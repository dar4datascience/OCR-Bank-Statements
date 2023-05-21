# using package pdftools
here::i_am('test_ocr_capability.R')
################
#pdftools 
library(pdftools)
library(magrittr)
library(glue)
library(stringr)
library(tesseract)



invex_test <- file.path(
  here::here('inputs', '2022-12-invex.pdf')
)



invex_test_text <- pdf_text(invex_test) %>% 
  glue::glue_collapse() %>% 
  #between Detalle de transacciones\n\n and Promociones a Meses Sin Intereses\n\n
  str_extract(pattern=regex("(?s)(?<=Detalle de transacciones)(.*?)(?=\\s*Promociones a Meses Sin Intereses)"))
