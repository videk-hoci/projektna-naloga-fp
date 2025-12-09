from sage.all import *
from sage.numerical.mip import MixedIntegerLinearProgram

def alpha_od_ilp_correct(G):
    """
    Vrne α_od(G) - velikost največje lihe neodvisne množice.
    
    ILP formulacija iz članka:
    
    Spremenljivke:
    - xu ∈ {0,1}: vozlišče u je v odd independent množici S
    - yu ∈ {0,1}: vozlišče u ima soseda v S
    - zu ∈ Z: števec za vozlišče u
    
    Omejitve:
    1. xu + xv ≤ 1 za vsako povezavo uv (neodvisnost)
    2. Σ(xv : uv ∈ E) ≤ n·yu (yu = 1 če ima u soseda v S)
    3. yu + Σ(xv : uv ∈ E) = 2·zu (odd pogoj)
    
    Args:
        G: Graf
    
    Returns:
        int: Velikost največje odd independent množice ali None če graf ima > 40 vozlišč
    """
    V = list(G.vertices())
    n = len(V)
    
    # Specialni primeri
    if n == 0:
        return 0
    if n == 1:
        return 1
    
    # Skip grafov z več kot 40 vozliščmi
    if n > 40:
        print(f"SKIP: Graf z {n} vozlišči (> 40)")
        return None
    
    if G.size() == 0:  # Graf brez povezav
        return n
    
    # Če je graf nepovezan, obdelaj vsako komponento posebej
    if not G.is_connected():
        components = G.connected_components()
        total = 0
        for component in components:
            subgraph = G.subgraph(component)
            result = alpha_od_ilp_correct(subgraph)
            if result is None:  # Ena od komponent je prevelika
                return None
            total += result
        return total
    
    # ILP formulacija iz članka
    p = MixedIntegerLinearProgram(maximization=True, solver="GLPK")
    
    # Spremenljivke
    x = p.new_variable(binary=True)  # xu ∈ {0, 1}
    y = p.new_variable(binary=True)  # yu ∈ {0, 1}
    z = p.new_variable(integer=True)  # zu ∈ Z
    
    # Ciljna funkcija: maksimiziraj Σ xu
    p.set_objective(sum(x[u] for u in V))
    
    # Omejitev 1: neodvisna množica
    for u, v in G.edges(labels=False):
        p.add_constraint(x[u] + x[v] <= 1)
    
    # Omejitve 2 & 3: odd pogoj
    for u in V:
        neighbors = list(G.neighbors(u))
        
        if len(neighbors) == 0:
            # Če nima sosedov, yu = 0 in zu = 0
            p.add_constraint(y[u] == 0)
            p.add_constraint(z[u] == 0)
        else:
            neighbor_sum = sum(x[v] for v in neighbors)
            
            # Omejitev 2: Σ(xv : uv ∈ E) ≤ n·yu
            p.add_constraint(neighbor_sum <= n * y[u])
            
            # Omejitev 3: yu + Σ(xv : uv ∈ E) = 2·zu
            p.add_constraint(y[u] + neighbor_sum == 2 * z[u])
    
    # Reši ILP
    try:
        p.solve()
        solution_x = p.get_values(x)
        S = set(u for u in V if solution_x[u] > 0.5)
        return len(S)
    except Exception as e:
        print(f"ILP napaka: {e}")
        return 0


def is_odd_independent_set(G, S):
    """
    Preveri, ali je S odd independent množica v grafu G.
    
    Args:
        G: Graf
        S: Množica vozlišč
    
    Returns:
        bool: True če je S odd independent, False sicer
    """
    S_set = set(S)
    
    # Preveri neodvisnost
    for u in S_set:
        for v in G.neighbors(u):
            if v in S_set:
                return False
    
    # Preveri odd pogoj
    for u in G.vertices():
        if u not in S_set:
            count = sum(1 for v in G.neighbors(u) if v in S_set)
            # Mora biti 0 ali liho
            if count != 0 and count % 2 == 0:
                return False
    
    return True



def alpha_od_ilp_tilen(G):    
    n = G.order()
    
    # Skip grafov z več kot 40 vozliščmi
    if n > 40:
        print(f"SKIP: Graf z {n} vozlišči (> 40)")
        return None
    
    V = G.vertices()
    
    # Create the mixed integer linear program
    mip = MixedIntegerLinearProgram(maximization=True)
    
    # Define variables
    x = mip.new_variable(binary=True) # Indicator if vertex v is in the independent set
    y = mip.new_variable(binary=True) # Indicator if vertex v has neighbors in the independent set
    z = mip.new_variable(integer=True) # Counter for the vertex v
    
    # Objective function
    mip.set_objective(mip.sum(x[v] for v in V))
    
    # Constraints
    for u, v in G.edges(labels=False):
        mip.add_constraint(x[u] + x[v] <= 1)
        
    for u in V:
        sum_neighbors = mip.sum(x[v] for v in G.neighbors(u))
        mip.add_constraint(sum_neighbors <= n * y[u])
        mip.add_constraint(y[u] + sum_neighbors == 2*z[u])
    
    # Solve the MIP
    return mip.solve()

# Test funkcija
def test_alpha_od():
    """
    Testira implementacijo na nekaj znanih primerih.
    """
    print("=== TEST α_od ILP ===\n")
    
    # Test 1: Graf brez povezav
    G1 = Graph(5)
    result1 = alpha_od_ilp_correct(G1)
    print(f"Test 1 - Graf brez povezav (5 vozlišč): α_od = {result1} (pričakovano: 5)")
    
    # Test 2: Pot P4
    G2 = graphs.PathGraph(4)
    result2 = alpha_od_ilp_correct(G2)
    print(f"Test 2 - Pot P4: α_od = {result2}")
    
    # Test 3: Cikel C5
    G3 = graphs.CycleGraph(5)
    result3 = alpha_od_ilp_correct(G3)
    print(f"Test 3 - Cikel C5: α_od = {result3}")
    
    # Test 4: Poln graf K4
    G4 = graphs.CompleteGraph(4)
    result4 = alpha_od_ilp_correct(G4)
    print(f"Test 4 - Poln graf K4: α_od = {result4} (pričakovano: 1)")
    
    # Test 5: Problematični graf iz primera
    G5 = Graph()
    G5.add_vertices([0, 1, 2, 3, 4, 5])
    G5.add_edges([(0, 3), (0, 5), (1, 4), (2, 5)])
    result5 = alpha_od_ilp_correct(G5)
    print(f"Test 5 - Graf 6_4_8: α_od = {result5}")
    print(f"  Komponente: {G5.connected_components()}")
    
    # Test 6: Drugi problematični graf
    G6 = Graph()
    G6.add_vertices([0, 1, 2, 3, 4, 5])
    G6.add_edges([(0, 3), (0, 5), (1, 4), (1, 5), (2, 5), (3, 5)])
    result6 = alpha_od_ilp_correct(G6)
    print(f"Test 6 - Graf 6_6_7: α_od = {result6}")
    print(f"  Komponente: {G6.connected_components()}")

# Zaženi teste

