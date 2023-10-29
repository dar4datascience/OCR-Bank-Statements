unlink("docs", recursive = TRUE)
# Config for github pages deployment
shinylive::export(
  appdir = "OCR-with-webR",
  destdir = "docs"
)

httpuv::runStaticServer(dir = "/home/duque/Documents/OCR-Bank-Statements/docs", port = 8988)

