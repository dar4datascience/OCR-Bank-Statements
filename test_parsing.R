# test parsing of files

# rappy parse> return code to parse into a df named movimientos rappi with the columns fecha, comercio, mxn
#rappy_test_text
library(stringr)
# extract transactions table
transactions_str <-
  str_extract(rappy_test_text, "(Movimientos)[^,]+Comercio.+?\\n\\n\\n")

transactions_lines <- str_split(transactions_str, '\\n')[[1]]

transactions_lines <-
  transactions_lines[grepl("\\d{4}-\\d{2}-\\d{2}", transactions_lines)]

transactions_df <-
  data.frame(do.call(rbind, str_split_fixed(transactions_lines, ' +', n =
                                              3)))
colnames(transactions_df) <- c("fecha", "comercio", "mx")