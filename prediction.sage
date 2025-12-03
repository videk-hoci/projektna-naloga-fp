from sage.all import *
import csv
import os

# Import functions from graph_tools
load('graph_tools.sage')

def predict_alfas(G):
    """
    Izračuna α(G), α_od(G) in α(G²) ter shrani rezultate v CSV.
    
    Args:
        G: Graf za analizo
    
    Rezultati se shranijo v:
    - rezultati.csv: lastnosti in izračunane vrednosti
    - grafi_oblika.csv: graf in povezave (list of tuples)
    """
    
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
                    break
    
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
        
        graf_id = f"{n}v_{m}e_{iteracija}"
    
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
    
    # ===== PREDICTION - na podlagi lastnosti grafa =====
    print(f"Napovedovanje za {graf_id}...")
    
    # Hevristika 1: Ali je graf bipartiten?
    is_bipartite = G.is_bipartite()
    
    # Hevristika 2: Ali imajo vsa vozlišča neparno stopnjo?
    degrees = G.degree()
    all_odd_degrees = all(d % 2 == 1 for d in degrees)
    
    # Hevristika 3: Premer grafa (če je povezan)
    if G.is_connected():
        diameter = G.diameter()
    else:
        diameter = float('inf')
    
    # NAPOVED: α(G) = α_od(G)
    predicted_alpha_equals_alpha_od = is_bipartite or all_odd_degrees
    
    # NAPOVED: α(G²) = α_od(G)
    predicted_alpha_G2_equals_alpha_od = (diameter <= 2) if diameter != float('inf') else False
    
    print(f"  Napoved α(G) = α_od(G): {predicted_alpha_equals_alpha_od}")
    print(f"  Napoved α(G²) = α_od(G): {predicted_alpha_G2_equals_alpha_od}")
    
    # ===== DEJANSKI IZRAČUNI =====
    print(f"Računam α(G) za {graf_id}...")
    alpha_G = G.independent_set(value_only=True)
    
    print(f"Računam α_od(G) za {graf_id}...")
    alpha_od_G = alpha_od_ilp(G)
    
    print(f"Računam G²...")
    G2 = graph_power(G, 2)
    
    print(f"Računam α(G²) za {graf_id}...")
    alpha_G2 = G2.independent_set(value_only=True)
    
    # Dejanske vrednosti
    actual_alpha_equals_alpha_od = (alpha_G == alpha_od_G)
    actual_alpha_G2_equals_alpha_od = (alpha_G2 == alpha_od_G)
    
    # Shrani graf v grafi_oblika.csv (samo če še ni tam)
    if not graf_exists_in_oblika:
        file_exists = os.path.exists('data/grafi_oblika.csv')
        with open('data/grafi_oblika.csv', 'a', newline='') as f:
            fieldnames = ['graf', 'povezave']
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            
            if not file_exists:
                writer.writeheader()
            
            writer.writerow({
                'graf': graf_id,
                'povezave': edges_string
            })
    
    # Shrani rezultate v rezultati.csv
    file_exists = os.path.exists('data/rezultati.csv')
    with open('data/rezultati.csv', 'a', newline='') as f:
        fieldnames = [
            'graf',
            'predicted_alpha_eq_alpha_od', 'actual_alpha_eq_alpha_od',
            'predicted_alpha_G2_eq_alpha_od', 'actual_alpha_G2_eq_alpha_od'
        ]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        
        if not file_exists:
            writer.writeheader()
        
        writer.writerow({
            'graf': graf_id,
            'predicted_alpha_eq_alpha_od': predicted_alpha_equals_alpha_od,
            'actual_alpha_eq_alpha_od': actual_alpha_equals_alpha_od,
            'predicted_alpha_G2_eq_alpha_od': predicted_alpha_G2_equals_alpha_od,
            'actual_alpha_G2_eq_alpha_od': actual_alpha_G2_equals_alpha_od
        })
    
    print(f"✓ Rezultati shranjeni za {graf_id}")
    print(f"  Napoved α(G)=α_od(G): {predicted_alpha_equals_alpha_od}, Dejanska vrednost: {actual_alpha_equals_alpha_od}")
    print(f"  Napoved α(G²)=α_od(G): {predicted_alpha_G2_equals_alpha_od}, Dejanska vrednost: {actual_alpha_G2_equals_alpha_od}")
