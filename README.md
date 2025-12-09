# Odd independent number vs. usual independent number

## Povzetek

## Razlaga kode

## Ugotovitve
Kot ugotovitve bova predstavila potrebne pogoje in zadostne pogoje.

### Družine grafov
#### Kneserjevi grafi KG(n,k)

Po EKR za $n\ge 2k$ velja $\alpha(KG(n,k)) = \binom{n-1}{k-1}$, za $n < 2k$ pa velja kar $\alpha(KG(n,k)) = \binom{n}{k}$

**Primer (k=1):** $(KG(n,1))$
Graf je popoln ($K_n$), zato velja:
$\alpha(G) = 1, \quad \alpha_{\text{odd}}(G) = 1, \quad \alpha(G^2) = 1$

**Primer (k=n/2):** $(KG(n,n/2))$
Vozlišča so vse $(n/2)$-podmnožice; disjunktna sta le komplementarna para, zato je graf popoln ujemalni graf (matching). S tem velja:
$\alpha(G) = \binom{n-1}{n/2-1}, \quad \alpha_{\text{odd}}(G) = \alpha(G), \quad \alpha(G^2) = \alpha(G)$

**Primer (k=2):** $(KG(n,2))$
- Če je $n$ **sodo**: $\alpha_{\text{odd}}(G) = \alpha(G) = n-1$.
- Če je $n$ **liho**: $\alpha_{\text{odd}}(G) = 3$. 

**O kvadratu grafa $G^2$ in premeru**
- Za $KG(n,k)$ velja: **premer** je 2, kadar je $n\ge 3k-1$. V tem primeru je $G^2$ poln graf, torej
  $\alpha(G^2)=1\quad \text{(za } n\ge 3k-1\text{)}.$


### Trivialni zadostni pogoji
Če je graf polni je alfa(G) = alfa_od(G) = alfa(G^2)
Če je graf cikel je alfa_od(G) = alfa(G^2)
Če je graf pot je alfa_od(G) = alfa(G^2)

### Trivialni potrebni pogoji

### Zadostni pogoji

### Potrebni pogoji