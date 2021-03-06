#' Get Selected Food Loss Data
#'
#' Function to obtain official food loss data at primary level 
#'
#' @export getSelectedLossData

getSelectedLossData = function(){
  
  
  ##################################################################################################
  ##   Code to get Import data from the Old System 
  ##################################################################################################
  ##  
  ##   measuredItemFS = ReadDatatable(table = "loss_food_group") %>%
  ##     select(measured_item_fs,food_general_group,measured_item_cpc) %>%
  ##     filter(food_general_group == "primary")
  ##   
  ##   
  ##   lossQuery = data.table(sws_query(area = 1:299, 
  ##                                    item = as.character(measuredItemFS$measured_item_fs), 
  ##                                    ele = 121, 
  ##                                    year = 1961:2015, 
  ##                                    value.names = F
  ##   ))
  ##   
  ##   
  ##   setnames(lossQuery, 
  ##            old = c(names(lossQuery)),
  ##            new = c("geographicAreaFS","measuredItemFCL","measuredElement","timePointYears",
  ##                    "Value_measuredElement_5120","flagObservationStatus_measuredElement_5120")
  ##   )
  ##   
  ##   lossQuery = 
  ##     lossQuery%>%
  ##     select(geographicAreaFS,measuredItemFCL,timePointYears,
  ##            Value_measuredElement_5120,flagObservationStatus_measuredElement_5120)
  ##   
  ##   
  ##   ## Convert measuredItemFCL to measuredItemCPC
  ##   ##   lossQuery[, measuredItemCPC := faoswsUtil::cpc2fcl(as.character(measuredItemFCL))]
  ##   
  ##   ## Convert geographicAreaFS to geographicAreaM49
  ##   ##   lossQuery[, geographicAreaM49 := faoswsUtil::fs2m49(as.character(geographicAreaFS))]
  ##   
  ##   
  ##   ## Convert time to numeric
  ##   lossQuery[, timePointYears := as.numeric(timePointYears)]
  ##   
  ##   ## Taking only official data
  ##   lossQuery = lossQuery[flagObservationStatus_measuredElement_5120 == " ", ]
  ##   
  ##   ## Adding headings to FCL codes
  ##   lossQuery[, measuredItemFCL := addHeadingsFCL(measuredItemFCL)]
  ##   
  ###################################################################################################  
  #
  #
  ##################################################################################################
  ##   Code to get Import data from the New System 
  ##################################################################################################
  
  allCountries =
    GetCodeList(domain = "agriculture",
                dataset = "aproduction",
                dimension = "geographicAreaM49")[type == "country", code]
  
  ## Convert geographicAreaM49 to geographicAreaFS  
  allCountriesFS = faoswsUtil::m492fs(as.character(allCountries))
  ## Remove "NULL"s  beacuse they are invalide codes for dimension geographicAreaFS
  allCountriesFS = na.omit(allCountriesFS) 
  ## Remove codes "274" "283" "280" "281" "279"
  ## because They are invalide codes for dimension geographicAreaFS
  allCountriesFS = allCountriesFS[-which(allCountriesFS == "274")]
  allCountriesFS = allCountriesFS[-which(allCountriesFS == "283")]
  allCountriesFS = allCountriesFS[-which(allCountriesFS == "280")]
  allCountriesFS = allCountriesFS[-which(allCountriesFS == "281")]
  allCountriesFS = allCountriesFS[-which(allCountriesFS == "279")]
  
  lossKey = DatasetKey(
    domain = "faostat_one",
    dataset = "FS1_SUA",
    dimensions = list(
      Dimension(name = areaVarFS,
                keys = allCountriesFS),
      Dimension(name = elementVarFS,
                keys = "121"),
      Dimension(name = itemVarFS,
                keys = as.character(as.numeric(requiredItems$measuredItemFCL))),
      Dimension(name = yearVar,
                keys = selectedYear)
    )
  )
  
  
  ## Pivot to vectorize yield computation
  lossPivot = c(
    Pivoting(code = areaVarFS, ascending = TRUE),
    Pivoting(code = itemVarFS, ascending = TRUE),
    Pivoting(code = yearVar, ascending = FALSE),
    Pivoting(code = elementVarFS, ascending = TRUE)
  )
  
  ## Query the data
  lossQuery = GetData(
    key = lossKey,
    flags = TRUE,
    normalized = FALSE,
    pivoting = lossPivot
  )
  
  
  
  setnames(lossQuery,
           old = names(lossQuery),
           new = c("geographicAreaFS","measuredItemFCL","timePointYears",
                   "Value_measuredElement_5120","flagFaostat_measuredElementFS_5120")
  )
  
  
  ## Convert geographicAreaM49 to geographicAreaFS
  lossQuery[, geographicAreaM49 := as.numeric(faoswsUtil::fs2m49(as.character(geographicAreaFS)))]
  
  ## Convert measuredItemCPC to measuredItemFCL
  lossQuery[, measuredItemFCL := addHeadingsFCL(measuredItemFCL)]
  lossQuery[, measuredItemCPC := faoswsUtil::fcl2cpc(as.character(measuredItemFCL))]
  
  
  ## Convert time to numeric
  lossQuery[, timePointYears := as.numeric(timePointYears)]
  
  lossQuery[, geographicAreaFS := as.numeric(geographicAreaFS)]
  
  
}
