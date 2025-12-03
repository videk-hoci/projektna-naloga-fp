from sage.all import *
import csv
import ast  # Varnejša alternativa za eval
load("graph_tools.sage")

# Funkcija za pretvorbo grafa v string povezav
def graph_to_edge_string(G):
    """Pretvori graf v string povezav v formatu '[(0,1),(1,2),...]'"""
    edges = [(min(u,v), max(u,v)) for u,v in G.edges(labels=False)]
    edges.sort()
    return str(edges)


# Funkcija za shranjevanje grafov v CSV
def save_graphs_to_csv(graphs, filename='data/grafi_oblika.csv'):
    """Shrani grafe v CSV format z headerjem 'graf,povezave'"""
    # Preberi obstoječe grafe
    existing_graphs = {}
    try:
        with open(filename, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                existing_graphs[row['povezave']] = row['graf']
    except FileNotFoundError:
        pass
    
    # Optimizacija: zberi nove grafe najprej, potem zapiši vse naenkrat
    new_graphs = []
    for G_data in graphs:
        if isinstance(G_data, tuple):
            G, ime, druzina = G_data
        else:
            G, ime, druzina = G_data, f"G{len(existing_graphs)}", "neznan"
        
        edge_string = graph_to_edge_string(G)
        if edge_string not in existing_graphs:
            new_graphs.append((ime, edge_string))
            existing_graphs[edge_string] = ime
    
    # Zapiši vse naenkrat
    with open(filename, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['graf', 'povezave'])
        
        # Najprej obstoječi, potem novi
        for edge_string, graf_ime in existing_graphs.items():
            writer.writerow([graf_ime, edge_string])
    
    return existing_graphs

# Funkcija za preverjanje lastnosti in shranjevanje
def analyze_and_save_graphs(graphs, properties_file='data/grafi.csv', graphs_file='data/grafi_oblika.csv'):
    """Preveri lastnosti grafov in shrani rezultate v CSV datoteke"""
    
    # Shrani grafe in pridobi mapping (povezave -> ime)
    graph_mapping = save_graphs_to_csv(graphs, graphs_file)
    
    # Preberi obstoječe lastnosti
    existing_properties = {}
    fieldnames_set = set(['graf', 'druzina'])
    try:
        with open(properties_file, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                existing_properties[row['graf']] = row
                fieldnames_set.update(row.keys())
    except FileNotFoundError:
        pass
    
    # Preberi VSE grafe iz grafi_oblika.csv
    all_graphs = {}
    try:
        with open(graphs_file, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                all_graphs[row['graf']] = row['povezave']
    except FileNotFoundError:
        pass
    
    # Pripravi podatke za grafi.csv
    results_dict = {}
    
    # Najprej dodaj vse obstoječe lastnosti
    for graf_ime, props in existing_properties.items():
        results_dict[graf_ime] = props.copy()
    
    # Ustvari slovar grafov za hitrejši dostop
    graphs_dict = {}
    for G_data in graphs:
        if isinstance(G_data, tuple):
            G, ime, druzina = G_data
        else:
            G, ime, druzina = G_data, "", "neznan"
        graphs_dict[ime] = (G, druzina)
    
    # Obdelaj VSE grafe iz grafi_oblika.csv
    for graf_ime, edge_string in all_graphs.items():
        # Če graf še ni v results_dict, dodaj osnovne podatke
        if graf_ime not in results_dict:
            results_dict[graf_ime] = {'graf': graf_ime, 'druzina': ''}
        
        # Pridobi graf objekt
        G = None
        druzina = None
        if graf_ime in graphs_dict:
            G, druzina = graphs_dict[graf_ime]
            # Posodobi družino SAMO če je podana in obstoječa je prazna
            if druzina and druzina != "neznan":
                if not results_dict[graf_ime].get('druzina') or results_dict[graf_ime]['druzina'] == "neznan":
                    results_dict[graf_ime]['druzina'] = druzina
        else:
            # Rekonstruiraj graf iz edge_string - uporabi ast.literal_eval za varnost
            edges = ast.literal_eval(edge_string)
            G = Graph(edges)
        
        # Izračunaj lastnosti - optimizacija: preveri prazne in None vrednosti
        if 'alpha' not in results_dict[graf_ime] or results_dict[graf_ime].get('alpha') in ('', None):
            results_dict[graf_ime]['alpha'] = G.independent_set(value_only=True)
        
        if 'alpha_od' not in results_dict[graf_ime] or results_dict[graf_ime].get('alpha_od') in ('', None):
            results_dict[graf_ime]['alpha_od'] = alpha_od(G)
        
        if 'alpha^2' not in results_dict[graf_ime] or results_dict[graf_ime].get('alpha^2') in ('', None):
            results_dict[graf_ime]['alpha^2'] = graph_power(G, 2).independent_set(value_only=True)

        if "premer" not in results_dict[graf_ime] or results_dict[graf_ime].get("premer") in ('', None):
            results_dict[graf_ime]["premer"] = get_diameter(G)

        if "max_stopnja" not in results_dict[graf_ime] or results_dict[graf_ime].get("max_stopnja") in ('', None):
            results_dict[graf_ime]["max_stopnja"] = get_max_degree(G)

        if "min_stopnja" not in results_dict[graf_ime] or results_dict[graf_ime].get("min_stopnja") in ('', None):
            results_dict[graf_ime]["min_stopnja"] = get_min_degree(G)
        
        if "vse_neparne" not in results_dict[graf_ime] or results_dict[graf_ime].get("vse_neparne") in ('', None):
            results_dict[graf_ime]["vse_neparne"] = all_degrees_odd(G)

        if "obseg" not in results_dict[graf_ime] or results_dict[graf_ime].get("obseg") in ('', None):
            results_dict[graf_ime]["obseg"] = get_girth(G)
        
        if "radij" not in results_dict[graf_ime] or results_dict[graf_ime].get("radij") in ('', None):
            results_dict[graf_ime]["radij"] = get_radius(G)

        if "dvodelen" not in results_dict[graf_ime] or results_dict[graf_ime].get("dvodelen") in ('', None):
            results_dict[graf_ime]["dvodelen"] = G.is_bipartite()

        if "drevo" not in results_dict[graf_ime] or results_dict[graf_ime].get("drevo") in ('', None):
            results_dict[graf_ime]["drevo"] = G.is_tree()
        
        if "gozd" not in results_dict[graf_ime] or results_dict[graf_ime].get("gozd") in ('', None):
            results_dict[graf_ime]["gozd"] = G.is_forest()
        
        if "Eulerjev" not in results_dict[graf_ime] or results_dict[graf_ime].get("Eulerjev") in ('', None):
            results_dict[graf_ime]["Eulerjev"] = G.is_eulerian()
        
        if "kromaticno_stevilo" not in results_dict[graf_ime] or results_dict[graf_ime].get("kromaticno_stevilo") in ('', None):
            results_dict[graf_ime]["kromaticno_stevilo"] = get_chromatic_number(G)
        
        if "gostota" not in results_dict[graf_ime] or results_dict[graf_ime].get("gostota") in ('', None):
            results_dict[graf_ime]["gostota"] = get_density(G)

        fieldnames_set.update(results_dict[graf_ime].keys())
    
    # Pretvori dictionary v seznam
    results = list(results_dict.values())
    
    # Shrani lastnosti v grafi.csv
    if results:
        fieldnames = sorted(fieldnames_set)
        # Zagotovi, da sta graf in druzina na začetku
        priority_fields = ['graf', 'druzina']
        fieldnames = priority_fields + [f for f in fieldnames if f not in priority_fields]
        
        with open(properties_file, 'w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(results)



# Primer uporabe:
# Splošna oblika:
# povezave = [(0,1),(1,2),...]
# graphs = [(povezave, "Graph_Name", "family_name"), ]

graphs = generate_all_graphs_up_to_n(7)
analyze_and_save_graphs(graphs)