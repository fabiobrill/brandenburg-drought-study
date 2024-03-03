def trainXGB(algorithm, param_grid, X, y, holdout=0.3, repetitions=10, ncv=5, cores=-1):
    """
    wrapper for repeated model fitting with random train test split, including the 
    computation of performance metrics and the selection of the best model
    """

    cvscores = []
    holdoutscores = []
    #resultlist = []
    paramlist = []
    estimatorlist = []

    # convert to numpy for xgb - and revert this later to get feature names in SHAP plots
    Xnp = X.to_numpy()
    ynp = y.to_numpy()

    for i in range(repetitions):
        print(i)

        # outer loop for validation
        X_train, X_test, y_train, y_test = train_test_split(Xnp, ynp, test_size=holdout)
        #trainlist.append(X_train)
        
        # inner loop to optimize the hyperparameters
        gs = GridSearchCV(algorithm, param_grid=param_grid, cv=ncv, n_jobs=cores)
        gs_results = gs.fit(X_train, y_train)

        # store the results in separate list
        cvscores.append(gs_results.best_score_)
        paramlist.append(gs_results.best_params_)
        estimatorlist.append(gs_results.best_estimator_)
        #resultlist.append(pd.DataFrame({'rank': gs_results.cv_results_['rank_test_score'],
        #                                'mean': gs_results.cv_results_['mean_test_score'],
        #                                'sd'  : gs_results.cv_results_['std_test_score'],
        #                                'params': gs_results.cv_results_['params']}).sort_values("rank"))
        
        # re-train best estimator on full training set and compute score on holdout set
        best_model_of_iteration = gs_results.best_estimator_.fit(X_train, y_train)
        holdoutscores.append(r2_score(y_test, best_model_of_iteration.predict(X_test)))
    
    # take the best model of all iterations by score on holdout set, 
    # activate early stopping and fit on entire data of the inner loop
    best_model = estimatorlist[np.argmax(holdoutscores)]
    best_model.set_params(early_stopping_rounds=2)
    best_model.fit(X_train, y_train, eval_set=[(X_test, y_test)])
    n_stop = best_model.get_booster().num_boosted_rounds()
    best_model.set_params(n_estimators = n_stop, early_stopping_rounds=None)

    return(best_model, cvscores, holdoutscores, paramlist)

def plotSkill(holdoutscores, cvscores, plottitle):
    sns.distplot(holdoutscores, label="holdout", color="tomato") 
    sns.distplot(cvscores, label="cv", color="slateblue")
    plt.legend()
    plt.title(plottitle)
    plt.xlim(0,1)