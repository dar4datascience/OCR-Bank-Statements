
################
#pdftools 
library(pdftools)
library(magrittr)
library(glue)
library(stringr)
library(tesseract)



bbva_test <- file.path(
  here::here('inputs', '202212-BBVACred.pdf')
)

# diferencia entre hojas
tesa_bbva_test_text <- pdf_ocr_text(bbva_test,
                                    language='spa')
