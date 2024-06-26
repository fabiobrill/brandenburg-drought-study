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

featurelabels = X_lk9.columns.map({
                "Crop_type" : "Crop (Categorical)",
                "SPEI_mar_0" : "SPEI March < 0",
                "SPEI_mar_-0.5" : "SPEI March < -0.5",
                "SPEI_mar_-1" : "SPEI March < -1",
                "SPEI_mar_-1.5" : "SPEI March < -1.5",
                "SPEI_mar_-2" : "SPEI March < -2",
                "SPEI_mar_-2.5" : "SPEI March < -2.5",
                "SPEI_apr_0" : "SPEI April < 0",
                "SPEI_apr_-0.5" : "SPEI April < -0.5",  
                "SPEI_apr_-1" : "SPEI April < -1",
                "SPEI_apr_-1.5" : "SPEI April < -1.5",
                "SPEI_apr_-2" : "SPEI April < -2",
                "SPEI_apr_-2.5" : "SPEI April < -2.5",
                "SPEI_may_0" : "SPEI May < 0",
                "SPEI_may_-0.5" : "SPEI May < -0.5",
                "SPEI_may_-1" : "SPEI May < -1",
                "SPEI_may_-1.5" : "SPEI May < -1.5",
                "SPEI_may_-2" : "SPEI May < -2",
                "SPEI_may_-2.5" : "SPEI May < -2.5",
                "SPEI_jun_0" : "SPEI June < 0",
                "SPEI_jun_-0.5" : "SPEI June < -0.5",
                "SPEI_jun_-1" : "SPEI June < -1",
                "SPEI_jun_-1.5" : "SPEI June < -1.5",
                "SPEI_jun_-2" : "SPEI June < -2",
                "SPEI_jun_-2.5" : "SPEI June < -2.5",
                "SPEI_jul_0" : "SPEI July < 0",
                "SPEI_jul_-0.5" : "SPEI July < -0.5",
                "SPEI_jul_-1" : "SPEI July < -1",
                "SPEI_jul_-1.5" : "SPEI July < -1.5",
                "SPEI_jul_-2" : "SPEI July < -2",
                "SPEI_jul_-2.5" : "SPEI July < -2.5",
                "SMI_mar_0" : "SMI March > 0",
                "SMI_mar_0.05" : "SMI March > 0.05",
                "SMI_mar_0.1" : "SMI March > 0.1",
                "SMI_mar_0.15" : "SMI March > 0.15",
                "SMI_apr_0" : "SMI April > 0",
                "SMI_apr_0.05" : "SMI April > 0.05",
                "SMI_apr_0.1" : "SMI April > 0.1",
                "SMI_apr_0.15" : "SMI April > 0.15",
                "SMI_may_0" : "SMI May > 0",
                "SMI_may_0.05" : "SMI May > 0.05",
                "SMI_may_0.1" : "SMI May > 0.1",
                "SMI_may_0.15" : "SMI May > 0.15",
                "SMI_jun_0" : "SMI June > 0",
                "SMI_jun_0.05" : "SMI June > 0.05",
                "SMI_jun_0.1" : "SMI June > 0.1",
                "SMI_jun_0.15" : "SMI June > 0.15",
                "SMI_jul_0" : "SMI July > 0",
                "SMI_jul_0.05" : "SMI July > 0.05",
                "SMI_jul_0.1" : "SMI July > 0.1",
                "SMI_jul_0.15" : "SMI July > 0.15",
                "AZL_23" : "AZL < 23",
                "AZL_29" : "AZL < 29",
                "AZL_36" : "AZL < 36",
                "AZL_46" : "AZL < 46",
                "SMI_total_0" : "SMI Total > 0",
                "SMI_total_5" : "SMI Total > 5",
                "SMI_total_10" : "SMI Total > 10",
                "SMI_total_15" : "SMI Total > 15",
                "SMI_total_20" : "SMI Total > 20",
                "SMI_total_25" : "SMI Total > 25",
                "SMI_total_30" : "SMI Total > 30",
                "SMI_total_35" : "SMI Total > 35",
                "LSTNDVI_0.25" : "LSTNDVI > 0.25",
                "LSTNDVI_0.5" : "LSTNDVI > 0.5",
                "LSTNDVI_0.75" : "LSTNDVI > 0.75",
                "LSTNDVI_1" : "LSTNDVI > 1",
                "LSTNDVI_1.25" : "LSTNDVI > 1.25",
                "LSTNDVI_1.5" : "LSTNDVI > 1.5"
                })


shap.summary_plot(shapvals_lk9, X_lk9, featurelabels, max_display=15, cmap="coolwarm", show=False)
#shap.summary_plot(shapvals_lk9, X_lk9, featurelabels, max_display=80, cmap="coolwarm", show=False)
#plt.savefig("figC2a.png", dpi=300, bbox_inches="tight")
#plt.savefig("../../figures/shap_lk9.pdf")
plt.savefig("fig14a.png", dpi=300, bbox_inches="tight")

shap.summary_plot(shapvals_lk9b, X_lk9b, featurelabels, max_display=15, cmap="coolwarm", show=False)
#shap.summary_plot(shapvals_lk9b, X_lk9b, featurelabels, max_display=80, cmap="coolwarm", show=False)
#plt.savefig("figC2b.png", dpi=300, bbox_inches="tight")
plt.savefig("fig14b.png", dpi=300, bbox_inches="tight")