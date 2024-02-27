import pandas as pd


yields = pd.read_csv("../../data/raw/tables/yield_reports_brandenburg_utf8.csv", delimiter=";", decimal=",", encoding = 'utf8')
yields = yields.rename(columns={'Landkreis':'NUTS_NAME', 'Crop':'category', 'Variety':'variety', 'Year':'year', 'P_t': 'yield_reported'})
yields["yield_reported"] = yields["yield_reported"].multiply(10) # dt

yields["crop"] = yields.variety.map({
    'Hafer' : 'oat',
    'Koernermais (einschl. Corn-Cob-Mix)' : 'grain_maize',
    'Roggen und Wintermenggetreide' : 'rye',
    'Triticale' : 'triticale',
    'Wintergerste' : 'winter_barley',
    'Winterweizen einschl. Dinkel' : 'winter_wheat',
    'Kartoffeln zusammen' : 'potatoes',
    'mittelfruehe und spaete Kartoffeln' : 'potatoes_medium_and_late',
    'Zuckerrueben' : 'sugarbeet',
    'Erbsen' : 'peas',
    'Lupinen' : 'lupines',
    'Sonnenblumen' : 'sunflower',
    'Winterraps' : 'winter_canola',
    'Silomais' : 'silage_maize' # discarded later
})

yields["NUTS_ID"] = yields["NUTS_NAME"].map({
    'Barnim' : 'DE405', 
    'Brandenburg an der Havel (KfS)' : 'DE401', 
    'Cottbus (KfS)' : 'DE402',
    'Dahme-Spreewald' : 'DE406',
    'Elbe-Elster' : 'DE407',
    'Frankfurt (Oder) (KfS)' : 'DE403',
    'Havelland' : 'DE408',
    'Maerkisch-Oderland' : 'DE409',
    'Oberhavel' : 'DE40A',
    'Oberspreewald-Lausitz' : 'DE40B',
    'Oder-Spree' : 'DE40C',
    'Ostprignitz-Ruppin' : 'DE40D',
    'Potsdam-Mittelmark' : 'DE40E',
    'Potsdam (KfS)' : 'DE404',
    'Prignitz' : 'DE40F',
    'Spree-Neiße' : 'DE40G',
    'Teltow-Flaeming' : 'DE40H',
    'Uckermark' : 'DE40I'
})

print(yields)
