import csv
import os
import pickle
import numpy as np
from sage.all import *

# Import functions from graph_tools
load('graph_tools.sage')

# Try to import Orange - handle gracefully if not available
ORANGE_AVAILABLE = False
SKLEARN_AVAILABLE = False

try:
    from Orange.data import Table, Domain, ContinuousVariable, DiscreteVariable
    ORANGE_AVAILABLE = True
    print("✓ Orange Data Mining is available")
except ImportError as e:
    print("⚠ Orange Data Mining is NOT available")

# Try sklearn (always, as it's useful for both Orange and standalone)
try:
    from sklearn.ensemble import RandomForestClassifier
    import sklearn
    SKLEARN_AVAILABLE = True
    if not ORANGE_AVAILABLE:
        print("✓ Sklearn is available (using fallback mode)")
except ImportError:
    if not ORANGE_AVAILABLE:
        print("⚠ Neither Orange nor sklearn is available")

# Define the feature domain for Orange
def create_orange_domain():
    """Create Orange domain matching the training data features."""
    # The model was trained with one-hot encoded discrete variables
    # and WITHOUT stevilo_vozlisc, stevilo_povezav, alpha, alpha_power2
    variables = [
        ContinuousVariable("Eulerjev=False"),
        ContinuousVariable("Eulerjev=True"),
        ContinuousVariable("drevo=False"),
        ContinuousVariable("drevo=True"),
        ContinuousVariable("dvodelen=False"),
        ContinuousVariable("dvodelen=True"),
        ContinuousVariable("gostota"),
        ContinuousVariable("gozd=False"),
        ContinuousVariable("gozd=True"),
        ContinuousVariable("kromaticno_stevilo"),
        ContinuousVariable("max_stopnja"),
        ContinuousVariable("min_stopnja"),
        ContinuousVariable("obseg"),
        ContinuousVariable("premer"),
        ContinuousVariable("radij"),
        ContinuousVariable("regularen=False"),
        ContinuousVariable("regularen=True"),
        ContinuousVariable("stiricikli"),
        ContinuousVariable("tricikli"),
        ContinuousVariable("vse_neparne=False"),
        ContinuousVariable("vse_neparne=True")
    ]
    return Domain(variables)

# Load the three ML models
def load_models():
    """Load the three prediction models from the models directory."""
    
    # Check if models directory exists
    if not os.path.exists('models'):
        print("⚠ 'models' directory not found!")
        return None
    
    # List all files in models directory
    print("Files in models/ directory:")
    model_files_list = [f for f in os.listdir('models') if not f.endswith(':Zone.Identifier') and not f.endswith(':mshield')]
    for f in model_files_list:
        print(f"  - {f}")
    
    models = {}
    
    # First try sklearn format (simpler, no Qt dependencies)
    if SKLEARN_AVAILABLE:
        sklearn_patterns = {
            'alpha_od_eq_1': 'models/sklearn_alpha_od_eq_1.pkl',
            'alpha_od_eq_alpha': 'models/sklearn_alpha_od_eq_alpha.pkl',
            'alpha_od_eq_alpha2': 'models/sklearn_alpha_od_eq_alpha2.pkl'
        }
        
        for key, filepath in sklearn_patterns.items():
            try:
                if os.path.exists(filepath):
                    with open(filepath, 'rb') as f:
                        models[key] = pickle.load(f)
                    print(f"✓ Loaded sklearn model: {key}")
            except Exception as e:
                print(f"Error loading sklearn {key}: {e}")
    
    # If no sklearn models, try Orange format
    if len(models) == 0 and ORANGE_AVAILABLE:
        orange_patterns = {
            'alpha_od_eq_1': 'models/model-alpha_od=1.pkcls',
            'alpha_od_eq_alpha': 'models/model-alpha_od=alpha.pkcls',
            'alpha_od_eq_alpha2': 'models/model-alpha_od=alpha_2.pkcls'
        }
        
        for key, filepath in orange_patterns.items():
            try:
                if os.path.exists(filepath):
                    with open(filepath, 'rb') as f:
                        model = pickle.load(f)
                        models[key] = model
                    
                    # Show what features this model expects
                    print(f"✓ Loaded Orange model: {key}")
                    if hasattr(model, 'domain'):
                        print(f"  Expected features ({len(model.domain.attributes)}):")
                        for i, attr in enumerate(model.domain.attributes):
                            print(f"    {i+1}. {attr.name} ({type(attr).__name__})")
                    
                    # Check underlying sklearn model
                    if hasattr(model, 'skl_model'):
                        sklearn_model = model.skl_model
                        if hasattr(sklearn_model, 'n_features_in_'):
                            print(f"  Sklearn model expects {sklearn_model.n_features_in_} features")
                        
            except Exception as e:
                print(f"Error loading Orange {key}: {e}")
    
    if len(models) == 0:
        print("⚠ No models loaded!")
        print("  Solution: Install PyQt5 with: sage -pip install PyQt5")
        return None
    
    print(f"✓ Successfully loaded {len(models)}/3 models")
    return models

# Load models once at startup
ML_MODELS = load_models()
ORANGE_DOMAIN = create_orange_domain() if ORANGE_AVAILABLE else None

def extract_features(G, alpha, alpha_power2, premer, max_stopnja, min_stopnja, 
                     vse_neparne, obseg, radij, dvodelen, drevo, gozd, 
                     Eulerjev, kromaticno_stevilo, gostota, regularen, 
                     tricikli, stiricikli):
    """
    Extract features from graph properties for ML model input.
    Returns a list of features in the expected order for the models.
    """
    stevilo_vozlisc = G.order()
    stevilo_povezav = G.size()
    
    # Handle infinity values
    premer_val = premer if premer != float('inf') else -1
    obseg_val = obseg if obseg != float('inf') else -1
    radij_val = radij if radij != float('inf') else -1
    
    features = [
        stevilo_vozlisc,
        stevilo_povezav,
        alpha,
        alpha_power2,
        premer_val,
        max_stopnja,
        min_stopnja,
        int(vse_neparne),
        obseg_val,
        radij_val,
        int(dvodelen),
        int(drevo),
        int(gozd),
        int(Eulerjev),
        kromaticno_stevilo,
        float(gostota),
        int(regularen),
        tricikli,
        stiricikli
    ]
    
    print(f"  Extracted {len(features)} features: {features}")
    return features

def extract_features_for_orange(G, alpha, alpha_power2, premer, max_stopnja, min_stopnja, 
                                vse_neparne, obseg, radij, dvodelen, drevo, gozd, 
                                Eulerjev, kromaticno_stevilo, gostota, regularen, 
                                tricikli, stiricikli):
    """
    Extract features from graph properties for Orange ML model input.
    Returns features with one-hot encoded discrete variables, matching training format.
    NOTE: Does NOT include stevilo_vozlisc, stevilo_povezav, alpha, alpha_power2
    """
    stevilo_vozlisc = G.order()
    
    # Handle infinity values
    premer_val = float(premer) if premer != float('inf') else -1.0
    obseg_val = float(obseg) if obseg != float('inf') else -1.0
    radij_val = float(radij) if radij != float('inf') else -1.0
    
    # Normalize tricikli and stiricikli by number of vertices (as done in training)
    tricikli_normalized = float(tricikli) / float(stevilo_vozlisc) if stevilo_vozlisc > 0 else 0.0
    stiricikli_normalized = float(stiricikli) / float(stevilo_vozlisc) if stevilo_vozlisc > 0 else 0.0
    
    # One-hot encode discrete variables (as floats for Orange ContinuousVariable)
    features = [
        1.0 if not Eulerjev else 0.0,  # Eulerjev=False
        1.0 if Eulerjev else 0.0,      # Eulerjev=True
        1.0 if not drevo else 0.0,     # drevo=False
        1.0 if drevo else 0.0,         # drevo=True
        1.0 if not dvodelen else 0.0,  # dvodelen=False
        1.0 if dvodelen else 0.0,      # dvodelen=True
        float(gostota),                # gostota
        1.0 if not gozd else 0.0,      # gozd=False
        1.0 if gozd else 0.0,          # gozd=True
        float(kromaticno_stevilo),     # kromaticno_stevilo
        float(max_stopnja),            # max_stopnja
        float(min_stopnja),            # min_stopnja
        obseg_val,                     # obseg
        premer_val,                    # premer
        radij_val,                     # radij
        1.0 if not regularen else 0.0, # regularen=False
        1.0 if regularen else 0.0,     # regularen=True
        stiricikli_normalized,         # stiricikli / stevilo_vozlisc
        tricikli_normalized,           # tricikli / stevilo_vozlisc
        1.0 if not vse_neparne else 0.0, # vse_neparne=False
        1.0 if vse_neparne else 0.0   # vse_neparne=True
    ]
    
    print(f"  Extracted {len(features)} features for Orange (tricikli: {tricikli}/{stevilo_vozlisc} = {tricikli_normalized:.3f}, stiricikli: {stiricikli}/{stevilo_vozlisc} = {stiricikli_normalized:.3f})")
    return features

def extract_features_for_sklearn(G, alpha, alpha_power2, premer, max_stopnja, min_stopnja, 
                                 vse_neparne, obseg, radij, dvodelen, drevo, gozd, 
                                 Eulerjev, kromaticno_stevilo, gostota, regularen, 
                                 tricikli, stiricikli):
    """
    Extract features as numpy array for sklearn models.
    Uses one-hot encoding for discrete variables to match training format.
    NOTE: Does NOT include stevilo_vozlisc, stevilo_povezav, alpha, alpha_power2
    """
    stevilo_vozlisc = G.order()
    
    # Handle infinity values
    premer_val = float(premer) if premer != float('inf') else -1.0
    obseg_val = float(obseg) if obseg != float('inf') else -1.0
    radij_val = float(radij) if radij != float('inf') else -1.0
    
    # Normalize tricikli and stiricikli by number of vertices (as done in training)
    tricikli_normalized = float(tricikli) / float(stevilo_vozlisc) if stevilo_vozlisc > 0 else 0.0
    stiricikli_normalized = float(stiricikli) / float(stevilo_vozlisc) if stevilo_vozlisc > 0 else 0.0
    
    # One-hot encode discrete variables
    features = np.array([[
        1.0 if not Eulerjev else 0.0,  # Eulerjev=False
        1.0 if Eulerjev else 0.0,      # Eulerjev=True
        1.0 if not drevo else 0.0,     # drevo=False
        1.0 if drevo else 0.0,         # drevo=True
        1.0 if not dvodelen else 0.0,  # dvodelen=False
        1.0 if dvodelen else 0.0,      # dvodelen=True
        float(gostota),
        1.0 if not gozd else 0.0,      # gozd=False
        1.0 if gozd else 0.0,          # gozd=True
        float(kromaticno_stevilo),
        float(max_stopnja),
        float(min_stopnja),
        obseg_val,
        premer_val,
        radij_val,
        1.0 if not regularen else 0.0, # regularen=False
        1.0 if regularen else 0.0,     # regularen=True
        stiricikli_normalized,         # stiricikli / stevilo_vozlisc
        tricikli_normalized,           # tricikli / stevilo_vozlisc
        1.0 if not vse_neparne else 0.0, # vse_neparne=False
        1.0 if vse_neparne else 0.0   # vse_neparne=True
    ]])
    
    print(f"  Extracted {features.shape[1]} features for sklearn (tricikli: {tricikli}/{stevilo_vozlisc} = {tricikli_normalized:.3f}, stiricikli: {stiricikli}/{stevilo_vozlisc} = {stiricikli_normalized:.3f})")
    return features

def predict_alfas(G):
    """
    Izračuna α(G), α_od(G) in α(G²) ter shrani rezultate v CSV.
    
    Args:
        G: Graf za analizo
    
    Rezultati se shranijo v:
    - rezultati.csv: lastnosti in izračunane vrednosti
    - grafi_oblika.csv: graf in povezave (list of tuples)
    """
    
    # Preuredi graf v standardno obliko (vozlišča 0, 1, 2, ...)
    G_relabeled = G.relabel(range(G.order()), inplace=False)
    G = G_relabeled  # Uporabi preurejeni graf za vse nadaljnje izračune
    
    # Preveri, če graf že obstaja v bazi - primerjaj povezave
    edges_list = list(G.edges(labels=False))
    edges_string = str(edges_list)
    
    # Preveri grafi_oblika.csv
    graf_exists_in_oblika = False
    graf_id = None
    
    if os.path.exists('data/grafi_oblika.csv'):
        with open('data/grafi_oblika.csv', 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row['povezave'] == edges_string:
                    graf_exists_in_oblika = True
                    graf_id = row['graf']
                    print(f"Graf najden v grafi_oblika.csv z ID: {graf_id}")
                    print(f"Graf že obstaja v bazi, ne dodajam v nobeno datoteko CSV.")
                    return
    
    # Če graf še ni v grafi_oblika.csv, določi nov ID
    if not graf_exists_in_oblika:
        n = G.order()
        m = G.size()
        
        # Preberi število iteracij za ta (n,m) par
        iteracija = 1
        if os.path.exists('data/grafi_oblika.csv'):
            with open('data/grafi_oblika.csv', 'r') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    if row['graf'].startswith(f"{n}v_{m}e_"):
                        current_iter = int(row['graf'].split('_')[-1])
                        iteracija = max(iteracija, current_iter + 1)
        
        graf_id = f"{n}_{m}_{iteracija}"
    print(f"Dodeljen nov ID grafa: {graf_id}")
    
    # Preveri, če je graf že v rezultati.csv
    graf_exists_in_rezultati = False
    if os.path.exists('data/rezultati.csv'):
        with open('data/rezultati.csv', 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row['graf'] == graf_id:
                    graf_exists_in_rezultati = True
                    print(f"Graf že ima rezultate v rezultati.csv z ID: {graf_id}")
                    return
    

    # ===== IZRAČUNI α(G), α(G²) =====
    print(f"Računam α(G) za {graf_id}...")
    alpha_G = G.independent_set(value_only=True)
    
    print(f"Računam G²...")
    G2 = graph_power(G, 2)
    
    print(f"Računam α(G²) za {graf_id}...")
    alpha_G2 = G2.independent_set(value_only=True)
    
    # ===== IZRAČUN lastnosti grafa =====
    print(f"Računam lastnosti grafa {graf_id}...")
    
    # Osnovne lastnosti
    stevilo_vozlisc = G.order()
    stevilo_povezav = G.size()
    
    # Alpha vrednosti
    alpha = alpha_G
    alpha_od = None  # bo izračunano kasneje
    alpha_power2 = alpha_G2
    
    # Premer
    premer = get_diameter(G)
    
    # Stopnje
    max_stopnja = get_max_degree(G)
    min_stopnja = get_min_degree(G)
    vse_neparne = all_degrees_odd(G)
    
    # Obvod in radij
    obseg = get_girth(G)
    radij = get_radius(G)
    
    # Dvodelnost in drevesa
    dvodelen = G.is_bipartite()
    drevo = G.is_tree()
    gozd = G.is_forest()
    
    # Eulerjev graf
    Eulerjev = G.is_eulerian()
    
    # Kromatično število
    kromaticno_stevilo = get_chromatic_number(G)
    
    # Gostota
    gostota = get_density(G)
    
    # Regularnost
    regularen = G.is_regular()
    
    # Cikli
    tricikli = count_triangles(G)
    stiricikli = count_4cycles(G)

    # ===== DOLOČANJE DRUŽINE GRAFA =====
    print(f"Določam družino grafa {graf_id}...")
    
    druzina = None

    # Preveri, če je dvodelen z neparnimi stopnjami
    if dvodelen and vse_neparne:
        druzina = "dvodelen_neparna_stopenja"
        print(f"  Graf je DVODELEN Z NEPARNIMI STOPNJAMI")
    
    # Preveri, če je kartezični produkt polnih grafov
    elif regularen and stevilo_vozlisc > 4:
        # Poskusi najti a, b tako da n = a*b in stopnja = (a-1) + (b - 1)
        for a in range(2, int(stevilo_vozlisc**0.5) + 1):
            if stevilo_vozlisc % a == 0:
                b = stevilo_vozlisc // a
                if max_stopnja == (a - 1) + (b - 1):
                    druzina = "kartezicni_produkt_polnih"
                    break

    
    # ===== DEJANSKI IZRAČUNI =====
    print(f"Računam α_od(G) za {graf_id}...")
    alpha_od_G = alpha_od_ilp_correct(G)
    alpha_od = alpha_od_G
    
    # ===== PREVERI DEFINITIVNE LASTNOSTI =====
    print(f"Preverjam definitivne lastnosti za {graf_id}...")
    predicted_alpha_equals_alpha_od = None
    predicted_alpha_G2_equals_alpha_od = None

    # Lastnost 1: če alpha = alpha^2, potem sta obe enakosti resnični
    if alpha == alpha_power2:
        predicted_alpha_equals_alpha_od = True
        predicted_alpha_G2_equals_alpha_od = True
        print(f"  Lastnost 1: α(G) = α(G²) → obe enakosti sta TRUE")
    # Lastnost 2: če max_stopnja <= 2, potem alpha_od = alpha^2
    elif max_stopnja <= 2:
        predicted_alpha_G2_equals_alpha_od = True
        print(f"  Lastnost 2: max_stopnja ≤ 2 → α_od(G) = α(G²)")
    # Lastnost 3: če kromaticno_stevilo + 1 = stevilo_vozlisc, potem alpha_od = alpha^2
    elif kromaticno_stevilo + 1 == stevilo_vozlisc:
        predicted_alpha_G2_equals_alpha_od = True
        print(f"  Lastnost 3: χ(G) + 1 = n → α_od(G) = α(G²)")

    # ===== PREVERJANJE NA PODLAGI DRUŽINE =====
    

    if druzina == "dvodelen_neparnih_stopenj":
        # Napoved za dvodelne z neparnimi stopnjami
        predicted_alpha_equals_alpha_od = True
        predicted_alpha_G2_equals_alpha_od = False 
        print(f"  DVODELEN NEPARNIH STOPENJ: α(G) = α_od(G) je TRUE")
    
    elif druzina == "kartezicni_produkt_polnih":
        # Napoved za kartezične produkte
        predicted_alpha_equals_alpha_od = False
        predicted_alpha_G2_equals_alpha_od = True
        print(f"  KARTEZIČNI PRODUKT: obe enakosti sta TRUE")
    

    

    # Dejanske vrednosti
    actual_alpha_equals_alpha_od = (alpha == alpha_od)
    actual_alpha_G2_equals_alpha_od = (alpha_power2 == alpha_od)
    
    # ===== HIERARCHICAL PREDICTION SYSTEM =====
    print(f"\n{'='*60}")
    print(f"HIERARHIČNI SISTEM NAPOVEDI za {graf_id}")
    print(f"{'='*60}")
    
    # Final predictions to be determined hierarchically
    final_pred_alpha_eq_alpha_od = predicted_alpha_equals_alpha_od
    final_pred_alpha_G2_eq_alpha_od = predicted_alpha_G2_equals_alpha_od
    
    # Track which method was used
    method_alpha_eq_alpha_od = None
    method_alpha_G2_eq_alpha_od = None
    
    ml_pred_alpha_od_eq_1 = None
    ml_pred_alpha_eq_alpha_od = None
    ml_pred_alpha_G2_eq_alpha_od = None
    
    # STEP 1: Check if definitive properties gave us predictions
    if predicted_alpha_equals_alpha_od is not None:
        method_alpha_eq_alpha_od = "definitna_lastnost"
        print(f"✓ α=α_od rešitev iz definitivnih lastnosti: {final_pred_alpha_eq_alpha_od}")
    
    if predicted_alpha_G2_equals_alpha_od is not None:
        method_alpha_G2_eq_alpha_od = "definitna_lastnost"
        print(f"✓ α²=α_od rešitev iz definitivnih lastnosti: {final_pred_alpha_G2_eq_alpha_od}")
    
    # STEP 2: Use ML models only for missing predictions
    need_ml_for_alpha_G2 = (final_pred_alpha_G2_eq_alpha_od is None)
    need_ml_for_alpha = (final_pred_alpha_eq_alpha_od is None)
    
    if need_ml_for_alpha_G2 or need_ml_for_alpha:
        print(f"\nPotrebne ML napovedi:")
        if need_ml_for_alpha_G2:
            print(f"  - α²=α_od (ni definitivne rešitve)")
        if need_ml_for_alpha:
            print(f"  - α=α_od (ni definitivne rešitve)")
        
        if ML_MODELS is not None and len(ML_MODELS) > 0:
            print(f"\nIzvajam ML napovedi...")
            
            try:
                # Extract features
                if SKLEARN_AVAILABLE:
                    features = extract_features_for_sklearn(
                        G, alpha, alpha_power2, premer, max_stopnja, min_stopnja,
                        vse_neparne, obseg, radij, dvodelen, drevo, gozd,
                        Eulerjev, kromaticno_stevilo, gostota, regularen,
                        tricikli, stiricikli
                    )
                elif ORANGE_AVAILABLE and ORANGE_DOMAIN is not None:
                    features = extract_features_for_orange(
                        G, alpha, alpha_power2, premer, max_stopnja, min_stopnja,
                        vse_neparne, obseg, radij, dvodelen, drevo, gozd,
                        Eulerjev, kromaticno_stevilo, gostota, regularen,
                        tricikli, stiricikli
                    )
                    features = Table.from_list(ORANGE_DOMAIN, [features])
                else:
                    raise Exception("Nobeden ML sistem ni na voljo")
                
                # STEP 2a: If we need α²=α_od prediction, first check α_od=1
                if need_ml_for_alpha_G2:
                    print(f"\n--- Napovedovanje α²=α_od ---")
                    
                    if 'alpha_od_eq_1' in ML_MODELS:
                        # Predict α_od = 1
                        if SKLEARN_AVAILABLE:
                            pred = ML_MODELS['alpha_od_eq_1'].predict(features)[0]
                            ml_pred_alpha_od_eq_1 = bool(pred)
                            if hasattr(ML_MODELS['alpha_od_eq_1'], 'predict_proba'):
                                prob = ML_MODELS['alpha_od_eq_1'].predict_proba(features)[0]
                                print(f"  1. ML napoved α_od=1: {ml_pred_alpha_od_eq_1} (prob: {prob[1]:.3f})")
                        else:
                            predictions = ML_MODELS['alpha_od_eq_1'](features)
                            pred = predictions[0]
                            if hasattr(pred, 'probabilities'):
                                ml_pred_alpha_od_eq_1 = bool(pred.probabilities[1] > 0.5)
                                print(f"  1. ML napoved α_od=1: {ml_pred_alpha_od_eq_1} (prob: {pred.probabilities[1]:.3f})")
                            else:
                                ml_pred_alpha_od_eq_1 = bool(int(pred))
                                print(f"  1. ML napoved α_od=1: {ml_pred_alpha_od_eq_1}")
                        
                        # If α_od = 1, then α²=α_od is TRUE
                        if ml_pred_alpha_od_eq_1:
                            final_pred_alpha_G2_eq_alpha_od = True
                            method_alpha_G2_eq_alpha_od = "ML_alpha_od=1"
                            print(f"  → Sklep: α_od=1 → α²=α_od je TRUE")
                        else:
                            # α_od ≠ 1, use direct model for α²=α_od
                            print(f"  → α_od≠1, preverjam direktno α²=α_od...")
                            
                            if 'alpha_od_eq_alpha2' in ML_MODELS:
                                if SKLEARN_AVAILABLE:
                                    pred = ML_MODELS['alpha_od_eq_alpha2'].predict(features)[0]
                                    ml_pred_alpha_G2_eq_alpha_od = bool(pred)
                                    if hasattr(ML_MODELS['alpha_od_eq_alpha2'], 'predict_proba'):
                                        prob = ML_MODELS['alpha_od_eq_alpha2'].predict_proba(features)[0]
                                        print(f"  2. ML napoved α²=α_od: {ml_pred_alpha_G2_eq_alpha_od} (prob: {prob[1]:.3f})")
                                else:
                                    predictions = ML_MODELS['alpha_od_eq_alpha2'](features)
                                    pred = predictions[0]
                                    if hasattr(pred, 'probabilities'):
                                        ml_pred_alpha_G2_eq_alpha_od = bool(pred.probabilities[1] > 0.5)
                                        print(f"  2. ML napoved α²=α_od: {ml_pred_alpha_G2_eq_alpha_od} (prob: {pred.probabilities[1]:.3f})")
                                    else:
                                        ml_pred_alpha_G2_eq_alpha_od = bool(int(pred))
                                        print(f"  2. ML napoved α²=α_od: {ml_pred_alpha_G2_eq_alpha_od}")
                                
                                final_pred_alpha_G2_eq_alpha_od = ml_pred_alpha_G2_eq_alpha_od
                                method_alpha_G2_eq_alpha_od = "ML_alpha2=alpha_od"
                    
                    print(f"✓ Končna napoved α²=α_od: {final_pred_alpha_G2_eq_alpha_od} (metoda: {method_alpha_G2_eq_alpha_od})")
                
                # STEP 2b: If we need α=α_od prediction, use direct model
                if need_ml_for_alpha:
                    print(f"\n--- Napovedovanje α=α_od ---")
                    
                    if 'alpha_od_eq_alpha' in ML_MODELS:
                        if SKLEARN_AVAILABLE:
                            pred = ML_MODELS['alpha_od_eq_alpha'].predict(features)[0]
                            ml_pred_alpha_eq_alpha_od = bool(pred)
                            if hasattr(ML_MODELS['alpha_od_eq_alpha'], 'predict_proba'):
                                prob = ML_MODELS['alpha_od_eq_alpha'].predict_proba(features)[0]
                                print(f"  ML napoved α=α_od: {ml_pred_alpha_eq_alpha_od} (prob: {prob[1]:.3f})")
                        else:
                            predictions = ML_MODELS['alpha_od_eq_alpha'](features)
                            pred = predictions[0]
                            if hasattr(pred, 'probabilities'):
                                ml_pred_alpha_eq_alpha_od = bool(pred.probabilities[1] > 0.5)
                                print(f"  ML napoved α=α_od: {ml_pred_alpha_eq_alpha_od} (prob: {pred.probabilities[1]:.3f})")
                            else:
                                ml_pred_alpha_eq_alpha_od = bool(int(pred))
                                print(f"  ML napoved α=α_od: {ml_pred_alpha_eq_alpha_od}")
                        
                        final_pred_alpha_eq_alpha_od = ml_pred_alpha_eq_alpha_od
                        method_alpha_eq_alpha_od = "ML_alpha=alpha_od"
                    
                    print(f"✓ Končna napoved α=α_od: {final_pred_alpha_eq_alpha_od} (metoda: {method_alpha_eq_alpha_od})")
                
            except Exception as e:
                print(f"  ⚠ Napaka pri ML napovedih: {e}")
                import traceback
                traceback.print_exc()
        else:
            print(f"  ⚠ ML modeli niso na voljo")
    else:
        print(f"\n✓ Vse napovedi pridobljene iz definitivnih lastnosti, ML ni potreben")
    
    # SUMMARY
    print(f"\n{'='*60}")
    print(f"POVZETEK NAPOVEDI")
    print(f"{'='*60}")
    print(f"α=α_od:")
    print(f"  Napoved: {final_pred_alpha_eq_alpha_od} (metoda: {method_alpha_eq_alpha_od})")
    print(f"  Dejanska vrednost: {actual_alpha_equals_alpha_od}")
    print(f"  Pravilnost: {'✓ PRAVILNO' if final_pred_alpha_eq_alpha_od == actual_alpha_equals_alpha_od else '✗ NAPAČNO'}")
    
    print(f"\nα²=α_od:")
    print(f"  Napoved: {final_pred_alpha_G2_eq_alpha_od} (metoda: {method_alpha_G2_eq_alpha_od})")
    print(f"  Dejanska vrednost: {actual_alpha_G2_equals_alpha_od}")
    print(f"  Pravilnost: {'✓ PRAVILNO' if final_pred_alpha_G2_eq_alpha_od == actual_alpha_G2_equals_alpha_od else '✗ NAPAČNO'}")
    print(f"{'='*60}\n")
    
    # Shrani graf v grafi_oblika.csv (samo če še ni tam)
    if not graf_exists_in_oblika:
        file_exists = os.path.exists('data/grafi_oblika.csv')
        with open('data/grafi_oblika.csv', 'a', newline='') as f:
            fieldnames = ['graf', 'vozlisca', 'povezave']
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            
            if not file_exists:
                writer.writeheader()
            
            # Get list of vertices
            vozlisca_list = list(G.vertices())
            vozlisca_string = str(vozlisca_list)
            
            writer.writerow({
                'graf': graf_id,
                'vozlisca': vozlisca_string,
                'povezave': edges_string
            })
    
    # Shrani lastnosti grafa v grafi.csv
    file_exists = os.path.exists('data/grafi.csv')
    with open('data/grafi.csv', 'a', newline='') as f:
        fieldnames = [
            'graf', 'druzina', 'Eulerjev', 'alpha', 'alpha^2', 'alpha_od', 'drevo', 'dvodelen',
            'gostota', 'gozd', 'kromaticno_stevilo', 'max_stopnja', 'min_stopnja',
            'obseg', 'premer', 'radij', 'regularen', 'stiricikli', 'tricikli', 'vse_neparne'
        ]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        
        if not file_exists:
            writer.writeheader()
        
        writer.writerow({
            'graf': graf_id,
            'druzina': druzina if druzina else '',
            'Eulerjev': Eulerjev,
            'alpha': alpha,
            'alpha^2': alpha_power2,
            'alpha_od': alpha_od,
            'drevo': drevo,
            'dvodelen': dvodelen,
            'gostota': gostota,
            'gozd': gozd,
            'kromaticno_stevilo': kromaticno_stevilo,
            'max_stopnja': max_stopnja,
            'min_stopnja': min_stopnja,
            'obseg': obseg if obseg != float('inf') else None,
            'premer': premer if premer != float('inf') else None,
            'radij': radij if radij != float('inf') else None,
            'regularen': regularen,
            'stiricikli': stiricikli,
            'tricikli': tricikli,
            'vse_neparne': vse_neparne
        })
    
    # Shrani napovedi in dejanske vrednosti v rezultati.csv
    file_exists = os.path.exists('data/rezultati.csv')
    with open('data/rezultati.csv', 'a', newline='') as f:
        fieldnames = [
            'graf',
            'final_pred_alpha_eq_alpha_od', 'actual_alpha_eq_alpha_od', 'method_alpha_eq_alpha_od',
            'final_pred_alpha_G2_eq_alpha_od', 'actual_alpha_G2_eq_alpha_od', 'method_alpha_G2_eq_alpha_od'
        ]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        
        if not file_exists:
            writer.writeheader()
        
        writer.writerow({
            'graf': graf_id,
            'final_pred_alpha_eq_alpha_od': final_pred_alpha_eq_alpha_od,
            'actual_alpha_eq_alpha_od': actual_alpha_equals_alpha_od,
            'method_alpha_eq_alpha_od': method_alpha_eq_alpha_od,
            'final_pred_alpha_G2_eq_alpha_od': final_pred_alpha_G2_eq_alpha_od,
            'actual_alpha_G2_eq_alpha_od': actual_alpha_G2_equals_alpha_od,
            'method_alpha_G2_eq_alpha_od': method_alpha_G2_eq_alpha_od
        })
    
    print(f"✓ Rezultati shranjeni za {graf_id}")
    print(f"  Napoved α(G)=α_od(G): {predicted_alpha_equals_alpha_od}, Dejanska vrednost: {actual_alpha_equals_alpha_od}")
    print(f"  Napoved α(G²)=α_od(G): {predicted_alpha_G2_equals_alpha_od}, Dejanska vrednost: {actual_alpha_G2_equals_alpha_od}")
