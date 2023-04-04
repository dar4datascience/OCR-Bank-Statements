# Combine pdfs
library(pdftools)
pdfs_2_combine <- list.files('~/Documents/OCR-Bank-Statements/inputs/deed house docs')

clean_pdf_paths_2_combine <- purrr::map_chr(pdfs_2_combine,
                                            ~paste0("inputs/deed house docs/", .x))

pdf_combine(input = clean_pdf_paths_2_combine,
            output = 'outputs/house deed full.pdf')

pdf_compress(input= 'outputs/house deed full.pdf',
             output = 'outputs/compressed house deed full.pdf')
