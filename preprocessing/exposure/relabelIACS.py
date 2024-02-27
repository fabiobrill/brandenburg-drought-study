def relabelIACS(cropdata):
    if "CODE" in cropdata.columns:
        print("CODE column found")
        cropdata["crop"] = cropdata.CODE.map({
        "424" : "grass_crops",
        "591" : "non_active",
        "452" : "mowing_meadows",
        "121" : "winter_rye",
        "122" : "summer_rye",
        "451" : "meadows",
        "115" : "winter_wheat",
        #"116" : "wheat", #summer_ # discontiuned yield reports for summer wheat
        "311" : "winter_canola",
        "312" : "summer_canola",
        "315" : "winter_ruebsen",
        "316" : "summer_ruebsen",
        "422" : "clover_grassland",
        "131" : "winter_barley",
        "132" : "summer_barley",
        "411" : "silage_maize",
        "156" : "winter_triticale",
        "157" : "summer_triticale",
        "126" : "winter_mix",
        "145" : "summer_mix",
        "171" : "grain_maize",
        "210" : "peas",
        "220" : "field_beans",
        "230" : "lupines",
        "240" : "peas_beans_mix",
        "330" : "soybean",
        "320" : "sunflower",
        "601" : "potatoes_starch",
        "602" : "potatoes",
        "603" : "sugarbeet",
        "142" : "oat", #winter_
        "143" : "oat" #summer_
        })
    elif "K_ART" in cropdata.columns:
        print("K_ART column found")
        cropdata["crop"] = cropdata.K_ART.map({
        "424" : "grass_crops",
        "591" : "non_active",
        "452" : "mowing_meadows",
        "121" : "winter_rye",
        "122" : "summer_rye",
        "451" : "meadows",
        "115" : "winter_wheat",
        #"116" : "wheat", #summer_ # discontiuned yield reports for summer wheat
        "311" : "winter_canola",
        "312" : "summer_canola",
        "315" : "winter_ruebsen",
        "316" : "summer_ruebsen",
        "422" : "clover_grassland",
        "131" : "winter_barley",
        "132" : "summer_barley",
        "411" : "silage_maize",
        "156" : "winter_triticale",
        "157" : "summer_triticale",
        "126" : "winter_mix",
        "145" : "summer_mix",
        "171" : "grain_maize",
        "210" : "peas",
        "220" : "field_beans",
        "230" : "lupines",
        "240" : "peas_beans_mix",
        "330" : "soybean",
        "320" : "sunflower",
        "611" : "potatoes", # K_ART_K: fruhkartoffeln
        "612" : "potatoes", # K_ART_K: sonstige speisekartoffen
        "613" : "potatoes", # K_ART_K: Industriekartoffeln
        "614" : "potatoes", # K_ART_K: Futterkartoffeln
        "615" : "potatoes", # K_ART_K: Pflanzkartoffeln
        "619" : "potatoes", # K_ART_K: Sonstige Kartoffeln
        "641" : "potatoes", # K_ART_K: Vertragsanbau
        "642" : "potatoes", # K_ART_K: Vertragsanbau
        "620" : "sugarbeet",
        "142" : "oat", #winter_
        "143" : "oat" #summer_
        })
    else:
        raise ValueError("no matching column name found")
    
    return(cropdata)
