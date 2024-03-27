import numpy as np
import pandas as pd
import shap
import matplotlib.pyplot as plt
import matplotlib
mycmap = matplotlib.colormaps['coolwarm']

X_lk9 = pd.read_csv("../data/processed/X_lk9.csv", index_col=0)
X_lk9b = pd.read_csv("../data/processed/X_lk9b.csv", index_col=0)
shapvals_lk9 = np.load("../data/processed/shapvals_lk9.npy")
shapvals_lk9b = np.load("../data/processed/shapvals_lk9b.npy")

shapvals_lk7 = np.load("../data/processed/shapvals_lk7.npy")

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
                "LSTNDVI_0.5" : "LSTNDVI > 0.5",
                "SPEI_may_-1" : "SPEI May < -1",
                "SPEI_may_-1.5" : "SPEI May < -1.5",
                "LSTNDVI_0.75" : "LSTNDVI > 0.75",
                })


shap.summary_plot(shapvals_lk9, X_lk9, featurelabels, max_display=15, cmap="coolwarm", show=False)
#plt.savefig("../../figures/shap_lk9.pdf")
plt.savefig("fig14a.png", dpi=300, bbox_inches="tight")

shap.summary_plot(shapvals_lk9b, X_lk9b, featurelabels, max_display=15, cmap="coolwarm", show=False)
plt.savefig("fig14b2.png", dpi=300, bbox_inches="tight")