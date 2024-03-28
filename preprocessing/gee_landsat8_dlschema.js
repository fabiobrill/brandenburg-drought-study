// Select time of interest in the format 'yyyy-mm-dd'
// ------------------------------------------------------------------------------------------
var starttime = '2020-05-01'
var endtime = '2020-06-30'
// ------------------------------------------------------------------------------------------


// There are several ways of doing cloud masking in GEE.
// This function simply uses the bitmask that is already part of the data
// You can look up the meaning of the "QA_PIXEL" band in the data description
// https://developers.google.com/earth-engine/datasets/catalog/LANDSAT_LC08_C02_T1_L2#bands
var maskClouds = function(image) {
  var dilatedCloud = (1 << 1)
  var cloud = (1 << 3)
  var cloudShadow = (1 << 4)
  var qa = image.select('QA_PIXEL')
  var mask1 = qa.bitwiseAnd(dilatedCloud).eq(0)
                .and(qa.bitwiseAnd(cloud).eq(0))
                .and(qa.bitwiseAnd(cloudShadow).eq(0))
  return(image.updateMask(mask1))
}

// Scale factors for Landsat8, taken from the website
function applyScaleFactors(image) {
  var opticalBands = image.select('SR_B.').multiply(0.0000275).add(-0.2);
  var thermalBands = image.select('ST_B.*').multiply(0.00341802).add(149.0);
  return image.addBands(opticalBands, null, true)
              .addBands(thermalBands, null, true);
}

// This function computes the NDVI using the correct bands of Landsat8
// obviously other bands have to be selected for other satellites, e.g. Landsat7!
function addNDVI(image) {
  var ndvi = image.normalizedDifference(['SR_B5', 'SR_B4']).rename('NDVI');
  return image.addBands(ndvi);
}

// Function that I wrote myself for a different project, to add the time of an image as layer
function addTime(image){
  return(image.addBands(ee.Image.constant(ee.Number.parse(image.date()
              .format("YYYYMMdd"))).rename('time').double())
              .set('date', ee.Number.parse(image.date()      
              .format("YYYYMMdd")).double()))
}

// Function to display all images in a collection, for explorative purpose
function displayScenes(myimage) {
  var id = myimage.id
  var scene = ee.Image(myimage.id)
  var scaledScene = applyScaleFactors(scene)
  var maskedScene = maskClouds(scaledScene)
  var timeScene = addTime(maskedScene)
  Map.addLayer(scaledScene.clip(catchment), vis_432,'scene')
  Map.addLayer(maskedScene.clip(catchment), vis_432, 'masked')
  Map.addLayer(timeScene.clip(catchment), vis_time, 'time')
}

// Load the dataset and filter by time and region and apply scaling, cloud mask, NDVI and time
var dataset = ee.ImageCollection('LANDSAT/LC08/C02/T1_L2')
                .filterDate(starttime, endtime)
                .filterBounds(bbox)
                .map(applyScaleFactors)
                .map(maskClouds)
                .map(addNDVI)
                .map(addTime);

print(dataset.first())

// Select LST band and compute NDVI
var lst = dataset.select(['ST_B10', 'time']);
var ndvi = dataset.select(['NDVI', 'time']) //.sort('date');

// Computing the statistics, e.g. mean, median, maximum, ...
// + timing of greenest pixel - we could also select LST at max. NDVI
// Printing layers to the console helps to understand what is going on
var greenestMosaic = ndvi.reduce(ee.Reducer.max(2)) // (2) adds second band at max of first band
print(greenestMosaic)


// -----------------------------------------------------------------------------------------
// Some visualization options for various layers
var vis_432 = {bands: ['SR_B4', 'SR_B3', 'SR_B2'], min: 0.0, max: 0.3};
var vis_ndvi = {bands:['NDVI'], min:0, max:1};
var vis_lst = {bands:['ST_B10'], min:280, max:330};

// convert string 'yyyy-mm-dd' to number yyyymmdd
var startnumber = ee.Number.parse(ee.String(starttime).replace('-','', 'g')).getInfo();
var endnumber = ee.Number.parse(ee.String(endtime).replace('-','', 'g')).getInfo();
print(startnumber)
print(endnumber)

// select colors for time visualization
var vis_time = {bands:['time'], min:startnumber, max:endnumber, palette:['#0000FF', '#00FFFF']};
var mypalette = ['#0000FF', '#00FFFF']

// Display some layers in GEE
Map.centerObject(bbox);
Map.addLayer(dataset.count(), {min:0, max:10}, '#scenes') // number of scenes per pixel

// Display all the scenes - comment out if not needed
//dataset.evaluate(function(dataset) {  // use map on client-side
//  dataset.features.map(displayScenes)
//})

Map.addLayer(ndvi.mean().clip(catchment), vis_ndvi, 'ndvi mean')
Map.addLayer(ndvi.median().clip(catchment), vis_ndvi, 'ndvi median')
Map.addLayer(greenestMosaic.clip(catchment), {bands:['max'], min:0, max:1}, 'ndvi maximum')
Map.addLayer(greenestMosaic.clip(catchment), {bands:['max1'], min: startnumber, max: endnumber, palette: mypalette}, 'day of max. ndvi')
Map.addLayer(lst.mean().clip(catchment), vis_lst, 'LST Mean')

// -----------------------------------------------------------------------------
// download

// semi-automatic name generation
var outname_ndvi = ee.String('landsat8_ndvi_').cat(starttime).cat("_").cat(endtime).getInfo()
var outname_lst = ee.String('landsat8_lst_').cat(starttime).cat("_").cat(endtime).getInfo()
var outname_greenest = ee.String('landsat8_greenest_').cat(starttime).cat("_").cat(endtime).getInfo()

// could probably also merge both to a 2-band image, at least for mean/median
// NDVI x1000 to export as integer
Export.image.toDrive({
  image: ndvi.select(['NDVI']).mean().multiply(1000).int16(),
  description: outname_ndvi,
  scale: 30,
  region: bbox,
  maxPixels: 1e10,
  fileFormat: 'GeoTIFF'
});

// LST directly exported as integer, i.e. rounded to 1 Kelvin
Export.image.toDrive({
  image: lst.select(['ST_B10']).mean().int16(),
  description: outname_lst,
  scale: 30,
  region: bbox,
  maxPixels: 1e10,
  fileFormat: 'GeoTIFF'
});

// Maximum NDVI together with time
Export.image.toDrive({
  image: greenestMosaic.float(),
  description: outname_greenest,
  scale: 30,
  region: bbox,
  maxPixels: 1e10,
  fileFormat: 'GeoTIFF'
});