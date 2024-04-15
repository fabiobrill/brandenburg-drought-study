import pandas as pd

# read price data (not public) and match units
prices = pd.read_csv("../../data/raw/tables/prices_ami.csv", delimiter=";", decimal=",", index_col=0)
prices = prices.divide(10)
prices.loc["potatoes",] = prices.loc["potatoes",].multiply(10)
prices.loc["potatoes_starch",] = prices.loc["potatoes_starch",].multiply(10)
prices = prices.round(2)
print(prices)