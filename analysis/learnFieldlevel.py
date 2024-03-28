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
os.chdir("../data/processed")
data = pd.read_csv("all_indicators_on_exposure.csv", encoding='latin-1')

subdata = data.dropna() #.sample(40000)

# ----------------------------------------------------------------------------------------------- #
# indexing to select columns from data that start with "SPEI_", "lstvndi_", "SMI_total_", "AZL_"

subdata["crop_type"] = subdata["crop"].astype("category").cat.codes #categorical
#subdata = pd.get_dummies(subdata, columns=["crop"]) # 1-hot encoding
crop_cols = [col for col in subdata.columns if col.startswith('crop_')]
SPEI_cols = [col for col in subdata.columns if col.startswith('SPEI_')]
SMI_cols = [col for col in subdata.columns if col.startswith('SMI_')]
magnitude_cols = [col for col in subdata.columns if col.endswith('magnitude')]
vulnerability_cols = ['AZL', 'TWI', 'NFK']

# target variable
y = subdata["LSTNDVI_anom"]

# ----------------------------------------------------------------------------------------------- #
# feature selection

X_f1 = subdata[magnitude_cols]
X_f2 = subdata[crop_cols + magnitude_cols + vulnerability_cols]
X_f22 = subdata[crop_cols + magnitude_cols]
X_f3 = subdata[crop_cols + SPEI_cols].drop("SPEI_magnitude", axis="columns")
X_f4 = subdata[crop_cols + SMI_cols].drop("SMI_magnitude", axis="columns")
X_f42 = subdata[crop_cols + SPEI_cols + SMI_cols].drop(["SPEI_magnitude", "SMI_magnitude"], axis="columns")
X_f5 = subdata[crop_cols + SPEI_cols + SMI_cols + vulnerability_cols].drop(["SPEI_magnitude", "SMI_magnitude"], axis="columns")
X_f6 = subdata[['cropcode'] + SPEI_cols + SMI_cols + vulnerability_cols + ['SMI_total']].drop(magnitude_cols, axis="columns")
X_f7 = subdata[crop_cols + SPEI_cols + SMI_cols + vulnerability_cols + magnitude_cols].drop(["SPEI_magnitude", "SMI_magnitude"], axis="columns")

# ----------------------------------------------------------------------------------------------- #
# parametrization

xgb_init = xgb.XGBRegressor(
    booster = 'gbtree',
    tree_method = 'hist'
)

# 10% subset
param_grid = {'n_estimators':[300], # tuned later via early stopping
              'learning_rate':[0.05, 0.1, 0.2],
              'max_depth':[4,5,6,7,8,9,10,12,15],
              'subsample':[0.7, 0.8, 0.9],
              'colsample_bytree':[0.7, 0.8, 0.9],
              'gamma':[0, 0.1, 1]
}

# full data
param_grid = {'n_estimators':[500], # tuned later via early stopping
              'learning_rate':[0.04],
              'max_depth':[15, 20],
              'subsample':[0.8],
              'colsample_bytree':[0.8],
              'gamma':[0]
}
# ----------------------------------------------------------------------------------------------- #
# train in nested cross validation for performance metrics

model_f1, cvscores_f1, holdoutscores_f1, best_params_f1 = trainXGB(xgb_init, param_grid, X_f1, y, repetitions=10)
model_f2, cvscores_f2, holdoutscores_f2, best_params_f2 = trainXGB(xgb_init, param_grid, X_f2, y, repetitions=10)
model_f3, cvscores_f3, holdoutscores_f3, best_params_f3 = trainXGB(xgb_init, param_grid, X_f3, y, repetitions=10)
model_f4, cvscores_f4, holdoutscores_f4, best_params_f4 = trainXGB(xgb_init, param_grid, X_f4, y, repetitions=10)
model_f5, cvscores_f5, holdoutscores_f5, best_params_f5 = trainXGB(xgb_init, param_grid, X_f5, y, repetitions=10)
model_f6, cvscores_f6, holdoutscores_f6, best_params_f6 = trainXGB(xgb_init, param_grid, X_f6, y, repetitions=10)
model_f7, cvscores_f7, holdoutscores_f7, best_params_f7 = trainXGB(xgb_init, param_grid, X_f7, y, repetitions=10)

# ----------------------------------------------------------------------------------------------- #
# compute SHAP values

shapvals_f1 = shap.TreeExplainer(model_f1).shap_values(X_f1)
shapvals_f2 = shap.TreeExplainer(model_f2).shap_values(X_f2)
shapvals_f3 = shap.TreeExplainer(model_f3).shap_values(X_f3)
shapvals_f4 = shap.TreeExplainer(model_f4).shap_values(X_f4)
shapvals_f5 = shap.TreeExplainer(model_f5).shap_values(X_f5)
shapvals_f6 = shap.TreeExplainer(model_f6).shap_values(X_f6)
shapvals_f7 = shap.TreeExplainer(model_f7).shap_values(X_f7)

# ----------------------------------------------------------------------------------------------- #
# save everything hard-coded

pd.Series(cvscores_f1).to_csv("cvscores_f1.csv")
pd.Series(holdoutscores_f1).to_csv("holdoutscores_f1.csv")
pd.DataFrame(best_params_f1).to_csv("best_params_f1.csv")
model_f1.save_model("model_f1.json")
np.save("shapvals_f1.npy", shapvals_f1)

pd.Series(cvscores_f2).to_csv("cvscores_f2.csv")
pd.Series(holdoutscores_f2).to_csv("holdoutscores_f2.csv")
pd.DataFrame(best_params_f2).to_csv("best_params_f2.csv")
model_f2.save_model("model_f2.json")
np.save("shapvals_f2.npy", shapvals_f2)
shapvals_f2 = np.load("shapvals_f2.npy")

pd.Series(cvscores_f3).to_csv("cvscores_f3.csv")
pd.Series(holdoutscores_f3).to_csv("holdoutscores_f3.csv")
pd.DataFrame(best_params_f3).to_csv("best_params_f3.csv")
model_f3.save_model("model_f3.json")
np.save("shapvals_f3.npy", shapvals_f3)

pd.Series(cvscores_f4).to_csv("cvscores_f4.csv")
pd.Series(holdoutscores_f4).to_csv("holdoutscores_f4.csv")
pd.DataFrame(best_params_f4).to_csv("best_params_f4.csv")
model_f4.save_model("model_f4.json")
np.save("shapvals_f4.npy", shapvals_f4)

pd.Series(cvscores_f5).to_csv("cvscores_f5.csv")
pd.Series(holdoutscores_f5).to_csv("holdoutscores_f5.csv")
pd.DataFrame(best_params_f5).to_csv("best_params_f5.csv")
model_f5.save_model("model_f5.json")
np.save("shapvals_f5.npy", shapvals_f5)

pd.Series(cvscores_f6).to_csv("cvscores_f6.csv")
pd.Series(holdoutscores_f6).to_csv("holdoutscores_f6.csv")
pd.DataFrame(best_params_f6).to_csv("best_params_f6.csv")
model_f6.save_model("model_f6.json")
np.save("shapvals_f6.npy", shapvals_f6)
shapvals_f6 = np.load("shapvals_f6.npy")

pd.Series(cvscores_f7).to_csv("cvscores_f7.csv")
pd.Series(holdoutscores_f7).to_csv("holdoutscores_f7.csv")
pd.DataFrame(best_params_f7).to_csv("best_params_f7.csv")
model_f7.save_model("model_f7.json")
np.save("shapvals_f7.npy", shapvals_f7)
np.save("X_f7.npy", X_f7)
shapvals_f7 = np.load("../models/shapvals_f7.npy")
model_f7 = xgb.XGBRegressor()
model_f7.load_model("model_f7.json")