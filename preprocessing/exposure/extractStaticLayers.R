library(terra)
library(sf)
library(dplyr)

# simple wrapper function around extract, with hard-coded settings
extractMean = function(x, shapes){
  temp = terra::extract(x, shapes[1], fun=mean, na.rm=T, exact=F, ID=F, raw=T)
  return(temp[,1])
}


# read raster data
azl = rast("data/raw/rasters/static/ackerzahl_nonzero_30m.tif") %>% project("EPSG:4326")
twi = rast("data/raw/rasters/static/twi.tif") %>% project("EPSG:4326")
nfk = rast("data/raw/rasters/static/nfk.tif") %>% project("EPSG:4326")

setwd("data/raw/iacs")

for (yoi in 2013:2022){
  print(yoi)
  vname = paste0("Inv_NoDups_", yoi, ".shp")
  outname = paste0("iacs_static_", yoi, ".gpkg")
  
  # transform crs because extraction is apparently much faster in 4326 
  shapes = read_sf(vname) %>% st_transform("EPSG:4326")
  
  #shapes = st_make_valid(shapes)
  idx = which(st_is_valid(shapes)) # kick out invalid polygons
  cat("removing", (nrow(shapes)-length(idx)), "invalid polygons \n")
  shapes = shapes[idx,]

  # column names were changed in 2018
  if(yoi <= 2018){
    shapes = shapes %>% dplyr::select(ID, K_ART, K_ART_NA, K_ART_K, Oeko) # remove Oeko?
  } else if (yoi > 2018) {
    if(yoi == 2022){
      shapes$ID = 1:nrow(shapes) # 2022 comes without shape IDs
    }
    shapes = shapes %>% dplyr::select(ID, CODE, CODE_BEZ)
  }

  # add the mean indicator values per field as columns
  shapes["AZL"] = extractMean(azl, shapes[1])
  shapes["LBG"] = case_when(
    shapes$azl < 23 ~ 5,
    shapes$azl <= 28 ~ 4,
    shapes$azl <= 35 ~ 3,
    shapes$azl <= 45 ~ 2,
    shapes$azl > 45 ~ 1
  )
  shapes["TWI"] = extractMean(twi, shapes[1])
  shapes["NFK"] = extractMean(nfk, shapes[1])

  write_sf(shapes, outname, driver="GPKG")
}