# Odd independent number vs. usual independent number

## Opis problema

Najini osrednji raziskovalni vprašanji sta bili:

1. Kateri grafi G zadostijo enakosti $\alpha_{\text{od}}(G) = \alpha(G)$
2. Kateri grafi G zadostijo enakosti $\alpha_{\text{od}}(G) = \alpha(G^2)$

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

#### Kartezični produkt polnih grafov

#### Polni grafi

#### Poti

#### Cikli


### Statistična analiza
Iz neenakosti $\alpha(G) \geq \alpha_{\text{odd}}(G) \geq \alpha(G^2)$ sledi, da je $\alpha_{\text{odd}}(G)$ v primeru enakosti 
$\alpha(G) = \alpha(G^2)$ tudi $\alpha_{\text{odd}}(G)$ obema enaka. Sedaj predpostaviva, da si nista enaki.

Če je maksimalna stopnja vozlišča v grafu 2 sta $\alpha(G) = \alpha(G^2)$. Prav tako to velja za grafe, kjer je kromatično število za ena manjše od števila vozlišč.

### Trivialni zadostni pogoji
Če je graf polni je alfa(G) = alfa_od(G) = alfa(G^2)
Če je graf cikel je alfa_od(G) = alfa(G^2)
Če je graf pot je alfa_od(G) = alfa(G^2)

### Trivialni potrebni pogoji

### Zadostni pogoji

### Potrebni pogoji