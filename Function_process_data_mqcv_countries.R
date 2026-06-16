

################################################################
#### Data processing function - process_data_mqcv_countries ####
################################################################

##USE OF THE FUNCTION 
#When providing a dataset with MQ info and one with CV119 invo, The function will return a dataset that contains information on the MQ-events of interest and on the CV19-variable of interest. 
#Scope: for a specific country or data from all countries, excluding specific countries (NOT GLOBAL DATA!). It looks at MQ events on country level (not supra-country or online!)
#It takes into acount
# * which countries to include or exclude from the dataset
# * which product category we look at. (all, medicines, personal_protective_equipment, sanitisers_disinfectants, vaccines, diagnostics, ventilation_oxygenation_equipment_and_consumables)
# * Which covid-variable we are looking at.

###DO NOT USE THE FUNCTION 
#Do not use the function to look at the data on a more global level. It is not fit to look at "OWID_" alpha-3-codes
#Do not use the function for MQ events that are supra-country or online!

#The data prep code is based on the function that is saved in "Function_EDAcorrelations.R"
#In this case we only wanted to keep the step of the data-preparation. Not further plotting, making correlations etc. So we only need a part of the EDAcorrelation function.


#===============================================================================
#===============================================================================

################################
#### MAIN FUNCTION          ####
################################

process_data_mqcv_countries <- function(
    covid_data = data_CV19_monthly,#Data comes from script: "3.dataprep_for_EDA_CV_SF.R"
    mq_data = data_mq,#Data comes from script: "3.dataprep_for_EDA_CV_SF.R"
    inc_countries = NULL,#when this is used, excluding countries not possible
    exc_countries = NULL,#when this is used, including countries is not possible. 
    product_subset = NULL, #when NULL, will use all products combined
    covid_subset = "new_cases") {
  
  # Clean and process data
  covid_cleaned <- covid_data %>%
    filter(!grepl("OWID_", alpha_3_code))
  
  mq_cleaned <- clean_mq_data(mq_data)
  
  # Merge datasets
  joint_data <- full_join(
    mq_cleaned,
    covid_cleaned,
    by = c('year_month', 'alpha_3_code'))
  
  # Filter by countries
  joint_filtered_country <- filter_countries(joint_data, 
                                             inc_countries, exc_countries)
  
  # Apply product and COVID subsets 
  data_subset <- apply_subsets(joint_filtered_country, 
                               product_subset, covid_subset)
  
  # Finalize the data by month
  final_data <- finalise_by_month(data_subset)
  
  return(final_data)
}



################################
#### HELPER FUNCTIONs       ####
################################


### A - Clean and process MQ data 

clean_mq_data<- function (mq_data) {
  
  ## CLEAN DATA
  mq_data <- mq_data %>%
    filter(!grepl("MQ_", alpha_3_code))
  
  ##PROCESS DATA
  #i.e. check for each alpha-3 code the number of events per month and per product subset (or all) 
  mq_data <- mq_data %>%
    group_by(alpha_3_code, year_month, cv19_category_final) %>%
    summarise(mq_events = n(), .groups = 'drop') %>% #Each row is an event THUS sum of rows in this case makes the sum of the events
    pivot_wider(id_cols = c(alpha_3_code, year_month),
                names_from = cv19_category_final,
                values_from = mq_events) %>%
    clean_names() %>% 
    replace(is.na(.), 0) 
  
  # Add the all categories sum
  # First check if columns exist
  product_cols <- c("medicines", 
                    "personal_protective_equipment", 
                    "sanitisers_disinfectants",
                    "vaccines",
                    "diagnostics",
                    "ventilation_oxygenation_equipment_and_consumables")
  # Only use columns that actually exist in the data
  existing_cols <- intersect(product_cols, colnames(mq_data))
  
  if(length(existing_cols) > 0) {
    result <- mq_data %>%
      mutate(mq_events_all_cat = rowSums(
        across(all_of(existing_cols)), na.rm = TRUE))
  } else {
    result <- mq_data %>%
      mutate(mq_events_all_cat = 0)
  }
  
  return(result)
}

#===================================


###B Filter merged dataset by countries
filter_countries <- function(joint_data, inc_countries, exc_countries) {
  # Use `if/else` for clarity and `filter` with `inc_countries`
  if(!is.null(inc_countries)){
    joint_data <- joint_data %>%
      filter(alpha_3_code %in% inc_countries) # Typo fixed
  } else if (!is.null(exc_countries)) { # Use else if
    joint_data <- joint_data %>%
      filter(!alpha_3_code %in% exc_countries) # Simpler, safer filtering
  }
  return(joint_data) # Crucially, the modified data frame is now returned
}


#===================================


###C Apply product and COVID subsets
apply_subsets <- function(joint_filter_country, product_subset, covid_subset) {
  
  ## Apply product subset
  if(is.null(product_subset)) {
    joint_filter_country <- joint_filter_country %>%
      mutate(mq_events = mq_events_all_cat)
  } else {
    # Find column matching product_subset
    matching_col <- which(str_detect(colnames(joint_filter_country), product_subset))
    
    if(length(matching_col) > 0) {
      # Get the column name as a string using the index from `which`
      column_name_to_mutate <- colnames(joint_filter_country)[matching_col[1]]
      
      joint_filter_country <- joint_filter_country %>%
        mutate(mq_events = .data[[column_name_to_mutate]]) # Now using the column name string
    } else {
      joint_filter_country <- joint_filter_country %>%
        mutate(mq_events = 0)
    }
  }
  
  # Replace any missing values (NA) in mq_events with zero
  joint_filter_country <- joint_filter_country %>%
    mutate(mq_events = replace_na(mq_events, 0))
  
  ## Apply COVID subset
  # Find column matching covid_subset
  matching_col <- which(str_detect(colnames(joint_filter_country), str_c("\\b", covid_subset, "\\b")))
  
  if(length(matching_col) > 0) {
    column_name_to_mutate <- colnames(joint_filter_country)[matching_col[1]]
    joint_filter_country <- joint_filter_country %>%
      mutate(cv19_variable = .data[[column_name_to_mutate]])
  } else {
    joint_filter_country <- joint_filter_country %>%
      mutate(cv19_variable = 0)
  }
  
  return(joint_filter_country)
}


#===================================


###D   Finalize the data by month
# Group by month and return just the data
finalise_by_month <- function(data_subset) {
  # generate a variable that countains all months of interest
  months <- data.frame(year_month = c("2020-01-01", "2020-02-01", "2020-03-01",
                                      "2020-04-01", "2020-05-01", "2020-06-01",
                                      "2020-07-01", "2020-08-01", "2020-09-01",
                                      "2020-10-01", "2020-11-01", "2020-12-01",
                                      "2021-01-01", "2021-02-01", "2021-03-01",
                                      "2021-04-01", "2021-05-01", "2021-06-01",
                                      "2021-07-01", "2021-08-01", "2021-09-01",
                                      "2021-10-01", "2021-11-01", "2021-12-01",
                                      "2022-01-01", "2022-02-01", "2022-03-01") 
  ) %>%
    mutate(year_month = floor_date(ymd(year_month), "month")) %>%
    arrange(year_month)
  
  data_subset %>%
    group_by(year_month) %>%
    summarise(
      mq_events = sum(mq_events, na.rm = TRUE),
      cv19_variable = sum(cv19_variable, na.rm = TRUE),
      .groups = 'drop'
    ) %>%
    left_join(months, ., by = "year_month") %>%
    mutate(
      mq_events = replace_na(mq_events, 0), # Consistent NA replacement
    )
}
