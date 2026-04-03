library(shiny)
library(tidyverse)
library(plotly)

# ══════════════════════════════════════════════════════════════════════════════
# DATA PREPARATION
# ══════════════════════════════════════════════════════════════════════════════

# Initialize path_meta FRESH (prevents many-to-many duplication)
path_meta <- tribble(
  ~path_id,         ~beta,      ~label,                ~colour,   ~dash,
  "via_mc1",        "β₁×β₆",    "lu→mc1→fauna",       "#c2cab2", "dot",
  "via_mc2",        "β₂×β₇",    "lu→mc2→fauna",       "#555d45", "dot",
  "via_root",       "β₅×β₈",    "lu→root→fauna",      "#955f42", "dot",
  "via_mc1_root",   "β₁×β₃×β₈", "lu→mc1→root→fauna",  "#dea88b", "dot",
  "via_mc2_root",   "β₂×β₄×β₈", "lu→mc2→root→fauna",  "#d1855c", "dot",
  "total_indirect", "Σ indir",  "Total indirect",      "#999999", "solid",
  "total_effect",   "Total",    "Total effect",        "#444444", "solid"
)

# Load and clean data
data_sem_results <- read.csv("../output/SEM_results_database.csv", na.strings = c("", "NA")) %>%
  mutate(
    date_start = as.Date(date_start),
    taxon      = if_else(taxon == "all_taxa", "Community", taxon)
  )

indirect_long <- read.csv("../output/indirect_effects.csv", na.strings = c("", "NA")) %>%
  mutate(
    date_start = as.Date(date_start),
    taxon      = if_else(taxon == "all_taxa", "Community", taxon)
  ) %>%
  pivot_longer(
    cols = contains("via") | contains("total"),
    names_to = "path_id", values_to = "std_estimate"
  )

# Combine and Join
plot_data <- bind_rows(
  data_sem_results %>% mutate(path_id = paste0(predictor, "__", response)),
  indirect_long
) %>%
  filter(path_id %in% path_meta$path_id, !is.na(std_estimate)) %>%
  left_join(path_meta, by = "path_id")

taxa_list <- c("Community", sort(setdiff(unique(plot_data$taxon), "Community")))

# Helper function for smoothing
smooth_series <- function(df, span = 0.3) {
  df <- arrange(df, date_start)
  if (nrow(df) < 5) return(mutate(df, smoothed = std_estimate))
  fit <- tryCatch(loess(std_estimate ~ as.numeric(date_start), data = df, span = span),
                  error = function(e) NULL)
  df$smoothed <- if (!is.null(fit)) predict(fit) else df$std_estimate
  df
}

# ══════════════════════════════════════════════════════════════════════════════
# UI & SERVER
# ══════════════════════════════════════════════════════════════════════════════

ui <- fluidPage(
  theme = bslib::bs_theme(bootswatch = "flatly"),
  titlePanel("Eco-Path Dynamics"),
  sidebarLayout(
    sidebarPanel(
      checkboxGroupInput("sel_paths", "Paths", choices = path_meta$path_id, selected = path_meta$path_id),
      checkboxGroupInput("sel_taxa", "Taxa", choices = taxa_list, selected = "Community"),
      sliderInput("span", "Smoothing Intensity", 0, 0.8, 0.3)
    ),
    mainPanel(plotlyOutput("plot", height = "600px"))
  )
)

server <- function(input, output, session) {
  
  # Reactive smoothed data
  smoothed_df <- reactive({
    req(input$sel_paths, input$sel_taxa)
    plot_data %>%
      filter(path_id %in% input$sel_paths, taxon %in% input$sel_taxa) %>%
      group_by(path_id, taxon) %>%
      group_modify(~ smooth_series(.x, span = input$span)) %>%
      ungroup()
  })
  
  output$plot <- renderPlotly({
    df <- smoothed_df()
    req(nrow(df) > 0)
    
    fig <- plot_ly()
    
    # Nested loop to build traces
    for (tx in unique(df$taxon)) {
      for (pid in unique(df$path_id)) {
        sub <- df %>% filter(taxon == tx, path_id == pid)
        if (nrow(sub) < 2) next
        
        # Metadata safeguard
        meta <- path_meta %>% filter(path_id == pid) %>% slice(1)
        
        fig <- fig %>% add_trace(
          data = sub, x = ~date_start, y = ~smoothed,
          type = 'scatter', mode = 'lines',
          name = paste(tx, "|", meta$label),
          line = list(
            color = meta$colour, 
            width = if(tx == "Community") 4 else 1.5,
            dash = if(!is.na(meta$dash) && meta$dash == "dot") "dot" else "solid"
          ),
          opacity = if(tx == "Community") 1 else 0.6
        )
      }
    }
    
    fig %>% layout(hovermode = "closest", template = "minimal")
  })
}

shinyApp(ui, server)