# Odd independent number vs. usual independent number

## Uvod

Naj bo $G = (V,E)$ enostaven, neusmerjen graf.

**Neodvisna množica** v $G$ je množica vozlišč $S \subseteq V$, pri kateri nobeni dve vozlišči nista povezani:

$$\forall u, v \in S : uv \notin E.$$

Moč največje take množice se imenuje **neodvisno število** grafa $G$ in se označuje z $\alpha(G)$.

**Liha neodvisna množica** v grafu $G$ je neodvisna množica $T \subseteq V$, za katero za vsako vozlišče $v \in V \setminus T$ velja:

$$|N(v) \cap T| \equiv 1 \pmod{2} \quad \text{ali} \quad |N(v) \cap T| = 0,$$

kjer $N(v)$ označuje sosedna vozlišča od $v$.
Moč največje take množice se imenuje **liho neodvisno število** grafa $G$ in se označuje z $\alpha_{od}(G)$.


**Kvadrat grafa $G^2$** ima isto množico vozlišč kot $G$, 
pri čemer sta dve vozlišči povezani natanko tedaj, ko je v $G$ med njima pot dolžine 1 ali 2.

## Opis problema

Najini osrednji raziskovalni vprašanji sta bili:

1. Kateri grafi $G$ zadostijo enakosti **$\alpha_{\text{od}}(G) = \alpha(G)$**
2. Kateri grafi $G$ zadostijo enakosti **$\alpha_{\text{od}}(G) = \alpha(G^2)$**

## Razlaga kode
V graph_tools.sage so vse uporabljene funkcije za generiranje grafov in funkcija alpha_od_ilp_correct(G), ki izračuna $\alpha_{\text{od}}(G)$. V predicition_model.sage
je funkcija, ki na podlagi statističnih lastnosti ugiba iskane enakosti, nato pa jih še izračuna in preveri pravilnosti predvidevanj.
Vse funkcije kličemo v main.sage, rezultate pa zapišemo v CSV datoteke v mapi data.
