from sage.all import *

def get_diameter(G):
    """
    Vrne premer grafa G.
    
    Premer je največja razdalja med katerima koli dvema vozliščema v grafu.
    Za nepovezane grafe vrne float('inf').
    Za prazen graf vrne 0.
    
    Args:
        G: Graf
    
    Returns:
        int ali float('inf'): Premer grafa
    """
    # Prazen graf
    if G.order() == 0:
        return 0
    
    # Graf z enim vozliščem
    if G.order() == 1:
        return 0
    
    # Povezan graf
    if G.is_connected():
        return G.diameter()
    else:
        return float('inf')

def get_min_degree(G):
    """
    Vrne minimalno stopnjo vozlišča v grafu G.
    
    Args:
        G: Graf
    
    Returns:
        int: Minimalna stopnja vozlišča
    
    Primer:
        G = graphs.StarGraph(5)
        get_min_degree(G)  # Vrne 1 (zunanje točke)
    """
    if G.order() == 0:
        return 0
    
    degrees = G.degree()
    return min(degrees)

def get_max_degree(G):
    """
    Vrne maksimalno stopnjo vozlišča v grafu G.
    
    Args:
        G: Graf
    
    Returns:
        int: Maksimalna stopnja vozlišča
    
    Primer:
        G = graphs.StarGraph(5)
        get_max_degree(G)  # Vrne 5 (centralno vozlišče)
    """
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

def is_hamiltonian(G):
    """
    Preveri, ali je graf G Hamiltonov.
    
    Hamiltonov graf ima Hamiltonov cikel (cikel, ki obišče vsako vozlišče natanko enkrat).
    
    OPOMBA: Preverjanje Hamiltonovosti je NP-poln problem. Ta funkcija lahko traja zelo dolgo
    za večje grafe (n > 15-20). Sage uporablja algoritem, ki preizkusi vse možne cikle.
    
    Args:
        G: Graf
    
    Returns:
        bool: True če je graf Hamiltonov, False sicer
    
    Primer:
        G = graphs.CycleGraph(5)
        is_hamiltonian(G)  # Vrne True (celoten cikel je Hamiltonov)
        
        G = graphs.CompleteGraph(5)
        is_hamiltonian(G)  # Vrne True (polni grafi so vedno Hamiltonovi)
        
        G = graphs.PathGraph(5)
        is_hamiltonian(G)  # Vrne False (pot ni cikel)
        
        G = graphs.StarGraph(5)
        is_hamiltonian(G)  # Vrne False
    
    OPOZORILO: Za večje grafe (n > 20) lahko ta funkcija traja zelo dolgo!
    """
    try:
        return G.is_hamiltonian()
    except:
        # Če funkcija ne deluje (npr. za zelo velike grafe), vrni None
        return None

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

