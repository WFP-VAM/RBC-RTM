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
Key functions implemented

-   **Crystal_API_connect:** connect to Crystal database through the API to fetch the raw dataset. the function key parameter is `con_config` which should be a **list** contains the values of the three main API parameters `API_Key` , `Start_date` and `end_date`. Specify the `start_date` and `end_date` within which you need to extract the data. the dates should be in the format *MM/DD/YYYY.* The function should return the dataset in a dataframe structure and the status of the call should be 200 indicating a successful connection, other than that make sure that the dataset is ready for extraction and you inserted the correct dates.
