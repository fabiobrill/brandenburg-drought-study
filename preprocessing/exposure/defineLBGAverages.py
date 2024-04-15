import numpy as np
import pandas as pd


# 2010-2014 in dt/ha
winter_rye       = {'lbg1': 63, 'lbg2': 55, 'lbg3': 43, 'lbg4': 35, 'lbg5': 25}
winter_wheat     = {'lbg1': 77, 'lbg2': 65, 'lbg3': 50, 'lbg4': 38, 'lbg5': 23}
winter_barley    = {'lbg1': 75, 'lbg2': 63, 'lbg3': 50, 'lbg4': 36, 'lbg5': 25}
oat              = {'lbg1': 55, 'lbg2': 45, 'lbg3': 35, 'lbg4': 27, 'lbg5': 18}
winter_triticale = {'lbg1': 66, 'lbg2': 60, 'lbg3': 48, 'lbg4': 37, 'lbg5': 23}
grain_maize      = {'lbg1': 90, 'lbg2': 80, 'lbg3': 70, 'lbg4': 60, 'lbg5': 50}
winter_canola    = {'lbg1': 43, 'lbg2': 38, 'lbg3': 32, 'lbg4': 25, 'lbg5': 20}
summer_canola    = {'lbg1': 23, 'lbg2': 18, 'lbg3': 14, 'lbg4': 11, 'lbg5': np.NAN} 
sunflower        = {'lbg1': 28, 'lbg2': 25, 'lbg3': 20, 'lbg4': 17, 'lbg5': 15}
oilflax          = {'lbg1': np.NAN, 'lbg2': 14, 'lbg3': 10, 'lbg4': 7, 'lbg5': 7}
potatoes         = {'lbg1': 370, 'lbg2': 350, 'lbg3': 320, 'lbg4': 250, 'lbg5': 220}
potatoes_starch  = {'lbg1': 450, 'lbg2': 420, 'lbg3': 390, 'lbg4': 320, 'lbg5': 250}
sugarbeet        = {'lbg1': 650, 'lbg2': 620, 'lbg3': 580, 'lbg4': np.NAN, 'lbg5': np.NAN}
peas             = {'lbg1': 35, 'lbg2': 30, 'lbg3': 25, 'lbg4': 20, 'lbg5': np.NAN}
lupines          = {'lbg1': np.NAN, 'lbg2': 25, 'lbg3': 21, 'lbg4': 18, 'lbg5': 15}

lbg_yields = pd.DataFrame([winter_wheat,
                           winter_rye,
                           winter_rye, # init for summer
                           winter_barley,
                           oat,
                           winter_triticale,
                           winter_triticale, # init for summer
                           grain_maize,
                           peas,
                           lupines,
                           potatoes,
                           potatoes_starch,
                           sugarbeet,
                           winter_canola,
                           summer_canola,
                           sunflower,
                           oilflax], 
                           index=['winter_wheat',
                           'winter_rye',
                           'summer_rye',
                           'winter_barley',
                           'oat',
                           'winter_triticale',
                           'summer_triticale',
                           'grain_maize',
                           'peas',
                           'lupines',
                           'potatoes',
                           'potatoes_starch',
                           'sugarbeet',
                           'winter_canola',
                           'summer_canola',
                           'sunflower',
                           'oilflax'])

# implement the assumption that summer triticale and rye yield 60% of the winter varieties
lbg_yields.loc[["summer_rye", "summer_triticale"]] = lbg_yields.loc[["summer_rye", "summer_triticale"]].multiply(0.6)

print(lbg_yields)