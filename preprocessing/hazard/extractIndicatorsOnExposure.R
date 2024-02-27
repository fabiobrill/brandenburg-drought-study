library(terra)
library(sf)
library(dplyr)

# get EPSG number
getEPSG = function(v){
return(paste0("EPSG:",
              gsub("[^0-9]", "", 
                   last(strsplit(st_crs(v)$wkt, split="EPSG")[[1]])))
)
}

setwd("./data/intermediate")
rfolder = "../raw/rasters/"

for (yoi in 2013:2022){
  print(yoi)
  vname = paste0("exposure_plotscale_", yoi, ".gpkg")
  outname = paste0("indicators_on_exposure_", yoi, ".gpkg")
  shapes = read_sf(vname) %>% st_transform("EPSG:4326") # much faster in extraction
  #shapes = st_make_valid(shapes)
  idx = which(st_is_valid(shapes)) # kick out invalid polygons
  shapes = shapes[idx,]
  epsg = getEPSG(shapes)
  #epsg = "EPSG:25833"

  # read shapes and (folder of) rasters
  filelist = list.files(rfolder)
  filelist = filelist[endsWith(filelist, paste0(yoi,".tif"))]
  for(rfile in filelist){
    rname = gsub(paste0("_", yoi, ".tif"), "", rfile, fixed=T)
    print(rname)
    r = rast(paste0(rfolder, rfile))
    if(rname %in% c("LST", "NDVI")){
      r[r == 0] = NA # make sure that Landsat cloudmask is treated as NA
    }
    r = r %>% project(epsg) # reproject AFTER converting 0 to NA!
    x = terra::extract(r, shapes[1], fun=mean,
                       na.rm=T, exact=F, ID=F, raw=T)
    shapes[rname] = x[,1]
  }
  write_sf(shapes, outname, driver="GPKG")
}
