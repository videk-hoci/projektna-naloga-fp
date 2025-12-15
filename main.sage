from sage.all import *
import csv
import sys
import ast  # Varnejša alternativa za eval

# Increase CSV field size limit
csv.field_size_limit(sys.maxsize)

load("graph_tools.sage")
load("prediction_model.sage")

# Funkcija za pretvorbo grafa v string povezav
def graph_to_edge_string(G):
    """Pretvori graf v string povezav v formatu '[(0,1),(1,2),...]'"""
    edges = [(min(u,v), max(u,v)) for u,v in G.edges(labels=False)]
    edges.sort()
    return str(edges)

def graph_to_vertices_string(G):
    """Pretvori vozlišča grafa v string"""
    vertices = list(G.vertices())
    vertices.sort()
    return str(vertices)


# Funkcija za shranjevanje grafov v CSV
def save_graphs_to_csv(graphs, filename='data/grafi_oblika.csv'):
    """Shrani grafe v CSV format z headerjem 'graf,vozlisca,povezave'"""
    # Preberi obstoječe grafe
    existing_graphs = {}
    try:
        with open(filename, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                # Ključ: (vozlišča, povezave)
                key = (row.get('vozlisca', '[]'), row['povezave'])
                existing_graphs[key] = row['graf']
    except FileNotFoundError:
        pass
    
    # Optimizacija: zberi nove grafe najprej, potem zapiši vse naenkrat
    new_graphs = []
    for G_data in graphs:
        if isinstance(G_data, tuple):
            G, ime, druzina = G_data
        else:
            G, ime, druzina = G_data, f"G{len(existing_graphs)}", "neznan"
        
        vertices_string = graph_to_vertices_string(G)
        edge_string = graph_to_edge_string(G)
        key = (vertices_string, edge_string)
        
        if key not in existing_graphs:
            new_graphs.append((ime, vertices_string, edge_string))
            existing_graphs[key] = ime
    
    # Zapiši vse naenkrat
    with open(filename, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['graf', 'vozlisca', 'povezave'])
        
        # Najprej obstoječi, potem novi
        for (vertices_string, edge_string), graf_ime in existing_graphs.items():
            writer.writerow([graf_ime, vertices_string, edge_string])
    
    return existing_graphs

def has_missing_properties(row, ignore_fields=['druzina']):
    """
    Preveri, ali ima vrstica kakšne manjkajoče lastnosti (prazne ali None).
    
    Args:
        row: Dictionary vrstice iz CSV
        ignore_fields: Seznam polj, ki jih ignoriramo pri preverjanju
    
    Returns:
        bool: True če ima manjkajoče lastnosti, False sicer
    """
    for key, value in row.items():
        if key in ignore_fields or key == 'graf':
            continue
        if value in ('', None):
            return True
    return False

# Funkcija za preverjanje lastnosti in shranjevanje
def analyze_and_save_graphs(graphs, properties_file='data/grafi.csv', graphs_file='data/grafi_oblika.csv'):
    """Preveri lastnosti grafov in shrani rezultate v CSV datoteke"""
    
    # Shrani grafe in pridobi mapping ((vozlišča, povezave) -> ime)
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
                all_graphs[row['graf']] = {
                    'vozlisca': row.get('vozlisca', '[]'),
                    'povezave': row['povezave']
                }
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
    
    # Identificiraj grafe, ki potrebujejo obdelavo:
    # 1. Novi grafi (še niso v grafi.csv)
    # 2. Grafi z manjkajočimi lastnostmi (prazna polja, razen 'druzina')
    graphs_to_process = []
    
    for graf_ime in all_graphs.keys():
        if graf_ime not in existing_properties:
            # Nov graf
            graphs_to_process.append(graf_ime)
        elif has_missing_properties(existing_properties[graf_ime]):
            # Obstoječ graf z manjkajočimi lastnostmi
            graphs_to_process.append(graf_ime)
    
    total_to_process = len(graphs_to_process)
    
    if total_to_process == 0:
        print("Ni grafov za obdelavo! Vsi grafi imajo že vse lastnosti.")
        return
    
    print(f"Obdelujem {total_to_process} grafov (novi + manjkajoče lastnosti)...")
    processed = 0
    
    # Obdelaj samo grafe, ki potrebujejo obdelavo
    for i, graf_ime in enumerate(graphs_to_process):
        processed += 1
        if processed % 10 == 0:
            percentage = float(100 * processed) / float(total_to_process)
            print(f"Obdelanih {processed}/{total_to_process} grafov ({percentage:.1f}%)")
        
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
            # Rekonstruiraj graf iz vozlišč in povezav
            graf_data = all_graphs[graf_ime]
            vertices = ast.literal_eval(graf_data['vozlisca'])
            edges = ast.literal_eval(graf_data['povezave'])
            
            # Ustvari graf z eksplicitnimi vozlišči
            G = Graph()
            G.add_vertices(vertices)
            G.add_edges(edges)
        
        # Izračunaj lastnosti - preveri prazne in None vrednosti
        if 'alpha' not in results_dict[graf_ime] or results_dict[graf_ime].get('alpha') in ('', None):
            results_dict[graf_ime]['alpha'] = G.independent_set(value_only=True)
        
        if 'alpha_od' not in results_dict[graf_ime] or results_dict[graf_ime].get('alpha_od') in ('', None):
            results_dict[graf_ime]['alpha_od'] = alpha_od_ilp_correct(G)
        
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

        if "regularen" not in results_dict[graf_ime] or results_dict[graf_ime].get("regularen") in ('', None):
            results_dict[graf_ime]["regularen"] = G.is_regular()
        
        if "tricikli" not in results_dict[graf_ime] or results_dict[graf_ime].get("tricikli") in ('', None):
            results_dict[graf_ime]["tricikli"] = count_triangles(G)
        
        if "stiricikli" not in results_dict[graf_ime] or results_dict[graf_ime].get("stiricikli") in ('', None):
            results_dict[graf_ime]["stiricikli"] = count_4cycles(G)

        fieldnames_set.update(results_dict[graf_ime].keys())
    
        # Shrani vsakih 50 grafov
        if i % 50 == 0 and i > 0:
            print(f"Shranjujem vmesne rezultate pri {i} grafih...")
            results = list(results_dict.values())
            fieldnames = sorted(fieldnames_set)
            priority_fields = ['graf', 'druzina']
            fieldnames = priority_fields + [f for f in fieldnames if f not in priority_fields]
            
            with open(properties_file, 'w', newline='') as f:
                writer = csv.DictWriter(f, fieldnames=fieldnames)
                writer.writeheader()
                writer.writerows(results)
    
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
    
    print(f"✓ Končano! Obdelanih {total_to_process} grafov.")


# Primer uporabe:
# Splošna oblika:
# povezave = [(0,1),(1,2),...]
# graphs = [(povezave, "Graph_Name", "family_name"), ]

# Generate random graphs
graphs = generate_random_connected_graphs(30, 5, 0.8)

# Process each graph individually with predict_alfas
print(f"Processing {len(graphs)} graphs...")
for i, G_data in enumerate(graphs):
    print(f"\n{'='*60}")
    print(f"Processing graph {i+1}/{len(graphs)}")
    print(f"{'='*60}")
    
    # Extract graph from tuple (G, name, family)
    if isinstance(G_data, tuple):
        G = G_data[0]  # First element is the graph
    else:
        G = G_data  # In case it's already just a graph
    
    predict_alfas(G)

# Alternative: use the batch processing function
# analyze_and_save_graphs(graphs)