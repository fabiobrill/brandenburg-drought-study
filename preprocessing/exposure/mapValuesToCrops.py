import geopandas as gpd
import os

export_files = True

# source tables
exec(open('./relabelYieldReports.py').read())
exec(open('./relabelIACS.py').read())
exec(open('./defineLBGAverages.py').read())
exec(open('./definePriceTableAMI.py').read())

os.chdir("../../data/intermediate")

# load shapes of the Landkreise of Brandenburg
shapes = gpd.read_file("../processed/brandenburg_landkreise_id_25833.gpkg")

for yoi in range(2013,2023): # year of interest, start should be 2013

    yoi = str(yoi)
    print("processing " + yoi)

    # load IACS data, convert area to ha, and change crs to match shapes
    iacs = gpd.read_file("./iacs_static_" + yoi + ".gpkg").to_crs("EPSG:25833")
    iacs["area_iacs"] = iacs.area.multiply(1e-4) # m2 to ha

    relabelIACS(iacs) # no need for assignment here
    
    # merge with the average yields per LBG
    iacs = iacs[["crop", "azl", "lbg", "twi", "nfk", "area_iacs", "geometry"]]
    merged = iacs.merge(lbg_yields, left_on="crop", right_index=True)

    # hard-coded column merge
    merged["expected_dtha"] = np.NAN
    idx = np.where(merged["lbg"] == 1)
    merged["expected_dtha"].iloc[idx] = merged["lbg1"].iloc[idx]
    idx = np.where(merged["lbg"] == 2)
    merged["expected_dtha"].iloc[idx] = merged["lbg2"].iloc[idx]
    idx = np.where(merged["lbg"] == 3)
    merged["expected_dtha"].iloc[idx] = merged["lbg3"].iloc[idx]
    idx = np.where(merged["lbg"] == 4)
    merged["expected_dtha"].iloc[idx] = merged["lbg4"].iloc[idx]
    idx = np.where(merged["lbg"] == 5)
    merged["expected_dtha"].iloc[idx] = merged["lbg5"].iloc[idx]
    
    # calculate expected yield [dt] as area [ha] x yield per hectar [dt/ha]
    merged["yield_expected"] = merged["expected_dtha"].multiply(merged["area_iacs"])
    
    # add prices [EUR/dt] of the respective year
    merged = merged.merge(prices[yoi], left_on="crop", right_index=True)
    merged = merged.rename({yoi:'price_'+yoi}, axis="columns")
    
    # compute expected revenue [EUR] by expected yield [dt] x price [EUR/dt]
    merged["euro_expected"] = merged["yield_expected"].multiply(merged["price_"+yoi])

    # drop unnecessary columns and export
    merged = merged.drop(["lbg1", "lbg2", "lbg3", "lbg4", "lbg5"], axis="columns")

    # aggregate expected yields on NUTS3
    if not shapes.crs == merged.crs:
        merged = merged.to_crs(shapes.crs)
    
    # intersection with the shapes of the Landkreise - not dissolved yet
    fields_per_nuts3 = gpd.overlay(shapes, merged, keep_geom_type=False)

    # merge some summer and winter varieties to match yield reports
    # they had to be kept separate because of the LBG averages
    fields_per_nuts3 = fields_per_nuts3.replace({"crop": {
    'summer_rye' : 'rye',
    'winter_rye' : 'rye',
    'winter_triticale' : 'triticale',
    'summer_triticale' : 'triticale',
    'potatoes_starch' : 'potatoes'
    }})
    
    if export_files is True:
        fields_per_nuts3.to_file("./exposure_plotscale_" + yoi + ".gpkg", driver="GPKG")
    
    
    # individual polygons for each crop
    stats_per_nuts = fields_per_nuts3.groupby(["NUTS_ID","crop"], as_index=False).aggregate({"area_iacs": sum, "azl": np.mean, "twi": np.mean, "nfk": np.mean, "expected_dtha": np.mean, "yield_expected":sum, "euro_expected":sum})

    # joining with the yield reports before converting to broad format
    reported = yields[yields["year"] == yoi].groupby(["NUTS_ID","crop"], as_index=False).sum(numeric_only=True, min_count=1)

    # merge with price data - should be based on same as expected estimate
    reported = reported.merge(prices[yoi], left_on="crop", right_index=True).rename({yoi:"price_"+yoi},axis="columns")
    reported["euro_reported"] = reported["yield_reported"].multiply(reported["price_"+yoi])

    reported_vs_expected = reported.merge(stats_per_nuts)

    # compute yield gap and loss estiamte. yield reported x10 dt vs t
    # "adj_" columns are corrected for differences in reported area (IACS vs yield reports)
    # "rel_" columns are relative to the expected yield
    reported_vs_expected["area_dif"] = reported_vs_expected["A_ha"].subtract(reported_vs_expected["area_iacs"])
    reported_vs_expected["gap"] = reported_vs_expected["yield_expected"].subtract(reported_vs_expected["yield_reported"])
    reported_vs_expected["loss_estimate"] = reported_vs_expected["euro_expected"].subtract(reported_vs_expected["euro_reported"])
    reported_vs_expected["adj_yield_expected"] = reported_vs_expected["yield_expected"].add(reported_vs_expected["area_dif"].multiply(reported_vs_expected["expected_dtha"]))
    reported_vs_expected["adj_gap"] = reported_vs_expected["adj_yield_expected"].subtract(reported_vs_expected["yield_reported"])
    reported_vs_expected["rel_gap"] = reported_vs_expected["adj_gap"].divide(reported_vs_expected["adj_yield_expected"])
    reported_vs_expected["adj_euro_expected"] = reported_vs_expected["adj_yield_expected"].multiply(reported_vs_expected["price_"+yoi])
    reported_vs_expected["adj_loss_estimate"] = reported_vs_expected["adj_euro_expected"].subtract(reported_vs_expected["euro_reported"])

    # convert the levels of ["crop"] to individual columns
    # i.e. single polygons with crop statistics as attributes
    widetable = reported_vs_expected.pivot(index="NUTS_ID", columns="crop", values=["A_ha", "yield_expected", "adj_yield_expected", "euro_expected", "adj_euro_expected", "yield_reported", "euro_reported", "area_dif", "gap", "adj_gap", "rel_gap", "loss_estimate", "adj_loss_estimate"])
    widetable.columns = widetable.columns.map('_'.join).str.strip('_')
    widetable = widetable.reset_index()
    widetable["agr_area"] = widetable.loc[:,widetable.columns.str.startswith("A_ha")].sum(axis=1, min_count=1)
    widetable["euro_expected_total"] = widetable.loc[:,widetable.columns.str.startswith("euro_expected")].sum(axis=1, min_count=1)
    widetable["adj_euro_expected_total"] = widetable.loc[:,widetable.columns.str.startswith("adj_euro_expected")].sum(axis=1, min_count=1)

    widetable["loss_estimate_total"] = widetable.loc[:,widetable.columns.str.startswith("loss_estimate")].sum(axis=1, min_count=1).divide(1e6).round(3)
    widetable["loss_relative"] = widetable["loss_estimate_total"].divide(widetable["agr_area"]).multiply(1e6) # EUR per ha
    widetable["adj_loss_estimate_total"] = widetable.loc[:,widetable.columns.str.startswith("adj_loss_estimate")].sum(axis=1, min_count=1).divide(1e6).round(3)
    widetable["adj_loss_relative"] = widetable["adj_loss_estimate_total"].divide(widetable["agr_area"]).multiply(1e6) # EUR per ha
    #widetable["euro_reported_total"] = widetable.loc[:,widetable.columns.str.startswith("euro_reported")].sum(axis=1, min_count=1)
    # #widetable["loss_estimate_total_dropna"] = widetable["euro_expected_total"].subtract(widetable["euro_reported_total"]).divide(1e6).round(3)

    # joining back on the spatial geometries - the total euro count only works for pivot table
    result = shapes.merge(widetable, on="NUTS_ID", how="left")
    reduced = result[["NUTS_ID", "NUTS_NAME", "agr_area", "adj_loss_estimate_total", "adj_loss_relative", "geometry"]]

    if export_files is True:
        result.to_file("./exposure_aggregated_" + yoi + ".gpkg", diver="GPKG")
        reduced.to_file("./loss_estimates_" + yoi + ".gpkg", diver="GPKG")

    print("--- Done ---")