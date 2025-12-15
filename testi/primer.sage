from sage.all import *
load("graph_tools.sage")
load('prediction_model.sage')
G = Graph([(0,1),(1,2),(2,0)])  # C3
print("alpha_od(G) =", alpha_od_ilp_correct(G))
print("alpha(G) =", G.independent_set(value_only=True))




# Kvadrat grafa - vozlišča povezana, če so v razdalji <= 2
G_squared = graph_power(G, 2)
print("alpha(G^2) =", G_squared.independent_set(value_only=True))

H = Graph([(0,1),(1,2),(2,3),(3,0)])  # C4
print("alpha_od(H) =", alpha_od_ilp_correct(H))
print("alpha(H) =", H.independent_set(value_only=True))




# Kvadrat C4
H_squared = graph_power(H, 2)
print("alpha(H^2) =", H_squared.independent_set(value_only=True))
print("Povezave v H^2:", H_squared.edges(labels=False))
print("alpha^2(G) =", graph_power(G, 2).independent_set(value_only=True))

predict_alfas(G)
predict_alfas(H)
print(G.diameter())  # Premer grafa G


F = graphs.CompleteGraph(25)
predict_alfas(F)