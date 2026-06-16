## R code for doctoral thesis: Leveraging online news media data to investigate poor-quality medical products. Insights from the COVID-19 pandemic.
R code and analysis for the doctoral thesis of Kerlijn Van Assche

# Overview
This repository contains the R code used in my doctoral research on "Leveraging online news media data to investigate poor-quality medical products. Insights from the COVID-19 pandemic."
The code shared is specifically linked to "Chapter 6: pandemic pressure and product quality. A time series perspective". 
For more explanation on the data and methods used and for interpretation of the results, consult the thesis manuscript. 

  Aim of chapter 6: To examine the temporal association between new COVID-19 cases and poor-quality medical product (PQ-MP) events and to identify whether increases in COVID-19 cases precede increases in PQ-MP events. 
  The study uses cross-correlation analysis to explore potential lag structures between the two time series. 
  --> In India and USA, distinct patterns were observed between COVID-19 case counts and PQ-MP events. However, cross-correlation coefficients were small and non-significant.  

# Repository structure
- data    # Data for new COVID-19 cases and for PQ-MP events 
- R/      # Scripts/functions
- Outputs #  Markdown extract from the code including figures, tables and results
- README.md

# Methods
The analysis includes data preparation, visualisation and cross-correlation analysis for India and for the United States of America
    1. Data preparation
    2. Plotting
    3. Cross-correlations (incl stationarity & autocorrelation) 
            Step 0: Define the time series
            Step 1: Stationarity check and differencing
            Step 2: Autocorrelation analysis using ACF and PACF
            Step 3: baseline cross-correlation on stationary data
            Step 4: Prewhitened cross-correlation 
            
# Reproducibility    
All scripts are written in R. 
The data for chapter 6 were shared in this Github project. 

# Author
Kerlijn Van Assche 
DPhil researcher, University of Oxford
Contact via: kerlijn.vanassche@ndm.ox.ac.uk
