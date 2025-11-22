estimate_polyphenols = function(
    diet_input_file = "user_inputs/VVKAJ_Items.csv",  # default path
    type = c("ASA24", "NHANES"), 
    output = c("html", "md")
) {

  # Match user input
  type = match.arg(type)   # ensures type is a single string
  output = match.arg(output)
  
  # Install and load required packages
  source("functions/startup_functions.R")
  install_if_missing(c("tidyverse", "readxl", "rmarkdown"))
  suppressMessages(library(tidyverse))
  library(rmarkdown)
  
  # Confirm dietary type file exists
  if (!file.exists(diet_input_file)) {
    stop("Diet recall data file not found: ", diet_input_file)
  } else {
    message("Found diet recall data file.\n")
  }
  
  # Read data
  diet_dat = tryCatch(
    vroom::vroom(diet_input_file, show_col_types = FALSE),
    error = function(e) stop("Unable to read diet recall file: ", e$message)
  )
  
  # Make diet_input_file visible everywhere
  assign("diet_input_file", diet_input_file, envir = .GlobalEnv)
  
  ##########################################
  # Data Check Status Message
  ##########################################
  required_col = if (identical(type, "ASA24")) "FoodCode" else "DRXIFDCD"
  if (!required_col %in% names(diet_dat)) {
    stop("The diet data file must contain the column '", required_col, "' for ", type, ".")
  } else {
    message("Required column for ", type, " exists.\n")
  }
  
  ##########################################
  # Check multiple recalls per participant
  ##########################################
  # Determine ID column based on type source
  id_var = if (identical(type, "ASA24")) "UserName" else "SEQN"
  
  # Check that ID column exists
  if (!id_var %in% names(diet_dat)) {
    stop("The diet data file must contain the column '", id_var, "' for ", type, ".")
  }
  
  # Obtain recall counts by user
  recalls_per_user = diet_dat %>%
    group_by(.data[[id_var]]) %>%
    summarise(n_recalls = n_distinct(RecallNo), .groups = "drop")
  
  # Recall Status Message
  if (max(recalls_per_user$n_recalls, na.rm = TRUE) < 2) {
    stop("The diet recall file does not contain multiple recalls per participant.")
  } else {
    message("Multiple recalls detected across participants.\n")
  }
  
  ##########################################
  # Define steps based on data source
  ##########################################
  polyphenol_steps = if (identical(type, "ASA24")) {
    file.path("scripts", c(
      "STEP1_ASA24_FDD_Disaggregation.Rmd",
      "STEP2_FDD_FooDB_Content_Mapping.Rmd",
      "STEP3a_Polyphenol_Summary_Total.Rmd",
      "STEP3b_Polyphenol_Summary_Class.Rmd",
      "STEP3c_Polyphenol_Summary_Compound.Rmd",
      "STEP3d_Polyphenol_Summary_Food_Contributors.Rmd"
    ))
  } else {
    file.path("scripts", c(
      "STEP1_NHANES_FDD_Disaggregation.Rmd",
      "STEP2_FDD_FooDB_Content_Mapping.Rmd",
      "STEP3a_Polyphenol_Summary_Total.Rmd",
      "STEP3b_Polyphenol_Summary_Class.Rmd",
      "STEP3c_Polyphenol_Summary_Compound.Rmd",
      "STEP3d_Polyphenol_Summary_Food_Contributors.Rmd"
    ))
  }
  
  # Ensure we have flexibility to render different reports
  render_fun = switch(output, 
                      html = run_create_html_report, 
                      md = run_create_md_report)
  
  # Creates a report directory
  if (!dir.exists("reports")) dir.create("reports", recursive = TRUE)
  
  message("Pipeline will now start and generate ", output, " reports.\n")
  start_time = Sys.time()
  
  ##########################################
  # Run scripts
  ##########################################
  for (script in polyphenol_steps) {
    tryCatch({
      render_fun(script)
      message("Completed: ", script, "\n")
    }, error = function(e) {
      stop("Error in ", script, ": ", e$message)
    })
  }
  
  ##########################################
  # Runtime summary
  ##########################################
  end_time = Sys.time()
  total_seconds = as.numeric(difftime(end_time, start_time, units = "secs"))
  message("Polyphenol estimation pipeline completed successfully.")
  message("Total runtime: ", floor(total_seconds/60), " min ", round(total_seconds %% 60), " sec")
}
