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
    
    # preverimo vse podmnožice V
    for r in range(n+1):
        for subset in combinations(V, r):
            T = set(subset)
            valid = True
            
            # Preveri, ali je T neodvisna množica
            for v in T:
                if any(u in T for u in G.neighbors(v)):
                    valid = False
                    break
            
            if not valid:
                continue
            
            # Preveri pogoj za vozlišča izven T
            for v in V:
                if v not in T:
                    # število sosedov v T
                    count = len(set(G.neighbors(v)) & T)
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
    V k-ti potenci grafa sta dve vozlišči povezani, če sta v G na razdalji največ k.
    
    Args:
        G: Graf
        k: Potenca (npr. k=2 za kvadrat)
    
    Returns:
        Graf G^k
    """
    from sage.graphs.distances_all_pairs import distances_all_pairs
    
    Gk = Graph()
    Gk.add_vertices(G.vertices())
    
    # Izračunaj vse razdalje
    dist = distances_all_pairs(G)
    
    # Dodaj povezave med vozlišči, ki so na razdalji <= k
    for u in G.vertices():
        for v in G.vertices():
            if u < v and dist[u][v] <= k:
                Gk.add_edge(u, v)
    
    return Gk