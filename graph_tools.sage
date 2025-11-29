from sage.all import *
from itertools import combinations

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
