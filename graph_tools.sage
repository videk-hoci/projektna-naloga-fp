from sage.all import *
from itertools import combinations
import csv
import os


#########################################################    alpha_od   ###################################################################

def alpha_od(G):
    """
    Vrne α_od(G) - velikost največje lihe neodvisne množice.
    Deluje brute-force. Primerno za manjše grafi.
    """
    V = G.vertices()
    n = len(V)
    max_size = 0
    
    # Optimizacija: najprej preveri, ali je prazna množica veljavna
    valid_empty = all(G.degree(v) == 0 for v in V) or n == 0
    if valid_empty:
        max_size = 0
    
    # preverimo vse podmnožice V
    for r in range(1, n+1):  # Začni z 1, ne 0 (prazna množica že preverjena)
        for subset in combinations(V, r):
            T = set(subset)
            
            # Optimizacija: uporabi Graph metodo za preverjanje neodvisnosti
            subgraph = G.subgraph(T)
            if subgraph.size() > 0:  # Če ima povezave, ni neodvisna
                continue
            
            # Preveri pogoj za vozlišča izven T
            valid = True
            for v in V:
                if v not in T:
                    # Optimizacija: uporabi generator namesto set operacije
                    count = sum(1 for u in G.neighbors(v) if u in T)
                    # mora biti 0 ali liho
                    if count != 0 and count % 2 == 0:
                        valid = False
                        break
            
            if valid:
                max_size = max(max_size, len(T))
    
    return max_size

def alpha_od_ilp(G):
    """
    Vrne α_od(G) - velikost največje lihe neodvisne množice.
    Uporablja Integer Linear Programming (ILP) za hitrejše računanje.
    
    Strategija:
    1. ILP najde kandidate za neodvisne množice različnih velikosti
    2. Python funkcija validira odd-independent pogoj
    3. Vrne največjo veljavno množico
    
    Primerno za grafe do ~30 vozlišč (hitrejše od brute-force).
    
    Args:
        G: Graf
    
    Returns:
        Velikost največje lihe neodvisne množice
    """
    from sage.numerical.mip import MixedIntegerLinearProgram
    
    V = list(G.vertices())
    n = len(V)
    
    if n == 0:
        return 0
    
    # Najprej najdi maksimalno velikost neodvisne množice
    max_independent_size = G.independent_set(value_only=True)
    
    # Preverjaj velikosti od največje navzdol
    for target_size in range(max_independent_size, 0, -1):
        # Poskusi najti neodvisno množico velikosti target_size
        p = MixedIntegerLinearProgram(maximization=False, solver="GLPK")
        x = p.new_variable(binary=True)
        
        # Omejitev 1: točno target_size vozlišč v množici
        p.add_constraint(sum(x[v] for v in V) == target_size)
        
        # Omejitev 2: mora biti neodvisna množica
        for u, v in G.edges(labels=False):
            p.add_constraint(x[u] + x[v] <= 1)
        
        # Poskusi rešiti
        try:
            p.solve()
            solution = p.get_values(x)
            T = set(v for v in V if solution[v] > 0.5)
            
            # Validacija: preveri odd-independent pogoj
            if is_odd_independent_set(G, T):
                return len(T)
        except:
            # Če ILP ne najde rešitve, nadaljuj z manjšo velikostjo
            continue
    
    return 0

def is_odd_independent_set(G, T):
    """
    Preveri, ali je T liha neodvisna množica.
    
    Args:
        G: Graf
        T: Množica vozlišč (kandidat)
    
    Returns:
        True če je T odd-independent, False sicer
    """
    T_set = set(T)
    
    # Preveri neodvisnost
    for v in T_set:
        for u in G.neighbor_iterator(v):
            if u in T_set:
                return False
    
    # Preveri odd pogoj: za vsako vozlišče izven T
    # mora biti število sosedov v T enako 0 ali liho
    for v in G.vertices():
        if v not in T_set:
            count = sum(1 for u in G.neighbor_iterator(v) if u in T_set)
            if count != 0 and count % 2 == 0:
                return False
    
    return True


########################################################    Generiranje grafov   ###########################################################

def generate_graph_family(graph_function, prefix, family_name, n_start, n_end):
    """
    Generira družino grafov z dano funkcijo.
    
    Args:
        graph_function: Sage funkcija za generiranje grafa (npr. graphs.CompleteGraph)
        prefix: Predpona za ime grafa (npr. "K" za polne grafe)
        family_name: Ime družine grafov (npr. "polni", "poti", "cikli")
        n_start: Začetno število vozlišč
        n_end: Končno število vozlišč (vključno)
    
    Returns:
        Seznam tuplov (graf, ime, družina)
    
    Primer:
        generate_graph_family(graphs.CompleteGraph, "K", "polni", 3, 5)
        vrne: [(K3_graf, "K3", "polni"), (K4_graf, "K4", "polni"), (K5_graf, "K5", "polni")]
    """
    result = []
    for n in range(n_start, n_end + 1):
        G = graph_function(n)
        ime = f"{prefix}{n}"
        result.append((G, ime, family_name))
    return result

def graph_power(G, k):
    """
    Vrne k-to potenco grafa G.
    V k-ti potenci grafa sta dve vozliški povezani, če sta v G na razdalji največ k.
    """
    from sage.graphs.distances_all_pairs import distances_all_pairs
    
    # Optimizacija: uporabi prazen Graph, nato dodaj vertices
    vertices = G.vertices()
    Gk = Graph()
    Gk.add_vertices(vertices)
    
    # Izračunaj vse razdalje
    dist = distances_all_pairs(G)
    
    # Optimizacija: dodaj vse povezave naenkrat
    edges_to_add = []
    for i, u in enumerate(vertices):
        for v in vertices[i+1:]:  # Izogni se podvajanju in u == v
            if dist[u][v] <= k:
                edges_to_add.append((u, v))
    
    Gk.add_edges(edges_to_add)
    return Gk

def generate_kneser_family(n_start, n_end, k_values):
    """
    Generira družino Kneserjevih grafov KG(n,k) za različne vrednosti k.
    
    Kneserjev graf KG(n,k) ima vozlišča, ki so k-elementne podmnožice množice {1,2,...,n}.
    Dve vozliči sta povezani, če sta ustrezni podmnožici disjunktni.
    
    Args:
        n_start: Začetna vrednost n
        n_end: Končna vrednost n (vključno)
        k_values: Seznam ali ena vrednost k (velikost podmnožic)
                  Če je int, se uporabi ta vrednost
                  Če je list, se generirajo grafi za vse k vrednosti
    
    Returns:
        Seznam tuplov (graf, ime, družina)
    
    Primeri:
        generate_kneser_family(5, 7, 2)  # KG(5,2), KG(6,2), KG(7,2)
        generate_kneser_family(5, 7, [2, 3])  # KG(5,2), KG(5,3), KG(6,2), KG(6,3), ...
    """
    result = []
    
    # Če je k_values ena vrednost, jo pretvori v seznam
    if isinstance(k_values, int):
        k_values = [k_values]
    
    for n in range(n_start, n_end + 1):
        for k in k_values:
            if n >= 2*k:  # Kneserjev graf obstaja samo če n >= 2k
                G = graphs.KneserGraph(n, k)
                # Optimizacija: relabel direktno z range
                G_relabeled = G.relabel(range(G.order()), inplace=False)
                ime = f"KG({n},{k})"
                result.append((G_relabeled, ime, "kneser"))
    
    return result

def generate_cartesian_product_complete_graphs(k_values, n_start, n_end):
    """
    Generira družino Kartezičnih produktov polnih grafov K_n □ K_k.
    
    Args:
        k_values: Seznam ali ena vrednost k za K_k
        n_start: Začetna vrednost n
        n_end: Končna vrednost n (vključno)
    
    Returns:
        Seznam tuplov (graf, ime, družina)
    
    Primeri:
        generate_cartesian_product_complete_graphs(2, 3, 5)
        # K3□K2, K4□K2, K5□K2
        
        generate_cartesian_product_complete_graphs([2, 3], 3, 4)
        # K3□K2, K3□K3, K4□K2, K4□K3
    
    Opomba: Da se izognemo podvajanju (K2□K3 = K3□K2), generiramo samo n >= k.
    """
    result = []
    
    # Če je k_values ena vrednost, jo pretvori v seznam
    if isinstance(k_values, int):
        k_values = [k_values]
    
    for n in range(n_start, n_end + 1):
        for k in k_values:
            # Izognemo se podvajanju: generiraj samo če n >= k
            if n < k:
                continue
            
            # Ustvari Kartezični produkt K_n □ K_k
            G1 = graphs.CompleteGraph(n)
            G2 = graphs.CompleteGraph(k)
            G = G1.cartesian_product(G2)
            
            # Relabel vozlišča na števila za enostavnejši zapis v CSV
            G_relabeled = G.relabel(range(G.order()), inplace=False)
            
            # Uporabi notacijo kjer je večje število prvo (konvencija)
            ime = f"K{n}[]K{k}"
            result.append((G_relabeled, ime, "kartezicni_produkt_polnih"))
    
    return result

def generate_bipartite_odd_degree_graphs(m_values, n_values):
    """
    Generira družino neusmerjenih bipartitnih grafov z neparno stopnjo.
    
    Bipartitni graf ima vozlišča razdeljena v dve disjunktni množici.
    Vsa vozlišča imajo neparno stopnjo.
    
    Args:
        m_values: Seznam ali ena vrednost m za prvo množico vozlišč
        n_values: Seznam ali ena vrednost n za drugo množico vozlišč
    
    Returns:
        Seznam tuplov (graf, ime, družina)
    
    Primeri:
        generate_bipartite_odd_degree_graphs(2, 3)
        # Generira K_{2,3} (complete bipartite)
        
        generate_bipartite_odd_degree_graphs([2, 3], [3, 5])
        # K_{2,3}, K_{2,5}, K_{3,3}, K_{3,5}
    
    Opomba: Za bipartitni graf K_{m,n} imajo vsa vozlišča neparno stopnjo
            samo če sta m IN n obe neparni števili.
    """
    result = []
    
    # Če so vrednosti ena številka, pretvori v seznam
    if isinstance(m_values, int):
        m_values = [m_values]
    if isinstance(n_values, int):
        n_values = [n_values]
    
    for m in m_values:
        for n in n_values:
            # Izognemo se podvajanju: generiraj samo če m <= n
            if m > n:
                continue
            
            # Preveri, ali imajo vsa vozlišča neparno stopnjo
            # V K_{m,n} ima vsako vozlišče v prvi množici stopnjo n,
            # in vsako vozlišče v drugi množici stopnjo m
            if m % 2 == 1 and n % 2 == 1:
                # Ustvari polni bipartitni graf K_{m,n}
                G = graphs.CompleteBipartiteGraph(m, n)
                
                # Relabel vozlišča na števila
                G_relabeled = G.relabel(range(G.order()), inplace=False)
                
                ime = f"Dvodelni_{m}_{n}"
                result.append((G_relabeled, ime, "dvodelni_neparna_stopnja"))
    
    return result

def generate_star_graphs(n_start, n_end):
    """
    Generira družino zvezda grafov S_n.
    
    Zvezda graf S_n ima en centralni vozel povezan z n zunanjimi vozlišči.
    Centralno vozlišče ima stopnjo n, zunanja vozlišča imajo stopnjo 1.
    
    Args:
        n_start: Začetno število zunanjih vozlišč
        n_end: Končno število zunanjih vozlišč (vključno)
    
    Returns:
        Seznam tuplov (graf, ime, družina)
    
    Primer:
        generate_star_graphs(3, 5)
        # S3 (3 zunanje točke), S4, S5
    
    Opomba: Zvezda graf S_n = K_{1,n}
    """
    result = []
    
    for n in range(n_start, n_end + 1):
        # Zvezda graf je K_{1,n}
        G = graphs.StarGraph(n)
        
        # Relabel vozlišča na števila
        G_relabeled = G.relabel(range(G.order()), inplace=False)
        
        ime = f"S{n}"
        result.append((G_relabeled, ime, "zvezda"))
    
    return result

def generate_wheel_graphs(n_start, n_end):
    """
    Generira družino wheel grafov W_n.
    
    Wheel graf W_n je sestavljen iz cikla C_n z dodatnim centralnim vozliščem,
    ki je povezano z vsemi vozlišči cikla.
    
    Args:
        n_start: Začetna velikost cikla (število vozlišč v zunanjem krogu)
        n_end: Končna velikost cikla (vključno)
    
    Returns:
        Seznam tuplov (graf, ime, družina)
    
    Primer:
        generate_wheel_graphs(3, 5)
        # W3 (trikotnik + center), W4 (kvadrat + center), W5 (pentagon + center)
    
    Opomba: W_n ima n+1 vozlišč (n v krogu + 1 centralno)
    """
    result = []
    
    for n in range(n_start, n_end + 1):
        # Wheel graf
        G = graphs.WheelGraph(n)
        
        # Relabel vozlišča na števila
        G_relabeled = G.relabel(range(G.order()), inplace=False)
        
        ime = f"W{n}"
        result.append((G_relabeled, ime, "kolo"))
    
    return result

def generate_all_graphs_up_to_n(n_max):
    """
    Generira vse neizomorfne grafe z do n_max vozlišči.
    
    Za vsako število vozlišč generira vse možne grafe (do izomorfizma).
    Grafi so poimenovani kot {n}_{m}_{k}, kjer je:
    - n: število vozlišč
    - m: število povezav
    - k: zaporedna številka grafa z isto strukturo
    
    Args:
        n_max: Maksimalno število vozlišč
    
    Returns:
        Seznam tuplov (graf, ime, družina)
    
    Primer:
        generate_all_graphs_up_to_n(4)
        # Generira vse grafe z 1, 2, 3, 4 vozlišči
        # Imena: 3_0_1, 3_1_1, 3_2_1, 3_3_1, 4_0_1, 4_1_1, ...
    
    Opomba: Število grafov raste ZELO hitro:
            n=1: 1 graf
            n=2: 2 grafa
            n=3: 4 grafe
            n=4: 11 grafov
            n=5: 34 grafov
            n=6: 156 grafov
            n=7: 1044 grafov (!!)
    """
    result = []
    
    for n in range(1, n_max + 1):
        # Generiraj vse neizomorfne grafe z n vozliščimi
        all_graphs_n = list(graphs.nauty_geng(f"{n}"))
        
        # Razvrsti grafe po številu povezav
        graphs_by_edges = {}
        for G in all_graphs_n:
            m = G.size()  # število povezav
            if m not in graphs_by_edges:
                graphs_by_edges[m] = []
            graphs_by_edges[m].append(G)
        
        # Dodaj grafe z zaporednimi številkami
        for m in sorted(graphs_by_edges.keys()):
            for idx, G in enumerate(graphs_by_edges[m], start=1):
                # Relabel vozlišča na števila
                G_relabeled = G.relabel(range(G.order()), inplace=False)
                
                ime = f"{n}_{m}_{idx}"
                result.append((G_relabeled, ime, ""))
    
    return result

def generate_all_graphs_with_n_vertices(n):
    """
    Generira vse neizomorfne grafe z natanko n vozlišči.
    
    Args:
        n: Število vozlišč
    
    Returns:
        Seznam tuplov (graf, ime, družina)
    
    Primer:
        generate_all_graphs_with_n_vertices(5)
        # Generira vseh 34 grafov s 5 vozlišči
    """
    result = []
    
    # Generiraj vse neizomorfne grafe z n vozliščmi
    all_graphs_n = list(graphs.nauty_geng(f"{n}"))
    
    # Razvrsti grafe po številu povezav
    graphs_by_edges = {}
    for G in all_graphs_n:
        m = G.size()  # število povezav
        if m not in graphs_by_edges:
            graphs_by_edges[m] = []
        graphs_by_edges[m].append(G)
    
    # Dodaj grafe z zaporednimi številkami
    for m in sorted(graphs_by_edges.keys()):
        for idx, G in enumerate(graphs_by_edges[m], start=1):
            # Relabel vozlišča na števila
            G_relabeled = G.relabel(range(G.order()), inplace=False)
            
            ime = f"{n}_{m}_{idx}"
            result.append((G_relabeled, ime, f"vsi_grafi_{n}v"))
    
    return result


##########################################################    lastnosti grafov   ###########################################################

def get_diameter(G):
    if G.order() == 0:
        return 0
    
    # Graf z enim vozliščem
    elif G.order() == 1:
        return 0
    
    # Povezan graf
    if G.is_connected():
        return G.diameter()
    else:
        return float('inf')

def get_min_degree(G):
    if G.order() == 0:
        return 0
    
    degrees = G.degree()
    return min(degrees)

def get_max_degree(G):
    if G.order() == 0:
        return 0
    
    degrees = G.degree()
    return max(degrees)


def all_degrees_odd(G):
    """
    Preveri, ali imajo vsa vozlišča v grafu G neparno stopnjo.
    
    Args:
        G: Graf
    
    Returns:
        bool: True če imajo vsa vozlišča neparno stopnjo, False sicer
    
    Primer:
        G = graphs.CompleteBipartiteGraph(3, 3)
        all_degrees_odd(G)  # Vrne True (vsa vozlišča imajo stopnjo 3)
        
        G = graphs.CycleGraph(4)
        all_degrees_odd(G)  # Vrne False (vsa vozlišča imajo stopnjo 2)
    """
    if G.order() == 0:
        return True  # Prazen graf - vsa (nobena) vozlišča imajo neparno stopnjo
    
    degrees = G.degree()
    return all(d % 2 == 1 for d in degrees)

def get_girth(G):
    """
    Vrne obseg (girth) grafa G - dolžino najkrajšega cikla.
    
    Če graf nima ciklov, vrne float('inf').
    
    Args:
        G: Graf
    
    Returns:
        int ali float('inf'): Obseg grafa
    
    Primer:
        G = graphs.CycleGraph(5)
        get_girth(G)  # Vrne 5
        
        G = graphs.CompleteGraph(4)
        get_girth(G)  # Vrne 3 (trikotnik)
        
        G = graphs.PathGraph(5)
        get_girth(G)  # Vrne inf (drevo, brez ciklov)
    """
    if G.order() <= 2:
        return float('inf')  # Manjši grafi nimajo ciklov
    
    if G.size() == 0:
        return float('inf')  # Graf brez povezav nima ciklov
    
    try:
        girth = G.girth()
        return girth
    except:
        return float('inf')  # Graf nima ciklov


def get_radius(G):
    """
    Vrne radij grafa G - najmanjšo ekscentričnost med vsemi vozlišči.
    
    Ekscentričnost vozlišča je največja razdalja od tega vozlišča do kateregakoli drugega.
    Za nepovezane grafe vrne float('inf').
    Za prazen graf vrne 0.
    
    Args:
        G: Graf
    
    Returns:
        int ali float('inf'): Radij grafa
    
    Primer:
        G = graphs.PathGraph(5)  # 1-2-3-4-5
        get_radius(G)  # Vrne 2 (centralno vozlišče 3)
        
        G = graphs.CycleGraph(6)
        get_radius(G)  # Vrne 3
        
        G = graphs.StarGraph(5)  # Centralno vozlišče + 5 zunanjih
        get_radius(G)  # Vrne 1 (ekscentričnost centralnega vozlišča)
        
        G = Graph(5)  # Nepovezan graf
        get_radius(G)  # Vrne inf
    """
    # Prazen graf
    if G.order() == 0:
        return 0
    
    # Graf z enim vozliščem
    if G.order() == 1:
        return 0
    
    # Povezan graf
    if G.is_connected():
        return G.radius()
    else:
        return float('inf')

def get_chromatic_number(G):
    """
    Vrne kromatično število grafa G.
    
    Kromatično število je najmanjše število barv, potrebnih za pobarvanje vozlišč grafa,
    tako da nobeni dve sosednji vozliščima nimata iste barve.
    
    OPOMBA: Izračun kromatičnega števila je NP-težek problem. Za večje grafe (n > 20)
    lahko ta funkcija traja dolgo.
    
    Args:
        G: Graf
    
    Returns:
        int: Kromatično število grafa
    
    Primer:
        G = graphs.CompleteGraph(5)
        get_chromatic_number(G)  # Vrne 5 (vsako vozlišče potrebuje svojo barvo)
        
        G = graphs.CycleGraph(5)
        get_chromatic_number(G)  # Vrne 3 (lihi cikli potrebujejo 3 barve)
        
        G = graphs.CycleGraph(6)
        get_chromatic_number(G)  # Vrne 2 (sodi cikli so dvodelni)
        
        G = graphs.PathGraph(10)
        get_chromatic_number(G)  # Vrne 2 (poti so dvodelne)
        
        G = Graph(5)  # Prazen graf (brez povezav)
        get_chromatic_number(G)  # Vrne 1
    
    Lastnosti:
    - χ(G) = 1 natanko tedaj, ko je G brez povezav
    - χ(G) = 2 natanko tedaj, ko je G neprazen in dvodelen
    - χ(Kn) = n za poln graf
    - χ(G) ≤ Δ(G) + 1, kjer je Δ(G) maksimalna stopnja (Brooksova teorema)
    """
    if G.order() == 0:
        return 0
    
    return G.chromatic_number()


def get_density(G):
    """
    Vrne gostoto grafa G.
    
    Gostota grafa je razmerje med številom povezav in maksimalnim možnim številom povezav.
    Za neusmerjene grafe: density = 2m / (n(n-1)), kjer je m število povezav in n število vozlišč.
    
    Args:
        G: Graf
    
    Returns:
        float: Gostota grafa (vrednost med 0 in 1)
    
    Primer:
        G = graphs.CompleteGraph(5)
        get_density(G)  # Vrne 1.0 (maksimalno gost graf)
        
        G = graphs.CycleGraph(5)
        get_density(G)  # Vrne 0.5 (5 povezav od možnih 10)
        
        G = graphs.PathGraph(5)
        get_density(G)  # Vrne 0.4 (4 povezave od možnih 10)
        
        G = Graph(5)  # Prazen graf
        get_density(G)  # Vrne 0.0
        
        G = graphs.StarGraph(4)
        get_density(G)  # Vrne 0.4 (4 povezave od možnih 10)
    
    Lastnosti:
    - 0 ≤ density ≤ 1
    - density = 0 za graf brez povezav
    - density = 1 za poln graf
    - Za redke grafe: density → 0 ko n → ∞
    - Za goste grafe: density → 1 ko n → ∞
    """
    n = G.order()
    
    if n <= 1:
        return 0.0
    
    m = G.size()
    max_edges = n * (n - 1) / 2
    
    return float(m) / float(max_edges)
####################################################  Verjetnostna določnost grafov   ######################################################

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
