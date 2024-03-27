import numpy as np
import pandas as pd
import shap
import matplotlib.pyplot as plt

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

f = plt.figure()
shap.summary_plot(shapvals_f7, X_f7, featurelabels, cmap="coolwarm", show=False)
f.savefig("fig10.png", dpi=500, bbox_inches='tight')