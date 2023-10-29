library(reticulate)

reticulate::install_python(
  version = "3.9.1")


# Check if the virtual environment exists
if (!reticulate::virtualenv_exists("pdf_miner_reticulate_env")) {
  # Create the virtual environment
  reticulate::virtualenv_create("pdf_miner_reticulate_env",
                                version = "3.9.1",
                                packages = c("pandas", "pdfminer.six"))
}

# Use the virtual environment
reticulate::use_virtualenv("pdf_miner_reticulate_env",
                           required = TRUE)
