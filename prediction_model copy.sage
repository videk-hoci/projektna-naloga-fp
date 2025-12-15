import csv
import os
from sage.all import *

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
        # Poskusi najti a, b tako da n = a*b in stopnja = (a-1) + (b-1)
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
