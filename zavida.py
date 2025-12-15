import pickle
import math
import pandas as pd
from Orange.data import Table, Domain, ContinuousVariable, DiscreteVariable

# ======================
# CONFIG
# ======================

MODEL_PATH = "model.pkcls"
INPUT_CSV = "input.csv"
OUTPUT_CSV = "output_predictions.csv"

# ======================
# VARIABLE DEFINITIONS
# (MUST MATCH TRAINING)
# ======================

variables_order = [
    ("timefromlastgraduatedtoken", "continuous"),
    ("totalHolders", "continuous"),
    ("top2HoldersPercentages", "continuous"),
    ("top5HoldersPercentages", "continuous"),
    ("top10HoldersPercentages", "continuous"),
    ("top20HoldersPercentages", "continuous"),
    ("top40HoldersPercentages", "continuous"),
    ("solanaPrice", "continuous"),
    ("dailyTokenCount", "continuous"),
    ("dailyGraduatedTokenCount", "continuous"),
    ("totalSolVolume", "continuous"),
    ("totalTransactions", "continuous"),
    ("newUsers", "continuous"),
    ("reccuringUsers", "continuous"),
    ("timeToGraduation", "continuous"),
    ("hasWebsite", "discrete", ["true", "false"]),
    ("hasTelegram", "discrete", ["true", "false"]),
    ("hasTwitter", "discrete", ["true", "false"]),
    ("hasDescription", "discrete", ["true", "false"]),
    ("diff_1h", "continuous"),
    ("diff_12h", "continuous"),
    ("diff_24h", "continuous"),
    ("diff_1w", "continuous"),
]

# Class variable (used only by model internally)
class_var = DiscreteVariable("sucessffull", values=["no", "yes"])

# ======================
# BUILD ORANGE DOMAIN
# ======================

orange_vars = []
for v in variables_order:
    if v[1] == "continuous":
        orange_vars.append(ContinuousVariable(v[0]))
    else:
        orange_vars.append(DiscreteVariable(v[0], v[2]))

# Domain WITHOUT class (inference)
domain = Domain(orange_vars)

# ======================
# LOAD MODEL
# ======================

with open(MODEL_PATH, "rb") as f:
    model = pickle.load(f)

print("✅ Model loaded")

# ======================
# LOAD CSV
# ======================

df = pd.read_csv(INPUT_CSV)

# Ensure correct column order
df = df[[v[0] for v in variables_order]]

# ======================
# SANITIZE DATA
# ======================

rows = []

for _, row in df.iterrows():
    values = []
    for var in variables_order:
        name = var[0]

        if var[1] == "continuous":
            val = row[name]
            try:
                val = float(val)
                if math.isnan(val) or math.isinf(val):
                    val = 0.0
            except:
                val = 0.0
            values.append(val)

        else:  # discrete
            allowed = var[2]
            val = str(row[name]).strip().lower()
            if val not in [v.lower() for v in allowed]:
                values.append(allowed[0])
            else:
                for a in allowed:
                    if a.lower() == val:
                        values.append(a)
                        break

    rows.append(values)

# ======================
# CREATE ORANGE TABLE
# ======================

data = Table.from_list(domain, rows)

# ======================
# PREDICT
# ======================

predictions = model(data)

# ======================
# EXTRACT PROBABILITIES
# ======================

predicted_class = []
success_probability = []

for p in predictions:
    if hasattr(p, "probabilities"):
        # Index 1 = "yes"
        success_probability.append(float(p.probabilities[1]))
        predicted_class.append(p.predicted)
    else:
        success_probability.append(float(p))
        predicted_class.append(None)

# ======================
# OUTPUT CSV
# ======================

df_out = df.copy()
df_out["prediction_probability_yes"] = success_probability
df_out["prediction_class"] = predicted_class

df_out.to_csv(OUTPUT_CSV, index=False)

print(f"✅ Predictions written to {OUTPUT_CSV}")
