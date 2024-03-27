import numpy as np
import pandas as pd
import shap
import matplotlib.pyplot as plt
import matplotlib
mycmap = matplotlib.colormaps['coolwarm']
import statsmodels.api as sm

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

# manual export from the IDE
# add loess regression line to shap plots
idx = np.where(X_f7.columns=="AZL")[0][0]
x = X_f7.iloc[:,idx]
y_sv = shapvals_f7[:,idx]
lowess = sm.nonparametric.lowess(y_sv, x, frac=.1)

# fig12a
_,ax = plt.subplots()
ax.plot(*list(zip(*lowess)), color="black", )
#plt.ylim(-0.1,0.2)
shap.dependence_plot("AZL", shapvals_f7, X_f7, ax=ax, cmap=mycmap, dot_size=0.5, interaction_index="SMI_total")
#plt.xlabel("")
#plt.ylabel("SHAP value for AZL")
ax.save("fig12a.png", dpi=300, bbox_inches='tight')


# fig12b
#...



shap.dependence_plot("crop_type", shapvals_f7, X_f7, X_f7.columns, cmap=mycmap, dot_size=2)


idx = np.where(X_f7.columns=="SPEI_jun")[0][0]
x = X_f7.iloc[:,idx]
y_sv = shapvals_f7[:,idx]
lowess = sm.nonparametric.lowess(y_sv, x, frac=.1)

_,ax = plt.subplots()
ax.plot(*list(zip(*lowess)), color="black", )
#plt.ylim(-0.1,0.2)
shap.dependence_plot("SPEI_jun", shapvals_f7, X_f7, ax=ax, cmap=mycmap, dot_size=0.5, interaction_index="SMI_jun")


idx = np.where(X_f7.columns=="SMI_may")[0][0]
x = X_f7.iloc[:,idx]
y_sv = shapvals_f7[:,idx]
lowess = sm.nonparametric.lowess(y_sv, x, frac=.1)
_,ax = plt.subplots()
ax.plot(*list(zip(*lowess)), color="black", )
#plt.ylim(-0.1,0.2)
shap.dependence_plot("SMI_may", shapvals_f7, X_f7, ax=ax, cmap=mycmap, dot_size=0.5, interaction_index="SPEI_may")
plt.xlabel("SMI May")


idx = np.where(X_f7.columns=="SPEI_mar")[0][0]
x = X_f7.iloc[:,idx]
y_sv = shapvals_f7[:,idx]
lowess = sm.nonparametric.lowess(y_sv, x, frac=.1)
_,ax = plt.subplots()
ax.plot(*list(zip(*lowess)), color="black", )
#plt.ylim(-0.1,0.2)
shap.dependence_plot("SPEI_mar", shapvals_f7, X_f7, ax=ax, cmap=mycmap, dot_size=0.5, interaction_index="SMI_mar")


idx = np.where(X_f7.columns=="SMI_total")[0][0]
x = X_f7.iloc[:,idx]
y_sv = shapvals_f7[:,idx]
lowess = sm.nonparametric.lowess(y_sv, x, frac=.1)
_,ax = plt.subplots()
ax.plot(*list(zip(*lowess)), color="black", )
#plt.ylim(-0.1,0.2)
shap.dependence_plot("SMI_total", shapvals_f7, X_f7, ax=ax, cmap=mycmap, dot_size=0.5, interaction_index="AZL")

idx = np.where(X_f7.columns=="TWI")[0][0]
x = X_f7.iloc[:,idx]
y_sv = shapvals_f7[:,idx]
lowess = sm.nonparametric.lowess(y_sv, x, frac=.1)
_,ax = plt.subplots()
ax.plot(*list(zip(*lowess)), color="black", )
#plt.ylim(-0.1,0.2)
shap.dependence_plot("TWI", shapvals_f7, X_f7, ax=ax, cmap=mycmap, dot_size=0.5, interaction_index="NFK")
ax.set_xlabel("Mein Axenlabel")
ax.set_ylabel("SHAP value for SMI Total")