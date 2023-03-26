# using package pdftools
here::i_am('test_ocr_capability.R')
################
#pdftools 
library(pdftools)
library(magrittr)
library(glue)
library(stringr)

rappy_test <- file.path(
  here::here('inputs', '202210-rappicard.pdf')
)

bbva_test <- file.path(
  here::here('inputs', '202212-BBVACred.pdf')
)

invex_test <- file.path(
  here::here('inputs', '2022-12-invex.pdf')
)

#using pdf tools package. does a good job. shit part is regex
# pdf_text uses lobpoopler
rappy_test_text <- pdf_text(rappy_test)

bbva_test_text <- pdf_text(bbva_test)

invex_test_text <- pdf_text(invex_test) %>% 
  glue::glue_collapse() %>% 
  #between Detalle de transacciones\n\n and Promociones a Meses Sin Intereses\n\n
  str_extract(pattern=regex("(?s)(?<=Detalle de transacciones)(.*?)(?=\\s*Promociones a Meses Sin Intereses)"))

# pdf_ocr_text uses tesseract. doesnt work well with rappy because its a huge long pdf
#tesa_rappy_test_text <- pdf_ocr_text(rappy_test)

# diferencia entre hojas
tesa_bbva_test_text <- pdf_ocr_text(bbva_test,
                                    language='spa')
# here lines cannot be recognized due to image size being too small
tesa_invex_test_text <- pdf_ocr_text(invex_test,
                                     language='spa')


# References
# tabula: https://python.plainenglish.io/how-to-parse-data-tables-from-a-pdf-bank-statement-with-python-ebc3b8dd8990
# pdftools and tidytext>:https://www.charlesbordet.com/en/extract-pdf/#extract-the-right-information