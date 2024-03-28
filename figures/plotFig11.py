import numpy as np
import pandas as pd
import shap
import matplotlib.pyplot as plt
import matplotlib
mycmap = matplotlib.colormaps['coolwarm']

X_f7 = pd.read_csv("../data/processed/X_f7.csv", index_col=0)
shapvals_f7 = np.load("../data/processed/shapvals_f7.npy")

featurelabels = X_f7.columns.map({
                "AZL" : "AZL",
                "SPEI_jun" : "SPEI June",
                "SMI_jun" : "SMI June",
                "SMI_may" : "SMI May",
                "crop_type" : "Crop (Categorical)",
                "SPEI_mar" : "SPEI March",
                "SPEI_apr" : "SPEI April",
                "SPEI_may" : "SPEI May",
                "SPEI_jul" : "SPEI July",
                "SMI_mar" : "SMI March",
                "SMI_apr" : "SMI April",
                "SMI_jun" : "SMI June",
                "SMI_jul" : "SMI July",
                "TWI" : "TWI",
                "NFK" : "NFK",
                "SMI_total" : "SMI Total",
})

# ----------------------------------------------------------------------------------------------- #
# crop labels

# caution: these hard-coded label might need to be adjusted if
# model runs are repreated with different data subsets

# check crop codes
#cropcode = pd.DataFrame([subdata.crop, X_f7.crop_type]).T.drop_duplicates()

X_f7.crop_type = X_f7.crop_type.map({
                0 : "Grain Maize",
                1 : "Lupines",
                2 : "Oat",
                3 : "Peas",
                4 : "Potatoes",
                5 : "Rye",
                6 : "Sugar Beet",
                7 : "Summer Canola", # excluded
                8 : "Sunflower",
                9 : "Triticale",
               10 : "Winter Barley",
               11 : "Winter Canola",
               12 : "Winter Wheat"
})


shap.dependence_plot("crop_type", shapvals_f7, X_f7, X_f7.columns, cmap=mycmap, dot_size=0.5, x_jitter=0.3, show=False)
plt.xlabel("")
plt.ylabel("SHAP value for crop type")
plt.savefig("fig11.png", dpi=300, bbox_inches='tight')