import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

full_data = pd.read_csv("../data/processed/holdoutscores_lk7.csv", index_col=0)
predrought = pd.read_csv("../data/processed/holdoutscores_2013-2017.csv", index_col=0)
drought = pd.read_csv("../data/processed/holdoutscores_2018-2022.csv", index_col=0)
wheat = pd.read_csv("../data/processed/holdoutscores_wheat.csv", index_col=0)
rye = pd.read_csv("../data/processed/holdoutscores_rye.csv", index_col=0)
wheatrye = pd.read_csv("../data/processed/holdoutscores_wheatrye.csv", index_col=0)

sns.distplot(predrought, label="2013-2017", hist=False)
sns.distplot(drought, label="2018-2022", hist=False)
sns.distplot(full_data, label="2013-2022", hist=False, color="green")
plt.legend()
plt.title("")
plt.xlabel("R2 Score")
plt.xlim(0,1)
plt.savefig("fig13a.png", dpi=300, bbox_inches="tight")

sns.distplot(wheat, label="Winter Wheat (n=141)", hist=False, color="red")
sns.distplot(rye, label="Rye (n=151)", hist=False)
sns.distplot(wheatrye, label="Wheat & Rye (n=292)", hist=False, color="orange")
sns.distplot(full_data, label="All Crops (n=1436)", hist=False, color="green")
plt.legend()
plt.title("")
plt.xlabel("R2 Score")
plt.xlim(0,1)
plt.savefig("fig13b.png", dpi=300, bbox_inches="tight")