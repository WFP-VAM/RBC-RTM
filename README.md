## Overview

This data pipeline automates the process of RTM/mVAM data management for the RTM core variables related to the key indicators. The standard pipeline procedures are aligned with RBC RTM SOPs that includes a detailed explanation about the methodology applied in this script.

The key objective of the standard pipeline is to maintain the same process of data management across all countries running RTM/mVAM activities.

**The key functions implemented in this standard pipeline are:**

-   Fetching the raw dataset

-   Renaming and selecting core variables

-   Data quality checks

-   Data re-coding and merging

-   Indicators computation

-   Weights construction

-   Connecting to the regional master table

## Pipeline dependencies

### 1) Input file

Before running this pipeline script, you need to update the input file included in the script dependencies *RTM_pipeline_input.xlsx*,

In the first sheet *`main_parameters`* specify the start and end date that you wish to extract the data within. see the points below for more details:

-   **Provider:** Include here the name of the service provider.

-   **SurveyType:** Specify if the survey is RTM or other type of surveys ( include only RTM or Others)

-   **Country Code:** Specify the country code as included in the API key. [Example: Yemen1](Example:Yemen1){.uri} is the country code for Yemen

-   **StartDate:** the first date the you need to extract the data from. It should be in this format MM/DD/YYYY

-   **EndDate:** the last date that you need to extract the data to. It should be in this format MM/DD/YYYY

-   **SvyID**: This is unique ID to differentiate each data collection round. It is sequential for each country. and should be unique across all countries.

In the second sheet *`standard_names_mapping`* include the standard names according to WFP codebook in case the standard variables names were not used in the survey tool, The script will replace the original names with the standard names as indicated in that sheet. This step is essential as all other functions implemented in this script will be relying on the standard variables names

### 2) Calls logs

call logs should be provided by the service provider at the end of each data collection round or upon request. the call logs include the date and time of each call attempt as well as the call attempt status and call duration.

Calls logs template are included in the panelists tracking folder, and it is advisable to maintain the same template before running the pipeline.

Before running the pipeline, make sure that there is only one xlsx file in the folder "Panelists tracking", you can include as many sheets as needed for each country separately. The script will compile all data included in all sheets and conduct the checks for each country.

### 3) Weights input table 

In addition to modifying the input file, make sure that all population figures included in the weights input table file are updated, and the desired indicators are selected.

## RTM/mVAM methodology

RTM/mVAM survey cycle step by step process are explained in the consolidated regional SOPs accessible through this [link](https://wfp.sharepoint.com/:w:/s/RBC-Nearreal-timemonitoringsystem/EfLHfxeUpDJJom9vmhDFVgQB2HAfN0-PxVkXGtflBXSxzQ?e=ySl2b5)

## Working environment

```         
R version 4.2.3 (2023-03-15 ucrt)
Platform: x86_64-w64-mingw32/x64 (64-bit)
Running under: Windows 10 x64 (build 19045)

Matrix products: default

locale:
[1] LC_COLLATE=English_United Kingdom.utf8  LC_CTYPE=English_United Kingdom.utf8   
[3] LC_MONETARY=English_United Kingdom.utf8 LC_NUMERIC=C                           
[5] LC_TIME=English_United Kingdom.utf8    

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:
 [1] jsonlite_1.8.4  httr_1.4.5      readxl_1.4.2    lubridate_1.9.2 forcats_1.0.0  
 [6] stringr_1.5.0   dplyr_1.1.1     purrr_1.0.1     readr_2.1.4     tidyr_1.3.0    
[11] tibble_3.2.1    ggplot2_3.4.1   tidyverse_2.0.0

loaded via a namespace (and not attached):
 [1] cellranger_1.1.0 pillar_1.9.0     compiler_4.2.3   tools_4.2.3     
 [5] digest_0.6.31    timechange_0.2.0 evaluate_0.20    lifecycle_1.0.3 
 [9] gtable_0.3.3     pkgconfig_2.0.3  rlang_1.1.0      cli_3.6.1       
[13] rstudioapi_0.14  curl_5.0.0       yaml_2.3.7       xfun_0.38       
[17] fastmap_1.1.1    withr_2.5.0      knitr_1.42       generics_0.1.3  
[21] vctrs_0.6.1      hms_1.1.3        grid_4.2.3       tidyselect_1.2.0
[25] glue_1.6.2       R6_2.5.1         fansi_1.0.4      rmarkdown_2.21  
[29] tzdb_0.3.0       magrittr_2.0.3   scales_1.2.1     htmltools_0.5.5 
[33] colorspace_2.1-0 utf8_1.2.3       stringi_1.7.12   munsell_0.5.0
```

## 

## Defined functions 

-   **Crystal_API_connect:**

    connect to Crystal database through the API to fetch the raw dataset. the function key parameter is `con_config` which should be a **list** contains the values of the three main API parameters `API_Key` , `Start_date` and `end_date`. Specify the `start_date` and `end_date` within which you need to extract the data. the dates should be in the format *MM/DD/YYYY.*

    The function should return the dataset in a dataframe structure and the status of the call should be 200 indicating a successful connection, other than that make sure that the dataset is ready for extraction and you inserted the correct dates.

-   **replace_variable_names**

    The function auto-replaces the variable names in a dataframe as specified in the pipeline input file, it iterates over each column to replace the variable name.

    it has three main parameters "**data**" the dataset in a dataframe structure, '**old_names**' a vector of the original names and '**new_names**' the new desired names.
