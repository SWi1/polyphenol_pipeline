# ============================================================
# Run the Polyphenol Estimation Pipeline
# Built by: Stephanie Wilson
# Date: November 2025
# ============================================================

# SET WORKING DIRECTORY
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# SOURCE FUNCTIONS
# ------------------------------------------------------------
source('functions/estimate_polyphenols.R')
source('functions/calculate_DII.R')

# RUN THE POLYPHENOL ESTIMATION PIPELINE
# ------------------------------------------------------------
# diet_input_file = 'user_inputs/update_this_path.csv'
# type, specify "ASA24" or "NHANES"
# output, specify "html" or "md" for your reports
estimate_polyphenols(diet_input_file = 'user_inputs/VVKAJ_Items.csv',
                     type = "ASA24", output = "md") 

# CALCULATE DIETARY INFLAMMATORY INDEX
# ------------------------------------------------------------
calculate_DII(output = "md")