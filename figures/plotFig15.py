import numpy as np
import pandas as pd
import shap
import matplotlib.pyplot as plt
import matplotlib
mycmap = matplotlib.colormaps['coolwarm']
import statsmodels.api as sm

X_lk9 = pd.read_csv("../data/processed/X_lk9.csv", index_col=0)
X_lk9b = pd.read_csv("../data/processed/X_lk9b2.csv", index_col=0)
shapvals_lk9 = np.load("../data/processed/shapvals_lk9.npy")
shapvals_lk9b = np.load("../data/processed/shapvals_lk9b2.npy")

featurelabels = X_lk9.columns.map({
                "Crop_type" : "Crop (Categorical)",
                "SPEI_jun_-1" : "SPEI June < -1",
                "SMI_total_10" : "SMI Total > 10",
                "SMI_total_5" : "SMI Total > 5",
                "SPEI_mar_0" : "SPEI March < 0",
                "SPEI_jul_-0.5" : "SPEI July < -0.5",
                "AZL_23" : "AZL < 23",
                "AZL_46" : "AZL < 46",
                "SMI_total_25" : "SMI Total > 25",
                "SPEI_may_-0.5" : "SPEI May < -0.5",
                "SPEI_mar_-0.5" : "SPEI March < -0.5",
                "AZL_29" : "AZL < 29",
                "SMI_total_15" : "SMI Total > 15",
                "SMI_jun_0.1" : "SMI June > 0.1",
                "SMI_jul_0" : "SMI July > 0",
                "SPEI_jun_-0.5" : "SPEI June < -0.5",
                "LSTNDVI_1" : "LSTNDVI > 1",
                "SPEI_jun_0" : "SPEI June < 0",
                "SPEI_jul_-1" : "SPEI July < -1",
                "AZL_36" : "AZL < 36",
                "SMI_jul_0.05" : "SMI July > 0.05",
                "SPEI_jun_-1.5" : "SPEI June < -1.5",
                "SPEI_apr_-0.5" : "SPEI April < -0.5",
                "SMI_apr_0.1" : "SMI April > 0.1",
                "LSTNDVI_0.5" : "LSTNDVI > 0.5"
                })


# fig15a : crop type
#cropcode = pd.DataFrame([subdata.crop, X_lk9.Crop_type]).T.drop_duplicates()

X_lk9.Crop_type = X_lk9.Crop_type.map({
                0 : "Grain Maize",
                1 : "Lupines",
                2 : "Oat",
                3 : "Peas",
                4 : "Potatoes",
                5 : "Rye",
                6 : "Sugar Beet",
                7 : "Sunflower",
                8 : "Triticale",
                9 : "Winter Barley",
               10 : "Winter Canola",
               11 : "Winter Wheat"
})
shap.dependence_plot("Crop_type", shapvals_lk9, X_lk9, X_lk9.columns, cmap=mycmap, dot_size=3, x_jitter=0.3, show=False, interaction_index="AZL_36")
plt.ylabel("SHAP value for crop type")
plt.xlabel("")
plt.savefig("fig15a.png", dpi=700, bbox_inches='tight')

# fig15b : SPEI_jun_-1 using all data
idx = np.where(X_lk9.columns=="SPEI_jun_-1")[0][0]
x = X_lk9.iloc[:,idx]
y_sv = shapvals_lk9[:,idx]
lowess = sm.nonparametric.lowess(y_sv, x, frac=0.2)
_,ax = plt.subplots()
ax.plot(*list(zip(*lowess)), color="black", )
#plt.ylim(-0.1,0.2)
shap.dependence_plot("SPEI_jun_-1", shapvals_lk9, X_lk9, ax=ax, cmap=mycmap, dot_size=4, interaction_index="SMI_jun_0.1", show=False)
plt.ylabel("SHAP value for SPEI June < -1")
plt.xlabel("Fraction of area affected by SPEI June < -1")
plt.savefig("fig15b.png", dpi=400, bbox_inches='tight')


# fig15c : SPEI_jun_-1 using subset data (rel_gap > 0)
idx = np.where(X_lk9b.columns=="SPEI_jun_-1")[0][0]
x = X_lk9b.iloc[:,idx]
y_sv = shapvals_lk9b[:,idx]
lowess = sm.nonparametric.lowess(y_sv, x, frac=0.2)
_,ax = plt.subplots()
ax.plot(*list(zip(*lowess)), color="black", )
#plt.ylim(-0.1,0.2)
shap.dependence_plot("SPEI_jun_-1", shapvals_lk9b, X_lk9b, ax=ax, cmap=mycmap, dot_size=4, interaction_index="SMI_jun_0.1", show=False)
plt.ylabel("SHAP value for SPEI June < -1")
plt.xlabel("Fraction of area affected by SPEI June < -1")
plt.savefig("fig15c.png", dpi=400, bbox_inches='tight')


# fig15d : SPEI March < 0
idx = np.where(X_lk9.columns=="SPEI_mar_0")[0][0]
x = X_lk9.iloc[:,idx]
y_sv = shapvals_lk9[:,idx]
lowess = sm.nonparametric.lowess(y_sv, x, frac=0.2)
_,ax = plt.subplots()
ax.plot(*list(zip(*lowess)), color="black", )
#plt.ylim(-0.1,0.2)
shap.dependence_plot("SPEI_mar_0", shapvals_lk9, X_lk9, ax=ax, cmap=mycmap, dot_size=4, show=False)
plt.ylabel("SHAP value for SPEI March < 0")
plt.xlabel("Fraction of area affected by SPEI March < 0")
plt.savefig("fig15d.png", dpi=400, bbox_inches='tight')


# fig15e LSTNDVI 0.5
idx = np.where(X_lk9b.columns=="LSTNDVI_0.5")[0][0]
x = X_lk9b.iloc[:,idx]
y_sv = shapvals_lk9b[:,idx]
lowess = sm.nonparametric.lowess(y_sv, x, frac=0.2)
_,ax = plt.subplots()
ax.plot(*list(zip(*lowess)), color="black", )
#plt.ylim(-0.1,0.2)
shap.dependence_plot("LSTNDVI_0.5", shapvals_lk9b, X_lk9b, ax=ax, cmap=mycmap, dot_size=4, show=False)
plt.ylabel("SHAP value for LST/NDVI-anom. > 0.5")
plt.xlabel("Fraction of area affected by LST/NDVI-anom. > 0.5")
plt.savefig("fig15e.png", dpi=400, bbox_inches='tight')