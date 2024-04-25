import os
import numpy as np
import pandas as pd
from sklearn.base import clone
from sklearn.model_selection import GridSearchCV, train_test_split
from sklearn.metrics import r2_score
import matplotlib as mpl
import matplotlib.pyplot as plt
import seaborn as sns
import statsmodels.api as sm
import xgboost as xgb
import shap

pd.set_option('display.max_colwidth', 255)
mycmap = mpl.colormaps['coolwarm']

# ----------------------------------------------------------------------------------------------- #
# load the wrapper function from a different script
exec(open('learnfunctionXGB.py').read())

# load data
os.chdir("../data/processed/")
data = pd.read_csv("relative_gaps_vs_thresholds.csv", encoding='latin-1')

# 2 entries are outliers with rel_gap = 17 and 21 (Barnim potatoes)
data = data.loc[(data.rel_gap < 1) & (data.rel_gap > -1)] # '> 0' for setup 9b
#data = data.loc[data.crop == "winter_wheat"]
#data = data.loc[data.crop == "rye"]

# ----------------------------------------------------------------------------------------------- #
# indexing to select columns from data that start with "SPEI_", "lstvndi_", "SMI_total_", "AZL_"

LSTNDVI_cols = [col for col in data.columns if col.startswith('LSTNDVI_')]
AZL_cols = [col for col in data.columns if col.startswith('AZL_')]
SPEI_cols = [col for col in data.columns if col.startswith('SPEI_')]
SPEI_monthly_cols = [col for col in data.columns if col.startswith(('SPEI_mar','SPEI_apr','SPEI_may','SPEI_jun','SPEI_jul'))]
SPEI_sum_cols = [col for col in data.columns if col.startswith('SPEI_sum_')]
SPEI_magnitude_cols = [col for col in data.columns if col.startswith(('SPEI_magnitude_-', 'SPEI_magnitude_0'))]
SPEI_magnitudeJul_cols = [col for col in data.columns if col.startswith('SPEI_magnitude_inclJul_')]
SMI_monthly_cols = [col for col in data.columns if col.startswith(('SMI_mar','SMI_apr','SMI_may','SMI_jun','SMI_jul'))]
SMI_magnitude_cols = [col for col in data.columns if col.startswith('SMI_magnitude')]
SMI_total_cols = [col for col in data.columns if col.startswith('SMI_total_')]

dropcols = ['SPEI_mar_-4', 'SPEI_mar_-3.5', 'SPEI_mar_-3', 'SPEI_apr_-4', 'SPEI_apr_-3.5', 'SPEI_apr_-3',
            'SPEI_may_-4', 'SPEI_may_-3.5', 'SPEI_may_-3', 'SPEI_jun_-4', 'SPEI_jun_-3.5', 'SPEI_jun_-3',
            'SPEI_jul_-4', 'SPEI_jul_-3.5', 'SPEI_jul_-3']

# ----------------------------------------------------------------------------------------------- #
# define subdata, target and features

subdata = data.dropna()
subdata["Crop_type"] = subdata["crop"].astype("category").cat.codes
crop_cols = ["Crop_type"]
# alternative: convert categorical variable "crop" to dummy variable
#subdata = pd.get_dummies(subdata, columns=["crop"])
#crop_cols = [col for col in subdata.columns if col.startswith('crop_')]

# target variable
y = subdata["rel_gap"]

# ----------------------------------------------------------------------------------------------- #
# feature selection

X_lk1 = subdata[crop_cols + LSTNDVI_cols]
X_lk2 = subdata[crop_cols + SPEI_magnitude_cols]
X_lk3 = subdata[crop_cols + SPEI_magnitude_cols + SMI_magnitude_cols + SMI_total_cols + AZL_cols]
X_lk4 = subdata[crop_cols + SPEI_monthly_cols + AZL_cols].drop(dropcols, axis="columns")
X_lk5 = subdata[crop_cols + SMI_monthly_cols + AZL_cols]
X_lk6 = subdata[crop_cols + SPEI_monthly_cols + SMI_monthly_cols + AZL_cols].drop(dropcols, axis="columns")
X_lk7 = subdata[crop_cols + SPEI_monthly_cols + SMI_monthly_cols + AZL_cols + SMI_total_cols].drop(dropcols, axis="columns")
X_lk8 = subdata[crop_cols + SPEI_monthly_cols + SMI_monthly_cols + AZL_cols + SMI_total_cols + LSTNDVI_cols].drop(dropcols, axis="columns")
X_lk9 = subdata[crop_cols + SPEI_monthly_cols + SMI_monthly_cols + AZL_cols + SMI_total_cols + LSTNDVI_cols].drop(dropcols, axis="columns")

# ----------------------------------------------------------------------------------------------- #
# parametrization

xgb_init = xgb.XGBRegressor(
    booster = 'gbtree',
    tree_method = 'hist'
)

param_grid = {'n_estimators':[200], # tuned later via early stopping
              'learning_rate':[0.05, 0.1, 0.2],
              'max_depth':[4, 5, 6, 7, 8, 9],
              'subsample':[0.7, 0.8, 0.9],
              'colsample_bytree':[0.7, 0.8, 0.9],
              'gamma':[0, 0.1, 1]
}

# ----------------------------------------------------------------------------------------------- #
# train in nested cross validation for performance metrics

model_lk1, cvscores_lk1, holdoutscores_lk1, best_params_lk1 = trainXGB(xgb_init, param_grid, X_lk1, y, repetitions=10)
model_lk2, cvscores_lk2, holdoutscores_lk2, best_params_lk2 = trainXGB(xgb_init, param_grid, X_lk2, y, repetitions=10)
model_lk3, cvscores_lk3, holdoutscores_lk3, best_params_lk3 = trainXGB(xgb_init, param_grid, X_lk3, y, repetitions=10)
model_lk4, cvscores_lk4, holdoutscores_lk4, best_params_lk4 = trainXGB(xgb_init, param_grid, X_lk4, y, repetitions=10)
model_lk5, cvscores_lk5, holdoutscores_lk5, best_params_lk5 = trainXGB(xgb_init, param_grid, X_lk5, y, repetitions=10)
model_lk6, cvscores_lk6, holdoutscores_lk6, best_params_lk6 = trainXGB(xgb_init, param_grid, X_lk6, y, repetitions=10)
model_lk7, cvscores_lk7, holdoutscores_lk7, best_params_lk7 = trainXGB(xgb_init, param_grid, X_lk7, y, repetitions=10)
model_lk8, cvscores_lk8, holdoutscores_lk8, best_params_lk8 = trainXGB(xgb_init, param_grid, X_lk8, y, repetitions=10)
model_lk9, cvscores_lk9, holdoutscores_lk9, best_params_lk9 = trainXGB(xgb_init, param_grid, X_lk9, y, repetitions=10)

# 9b is using the same features as 9, but only data where rel_gap > 0
# this specific model run has been started manually by changing the code above
model_lk9b, cvscores_lk9b, holdoutscores_lk9b, best_params_lk9b = trainXGB(xgb_init, param_grid, X_lk9, y, repetitions=10)

# ----------------------------------------------------------------------------------------------- #
# compute SHAP values

shapvals_lk1 = shap.TreeExplainer(model_lk1).shap_values(X_lk1)
shapvals_lk2 = shap.TreeExplainer(model_lk2).shap_values(X_lk2)
shapvals_lk3 = shap.TreeExplainer(model_lk3).shap_values(X_lk3)
shapvals_lk4 = shap.TreeExplainer(model_lk4).shap_values(X_lk4)
shapvals_lk5 = shap.TreeExplainer(model_lk5).shap_values(X_lk5)
shapvals_lk6 = shap.TreeExplainer(model_lk6).shap_values(X_lk6)
shapvals_lk7 = shap.TreeExplainer(model_lk7).shap_values(X_lk7)
shapvals_lk8 = shap.TreeExplainer(model_lk8).shap_values(X_lk8)
shapvals_lk9 = shap.TreeExplainer(model_lk9).shap_values(X_lk9)
shapvals_lk9b = shap.TreeExplainer(model_lk9b).shap_values(X_lk9)

# ----------------------------------------------------------------------------------------------- #
# save everything (hard-coded)

pd.Series(cvscores_lk1).to_csv("cvscores_lk1.csv")
pd.Series(holdoutscores_lk1).to_csv("holdoutscores_lk1.csv")
pd.DataFrame(best_params_lk1).to_csv("best_params_lk1.csv")
model_lk1.save_model("model_lk1.json")
np.save("shapvals_lk1.npy", shapvals_lk1)

pd.Series(cvscores_lk2).to_csv("cvscores_lk2.csv")
pd.Series(holdoutscores_lk2).to_csv("holdoutscores_lk2.csv")
pd.DataFrame(best_params_lk2).to_csv("best_params_lk2.csv")
model_lk2.save_model("model_lk2.json")
np.save("shapvals_lk2.npy", shapvals_lk2)

pd.Series(cvscores_lk3).to_csv("cvscores_lk3.csv")
pd.Series(holdoutscores_lk3).to_csv("holdoutscores_lk3.csv")
pd.DataFrame(best_params_lk3).to_csv("best_params_lk3.csv")
model_lk3.save_model("model_lk3.json")
np.save("shapvals_lk3.npy", shapvals_lk3)
shapvals_lk3 = np.load("shapvals_lk3.npy")

pd.Series(cvscores_lk4).to_csv("cvscores_lk4.csv")
pd.Series(holdoutscores_lk4).to_csv("holdoutscores_lk4.csv")
pd.DataFrame(best_params_lk4).to_csv("best_params_lk4.csv")
model_lk4.save_model("model_lk4.json")
np.save("shapvals_lk4.npy", shapvals_lk4)

pd.Series(cvscores_lk5).to_csv("cvscores_lk5.csv")
pd.Series(holdoutscores_lk5).to_csv("holdoutscores_lk5.csv")
pd.DataFrame(best_params_lk5).to_csv("best_params_lk5.csv")
model_lk5.save_model("model_lk5.json")
np.save("shapvals_lk5.npy", shapvals_lk5)

pd.Series(cvscores_lk6).to_csv("cvscores_lk6.csv")
pd.Series(holdoutscores_lk6).to_csv("holdoutscores_lk6.csv")
pd.DataFrame(best_params_lk6).to_csv("best_params_lk6.csv")
model_lk6.save_model("model_lk6.json")
np.save("shapvals_lk6.npy", shapvals_lk6)

pd.Series(cvscores_lk7).to_csv("cvscores_lk7.csv")
pd.Series(holdoutscores_lk7).to_csv("holdoutscores_lk7.csv")
pd.DataFrame(best_params_lk7).to_csv("best_params_lk7.csv")
model_lk7.save_model("model_lk7.json")
np.save("shapvals_lk7.npy", shapvals_lk7)
shapvals_lk7 = np.load("shapvals_lk7.npy")

pd.Series(cvscores_lk8).to_csv("cvscores_lk8.csv")
pd.Series(holdoutscores_lk8).to_csv("holdoutscores_lk8.csv")
pd.DataFrame(best_params_lk8).to_csv("best_params_lk8.csv")
model_lk8.save_model("model_lk8.json")
np.save("shapvals_lk8.npy", shapvals_lk8)
shapvals_lk8 = np.load("shapvals_lk8.npy")

pd.Series(cvscores_lk8).to_csv("cvscores_lk8b.csv")
pd.Series(holdoutscores_lk8).to_csv("holdoutscores_lk8b.csv")
pd.DataFrame(best_params_lk8).to_csv("best_params_lk8b.csv")
model_lk8.save_model("model_lk8b.json")
np.save("shapvals_lk8b.npy", shapvals_lk8)
shapvals_lk8 = np.load("shapvals_lk8b.npy")

pd.Series(cvscores_lk9).to_csv("cvscores_lk9.csv")
pd.Series(holdoutscores_lk9).to_csv("holdoutscores_lk9.csv")
pd.DataFrame(best_params_lk9).to_csv("best_params_lk9.csv")
model_lk9.save_model("model_lk9.json")
np.save("shapvals_lk9.npy", shapvals_lk9)
shapvals_lk9 = np.load("shapvals_lk9.npy")

pd.Series(cvscores_lk9b).to_csv("cvscores_lk9b.csv")
pd.Series(holdoutscores_lk9b).to_csv("holdoutscores_lk9b.csv")
pd.DataFrame(best_params_lk9b).to_csv("best_params_lk9b.csv")
model_lk9b.save_model("model_lk9b.json")
np.save("shapvals_lk9b.npy", shapvals_lk9b)
X_lk9.to_csv("X_lk9.csv")

# wheat
#pd.Series(cvscores_lk9).to_csv("cvscores_lk9wheat.csv")
#pd.Series(holdoutscores_lk9).to_csv("holdoutscores_lk9wheat.csv")
#pd.DataFrame(best_params_lk9).to_csv("best_params_lk9wheat.csv")
#model_lk9.save_model("model_lk9wheat.json")
#np.save("shapvals_lk9wheat.npy", shapvals_lk9)
#X_lk9.to_csv("X_lk9wheat.csv")

# rye
#pd.Series(cvscores_lk9).to_csv("cvscores_lk9rye.csv")
#pd.Series(holdoutscores_lk9).to_csv("holdoutscores_lk9rye.csv")
#pd.DataFrame(best_params_lk9).to_csv("best_params_lk9rye.csv")
#model_lk9.save_model("model_lk9rye.json")
#np.save("shapvals_lk9rye.npy", shapvals_lk9)
#X_lk9.to_csv("X_lk9rye.csv")