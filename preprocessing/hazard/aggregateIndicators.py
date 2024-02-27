import pandas as pd
import geopandas as gpd
import os

os.chdir("../../data/intermediate")
result = pd.DataFrame()

# Brandenburg counties
shapes = gpd.read_file("../processed/brandenburg_landkreise_id_25833.gpkg").to_crs(4326)

for yoi in range(2013,2023):
    print(yoi)

    fields_per_nuts3 = gpd.read_file("./indicators_on_exposure_" +str(yoi) + ".gpkg")

    fields_per_nuts3 = fields_per_nuts3.drop("price_"+str(yoi), axis="columns")
    fields_per_nuts3["year"] = yoi
    result = pd.concat([result, fields_per_nuts3])


# calculating lst/ndvi ratio
result["NDVI"] = result["NDVI"].divide(1000)
result["LSTNDVI"] = result["LST"].divide(result["NDVI"])

# export
result.drop("geometry", axis="columns").to_csv("./indicators_per_nuts3.csv")
result.to_file("./indicators_per_nuts3.gpkg", driver="GPKG")