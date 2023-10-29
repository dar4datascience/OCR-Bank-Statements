library(shiny)
library(bslib)
library(purrr) 
library(reactablefmtr)
source(here::here("Logic", "parse_bbva_debito.R"))
source(
    here::here("Logic",
               "pdf_miner_reticulate_env.R")
)
safe_parse_bbva_debito <- safely(shiny_parse_bbva_debito)
ui <- page_fillable(
    theme = bs_theme(bootswatch = "cyborg"),
    layout_sidebar(
        sidebar = sidebar("Sidebar area",
                          fileInput(
                              "pdf_files",
                              "Choose PDF File(s)",
                              accept = ".pdf",
                              multiple = TRUE
                          )
                          ),
       navset_card_tab(
           full_screen = TRUE,
           title = "Views",
           nav_panel(
               "PDFs Uploaded",
               card_title("PDFs by Year and Month"),
               reactableOutput("contents")
           ),
           nav_panel(
               "Parse Financial Data",
               card_title("Parsed PDFs"),
               reactableOutput("bbva_debito_parsed")
           ),
           nav_panel(
               shiny::icon("circle-info"),
               markdown("Learn more about [htmlwidgets](http://www.htmlwidgets.org/)")
           )
       )
    )
)

server <- function(input, output) {
    
    # observeEvent(input$pdf_files, {
    #     print(input$pdf_files)
    # })
    
    output$contents <- renderReactable({
        req(input$pdf_files)
        
        records_bbva_pdfs <- input$pdf_files |>
            pull(name) |> 
            str_extract(pattern = "\\d{6}")
        
        tbl_2_calendar <-
        tibble(date = lubridate::ym(records_bbva_pdfs)) |>
            mutate(
                month = lubridate::month(date, label = TRUE, abbr = FALSE),
                mes_order = lubridate::month(date),
                year = lubridate::year(date),
                existe = 1
            ) |>
            arrange(mes_order, year) |>
            select(-c(mes_order,
                      date)) |>
            mutate(existe = if_else(existe == 1,
                                    "💲",
                                    "🛑")) |>
            tidyr::pivot_wider(names_from = month,
                               values_from = existe) 
        
        tbl_2_calendar |>
            arrange(desc(year)) |>
            # table with icons change number with icon
            reactable(
                theme = cyborg(),
                height = 338,
                pagination = FALSE,
                bordered = TRUE,
                striped = TRUE,
                highlight = TRUE,
                sortable = TRUE,
                #align all center
                defaultColDef = colDef(align = "center"
                                       )
            )
    })
    

# parse pdf BBVA ----------------------------------------------------------
    # Create a reactiveValue object
    df <- reactiveValues(data = NULL)
    
    observeEvent(input$pdf_files, {

        req(input$pdf_files)
        
        parsed_data <-  map2(input$pdf_files$datapath, input$pdf_files$name, safe_parse_bbva_debito) 
        
        df$data <- parsed_data |>
            map("result") |>
            list_rbind() 
    })
    

# TABLE RESULTS OF PARSING ------------------------------------------------

    output$bbva_debito_parsed <- renderReactable({
        req(input$pdf_files)
        
        parsed_bbva_df <- df$data
        
        parsed_bbva_df |>
            reactable(
                theme = cyborg(),
                pagination = FALSE,
                bordered = TRUE,
                striped = TRUE,
                highlight = TRUE,
                sortable = TRUE,
                #align all center
                defaultColDef = colDef(align = "center")
            )
    })    
}

shinyApp(ui, server)
