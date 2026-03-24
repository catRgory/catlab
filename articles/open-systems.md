# Open Systems and Typed ACSets

## Introduction

Real-world models are rarely built from scratch as monolithic wholes.
Instead, they are assembled from **components** that interact through
**interfaces**. An epidemiological model is composed of infection,
recovery, and demographic processes sharing populations. A distributed
system is built from services connected at their APIs.

Category theory provides a rigorous framework for this kind of
compositional modeling:

- **Typed ACSets** constrain elements by assigning each one a type from
  a shared type system. This enables operations like *stratification*
  (combining a disease model with an age structure) via typed products.
- **Structured cospans** formalize the notion of an *open system*: a
  system (the apex) together with designated interface points (the
  legs/feet). Composition glues two systems at a shared interface via
  pushout, while the monoidal product places systems side by side.
- **Undirected wiring diagrams** (UWDs) describe the architecture of a
  composed system — which subsystems share which variables — separately
  from the dynamics. The `oapply_cospans` operation composes a list of
  open systems according to a wiring diagram.

This vignette demonstrates these concepts using the `catlab` package.

``` r
library(catlab)
library(acsets)
#> 
#> Attaching package: 'acsets'
#> The following object is masked from 'package:graphics':
#> 
#>     arrows
#> The following object is masked from 'package:base':
#> 
#>     objects
```

## Typed ACSets

A **typed ACSet** pairs a concrete ACSet $X$ with a morphism
$\left. \varphi:X\rightarrow T \right.$ to a *type system* $T$. Every
element in $X$ is assigned a type by $\varphi$, and the naturality of
$\varphi$ ensures that the typing is consistent with the structure
(e.g., if an edge connects type-A and type-B vertices, the type of the
edge must connect those same vertex types in $T$).

### Defining a type system

A type system is just an ACSet that serves as an abstract template. For
example, a graph with two vertex types (“host” and “pathogen”) and one
edge type (interaction from host to pathogen):

``` r
T <- Graph()
invisible(add_vertices(T, 2))    # type 1 = host, type 2 = pathogen
invisible(add_edge(T, 1, 2))     # edge type: host → pathogen
cat("Type system: V =", nv(T), ", E =", ne(T), "\n")
#> Type system: V = 2 , E = 1
cat(to_dot(T))
#> digraph G {
#>   1;
#>   2;
#>   1 -> 2;
#> }
```

### Creating typed graphs

Now create a concrete graph and assign types. Here we have two hosts
(vertices 1–2, type 1), one pathogen (vertex 3, type 2), and two
interactions (both of type 1, mapping to the host→pathogen edge in $T$):

``` r
G <- Graph()
invisible(add_vertices(G, 3))
invisible(add_edge(G, 1, 3))   # host 1 → pathogen
invisible(add_edge(G, 2, 3))   # host 2 → pathogen

tG <- typed_acset(G, T, V = c(1L, 1L, 2L), E = c(1L, 1L))
cat("Typed graph: V =", nv(tG@acset), ", E =", ne(tG@acset), "\n")
#> Typed graph: V = 3 , E = 2
cat("Vertex types:", tG@typing@components$V, "\n")
#> Vertex types: 1 1 2
cat("Edge types:", tG@typing@components$E, "\n")
#> Edge types: 1 1
```

The naturality condition is automatically checked: each edge’s source
and target types must match the type system’s structure. An inconsistent
typing is rejected.

### Typed product (stratification)

The **typed product** computes the pullback over the shared type system.
For each object, it forms all pairs $\left( x_{1},x_{2} \right)$ where
$\varphi_{1}\left( x_{1} \right) = \varphi_{2}\left( x_{2} \right)$ —
elements of matching type are paired. This is the categorical product in
the slice category
${\mathbf{A}\mathbf{C}\mathbf{S}\mathbf{e}\mathbf{t}}/T$.

This is exactly the operation used in **stratification**: take a disease
model typed by compartment roles, take a population structure typed by
the same roles, and their product gives the stratified model.

``` r
# G1: 2 hosts, 1 pathogen, 2 edges (host → pathogen)
G1 <- Graph()
invisible(add_vertices(G1, 3))
invisible(add_edge(G1, 1, 3))
invisible(add_edge(G1, 2, 3))
tG1 <- typed_acset(G1, T, V = c(1L, 1L, 2L), E = c(1L, 1L))

# G2: 1 host, 1 pathogen, 1 edge
G2 <- Graph()
invisible(add_vertices(G2, 2))
invisible(add_edge(G2, 1, 2))
tG2 <- typed_acset(G2, T, V = c(1L, 2L), E = c(1L))

tp <- typed_product(tG1, tG2)
cat("Product: V =", nv(tp@acset), ", E =", ne(tp@acset), "\n")
#> Product: V = 3 , E = 2
cat("Product vertex types:", tp@typing@components$V, "\n")
#> Product vertex types: 1 1 2
```

The product has 3 vertices (host pairs (1,1) and (2,1), plus pathogen
pair (3,2)) and 2 edges (each edge in G1 paired with the single
matching-type edge in G2).

### Typed coproduct

The **typed coproduct** is the disjoint union with the combined typing.
It is useful when merging independent components that share a type
system.

``` r
# Two small typed graphs over a 2-type system (no edges)
T2 <- Graph()
invisible(add_vertices(T2, 2))

H1 <- Graph()
invisible(add_vertices(H1, 2))
tH1 <- typed_acset(H1, T2, V = c(1L, 2L), E = integer(0))

H2 <- Graph()
invisible(add_vertices(H2, 3))
tH2 <- typed_acset(H2, T2, V = c(1L, 1L, 2L), E = integer(0))

tc <- typed_coproduct(tH1, tH2)
cat("Coproduct: V =", nv(tc@acset), "\n")
#> Coproduct: V = 5
cat("Types:", tc@typing@components$V, "\n")
#> Types: 1 2 1 1 2
```

### Checking typed morphisms

A morphism $\left. f:X_{1}\rightarrow X_{2} \right.$ between typed
ACSets preserves typing if $\varphi_{2} \circ f = \varphi_{1}$. The
`is_typed_morphism` function checks this condition.

``` r
# Two typed graphs over a 2-vertex-type system
G1 <- Graph()
invisible(add_vertices(G1, 2))
tG1 <- typed_acset(G1, T2, V = c(1L, 2L), E = integer(0))

G2 <- Graph()
invisible(add_vertices(G2, 3))
tG2 <- typed_acset(G2, T2, V = c(1L, 2L, 1L), E = integer(0))

# Good: maps type-1 → type-1, type-2 → type-2
f_good <- ACSetTransformation(list(V = c(1L, 2L), E = integer(0)), G1, G2)
cat("Type-preserving?", is_typed_morphism(f_good, tG1, tG2), "\n")
#> Type-preserving? TRUE

# Bad: maps type-1 → type-2 (vertex 1 sent to vertex 2)
f_bad <- ACSetTransformation(list(V = c(2L, 1L), E = integer(0)), G1, G2)
cat("Type-preserving?", is_typed_morphism(f_bad, tG1, tG2), "\n")
#> Type-preserving? FALSE
```

### Creating typed ACSets from type assignments

The `discrete_typed` function creates a typed ACSet directly from type
assignments, without needing to build the underlying ACSet first. This
is useful when you only care about the typing structure (no edges):

``` r
T3 <- Graph()
invisible(add_vertices(T3, 3))  # 3 vertex types

dt <- discrete_typed(T3, V = c(1L, 1L, 2L, 3L))
cat("Vertices:", nv(dt@acset), "\n")
#> Vertices: 4
cat("Types:", dt@typing@components$V, "\n")
#> Types: 1 1 2 3
```

## Open systems via structured cospans

A **structured cospan** formalizes the idea of an open system. It
consists of:

- An **apex**: the full system (an ACSet, e.g., a graph or Petri net).
- **Legs**: morphisms from discrete “feet” into the apex, identifying
  which parts of the system are exposed as interfaces.
- An **interface object**: which object type in the schema forms the
  interface (e.g., `"V"` for graphs, `"S"` for Petri net species).

The feet live in a simpler category (just finite sets represented as
discrete ACSets). The legs tell us which parts of the rich structure
(the apex) are visible from outside.

### Opening a path graph

Consider a path graph $\left. 1\rightarrow 2\rightarrow 3 \right.$. We
can “open” it by exposing vertex 1 on the left and vertex 3 on the
right:

``` r
G <- path_graph(3)
sc <- open_acset(G, "V", 1L, 3L)
cat("Apex: V =", nv(cospan_apex(sc)), ", E =", ne(cospan_apex(sc)), "\n")
#> Apex: V = 3 , E = 2
cat("Number of legs:", nlegs(sc), "\n")
#> Number of legs: 2
cat("Foot sizes:", foot_sizes(sc), "\n")
#> Foot sizes: 1 1
```

Each argument after `interface_ob` defines one leg. Here `1L` creates a
leg mapping one foot element to vertex 1, and `3L` creates a leg mapping
one foot element to vertex 3. This gives us a cospan
$\left. \{*\}\rightarrow G\leftarrow\{*\} \right.$ — two singleton feet.

### Multi-element legs

Legs can map multiple interface elements. For instance, opening a
complete graph with two vertices exposed on each side:

``` r
K4 <- complete_graph(4)
sc <- open_acset(K4, "V", c(1L, 2L), c(3L, 4L))
cat("Legs:", nlegs(sc), "\n")
#> Legs: 2
cat("Foot sizes:", foot_sizes(sc), "\n")
#> Foot sizes: 2 2
```

## Composing open systems

### Sequential composition (`compose_cospans`)

Two open systems can be composed **sequentially** by gluing the right
foot of the first to the left foot of the second via pushout. This
identifies the shared interface points.

``` r
# Two open edges: 1→2 with endpoints exposed
G1 <- path_graph(2)
sc1 <- open_acset(G1, "V", 1L, 2L)

G2 <- path_graph(2)
sc2 <- open_acset(G2, "V", 1L, 2L)

# Glue: vertex 2 of G1 = vertex 1 of G2
comp <- compose_cospans(sc1, sc2)
cat("Composed: V =", nv(cospan_apex(comp)), ", E =", ne(cospan_apex(comp)), "\n")
#> Composed: V = 3 , E = 2
```

The result is a path $\left. 1\rightarrow 2\rightarrow 3 \right.$: three
vertices (vertex 2 of G1 was identified with vertex 1 of G2) and two
edges.

### Building a longer chain

We can compose a longer path with a shorter one:

``` r
G1 <- path_graph(3)   # 1→2→3
sc1 <- open_acset(G1, "V", 1L, 3L)

G2 <- path_graph(2)   # 1→2
sc2 <- open_acset(G2, "V", 1L, 2L)

comp <- compose_cospans(sc1, sc2)
apex <- cospan_apex(comp)
cat("Chain: V =", nv(apex), ", E =", ne(apex), "\n")
#> Chain: V = 4 , E = 3
cat(to_dot(apex))
#> digraph G {
#>   1;
#>   2;
#>   3;
#>   4;
#>   1 -> 2;
#>   2 -> 3;
#>   3 -> 4;
#> }
```

### Parallel composition (`otimes_cospans`)

The **monoidal product** places two open systems side by side with no
interaction — it takes the coproduct (disjoint union) of the apexes:

``` r
G1 <- path_graph(2)
sc1 <- open_acset(G1, "V", 1L, 2L)

G2 <- path_graph(3)
sc2 <- open_acset(G2, "V", 1L, 3L)

tens <- otimes_cospans(sc1, sc2)
cat("Tensor: V =", nv(cospan_apex(tens)), ", E =", ne(cospan_apex(tens)), "\n")
#> Tensor: V = 5 , E = 3
cat("Legs:", nlegs(tens), "\n")
#> Legs: 4
```

The result has $2 + 3 = 5$ vertices, $1 + 2 = 3$ edges, and $2 + 2 = 4$
legs (each original cospan contributes its legs).

## Composition via wiring diagrams

While `compose_cospans` handles binary sequential composition,
real-world models often involve many components connected in complex
patterns. **Undirected wiring diagrams** (UWDs) describe the
architecture — which components share which variables — and
`oapply_cospans` performs the composition.

### SIR model from open graphs

An SIR epidemiological model has three compartments (S, I, R) and two
processes: infection (S→I) and recovery (I→R). We can build each process
as an open graph and compose them:

``` r
# Infection: edge S→I, with S and I as separate interface ports
G_inf <- Graph()
invisible(add_vertices(G_inf, 2))
invisible(add_edge(G_inf, 1, 2))
sc_inf <- open_acset(G_inf, "V", 1L, 2L)  # 2 legs: port S, port I

# Recovery: edge I→R, with I and R as separate interface ports
G_rec <- Graph()
invisible(add_vertices(G_rec, 2))
invisible(add_edge(G_rec, 1, 2))
sc_rec <- open_acset(G_rec, "V", 1L, 2L)  # 2 legs: port I, port R
```

The wiring diagram specifies how the ports connect:

``` r
w_sir <- uwd(
  c("s", "i", "r"),
  infection = c("s", "i"),
  recovery  = c("i", "r")
)
cat(uwd_to_dot(w_sir))
#> graph UWD {
#>   rankdir=LR;
#>   J_1 [label="s" shape=circle width=0.3 style=filled fillcolor=gray90];
#>   J_2 [label="i" shape=circle width=0.3 style=filled fillcolor=gray90];
#>   J_3 [label="r" shape=circle width=0.3 style=filled fillcolor=gray90];
#>   B_1 [label="Box 1" shape=box style=filled fillcolor=lightyellow];
#>   B_2 [label="Box 2" shape=box style=filled fillcolor=lightyellow];
#>   OP_1 [label="" shape=diamond width=0.2 style=filled fillcolor=black];
#>   OP_1 -- J_1;
#>   OP_2 [label="" shape=diamond width=0.2 style=filled fillcolor=black];
#>   OP_2 -- J_2;
#>   OP_3 [label="" shape=diamond width=0.2 style=filled fillcolor=black];
#>   OP_3 -- J_3;
#>   B_1 -- J_1;
#>   B_1 -- J_2;
#>   B_2 -- J_2;
#>   B_2 -- J_3;
#> }
```

Each box has ports (one per junction name listed). The junction `"i"` is
shared between both boxes, so the I vertex of infection will be
identified with the I vertex of recovery.

**Important**: each port of a box corresponds to one leg of the
structured cospan. Since the `infection` box has 2 ports (`"s"` and
`"i"`), `sc_inf` must have 2 legs — which it does because we called
`open_acset(G_inf, "V", 1L, 2L)` with two separate integer arguments.

``` r
sir <- oapply_cospans(w_sir, list(sc_inf, sc_rec))
apex <- cospan_apex(sir)
cat("SIR model: V =", nv(apex), ", E =", ne(apex), "\n")
#> SIR model: V = 3 , E = 2
cat("Outer legs:", nlegs(sir), ", Foot size:", foot_sizes(sir), "\n")
#> Outer legs: 1 , Foot size: 3
cat(to_dot(apex))
#> digraph G {
#>   1;
#>   2;
#>   3;
#>   1 -> 2;
#>   2 -> 3;
#> }
```

The result has 3 vertices (S, I, R — with the shared I identified) and 2
edges (S→I, I→R).

### Predator-prey model

A predator-prey system with three processes — prey growth, predation,
and predator decline:

``` r
# Each process is an open edge with 2 ports
make_open_edge <- function() {
  G <- Graph()
  invisible(add_vertices(G, 2))
  invisible(add_edge(G, 1, 2))
  open_acset(G, "V", 1L, 2L)
}

# Growth: prey reproduces (involves prey only → self-loop-like)
# For simplicity, model each as a directed transition
sc_growth <- make_open_edge()     # prey → prey (growth)
sc_predation <- make_open_edge()  # prey → predator (predation)
sc_decline <- make_open_edge()    # predator → predator (decline)

w_pp <- uwd(
  c("prey", "predator"),
  growth    = c("prey", "prey"),
  predation = c("prey", "predator"),
  decline   = c("predator", "predator")
)

pp <- oapply_cospans(w_pp, list(sc_growth, sc_predation, sc_decline))
apex_pp <- cospan_apex(pp)
cat("Predator-prey: V =", nv(apex_pp), ", E =", ne(apex_pp), "\n")
#> Predator-prey: V = 2 , E = 3
```

### Star topology: central hub with spokes

``` r
w_star <- uwd(
  c("a", "b", "c"),
  spoke1 = c("center", "a"),
  spoke2 = c("center", "b"),
  spoke3 = c("center", "c")
)

sc_e1 <- make_open_edge()
sc_e2 <- make_open_edge()
sc_e3 <- make_open_edge()

star <- oapply_cospans(w_star, list(sc_e1, sc_e2, sc_e3))
apex_star <- cospan_apex(star)
cat("Star: V =", nv(apex_star), ", E =", ne(apex_star), "\n")
#> Star: V = 4 , E = 3
cat(to_dot(apex_star))
#> digraph G {
#>   1;
#>   2;
#>   3;
#>   4;
#>   1 -> 2;
#>   1 -> 3;
#>   1 -> 4;
#> }
```

The three spokes share a `"center"` junction, so all three edge sources
are identified into a single hub vertex, giving 4 vertices and 3 edges.

### Chain of three edges

``` r
w_chain <- uwd(
  c("a", "d"),
  e1 = c("a", "b"),
  e2 = c("b", "c"),
  e3 = c("c", "d")
)

chain <- oapply_cospans(w_chain, list(
  make_open_edge(), make_open_edge(), make_open_edge()
))
apex_chain <- cospan_apex(chain)
cat("Chain: V =", nv(apex_chain), ", E =", ne(apex_chain), "\n")
#> Chain: V = 4 , E = 3
cat(to_dot(apex_chain))
#> digraph G {
#>   1;
#>   2;
#>   3;
#>   4;
#>   1 -> 2;
#>   2 -> 3;
#>   3 -> 4;
#> }
```

## Open Petri nets

Structured cospans work with any ACSet schema, not just graphs. **Petri
nets** are a natural application: each species (place) can be an
interface point, and composition glues shared species together.

### Defining a Petri net schema

A Petri net has species (S), transitions (T), input arcs (I), and output
arcs (O). We define the schema manually using `BasicSchema`:

``` r
SchPetriNet <- BasicSchema(
  obs = c("S", "T", "I", "O"),
  homs = list(
    hom("is", "I", "S"),
    hom("it", "I", "T"),
    hom("os", "O", "S"),
    hom("ot", "O", "T")
  ),
  attrtypes = character(0),
  attrs = list()
)
PetriNet <- acset_type(SchPetriNet, name = "PetriNet",
                       index = c("is", "it", "os", "ot"))
```

### Creating simple Petri nets

An infection transition: S + I → 2I (one S and one I consumed, two I
produced):

``` r
pn_inf <- PetriNet()
add_parts(pn_inf, "S", 2)         # S:1 = S, S:2 = I
#> [1] 1 2
add_parts(pn_inf, "T", 1)         # T:1 = infection
#> [1] 1
# Inputs: S and I feed into infection
add_part(pn_inf, "I", is = 1L, it = 1L)   # S → infection
#> [1] 1
add_part(pn_inf, "I", is = 2L, it = 1L)   # I → infection
#> [1] 2
# Outputs: infection produces 2 I
add_part(pn_inf, "O", os = 2L, ot = 1L)   # infection → I
#> [1] 1
add_part(pn_inf, "O", os = 2L, ot = 1L)   # infection → I
#> [1] 2
cat("Infection PN: S =", nparts(pn_inf, "S"),
    ", T =", nparts(pn_inf, "T"),
    ", I =", nparts(pn_inf, "I"),
    ", O =", nparts(pn_inf, "O"), "\n")
#> Infection PN: S = 2 , T = 1 , I = 2 , O = 2
cat(petri_to_dot(pn_inf))
#> digraph PetriNet {
#>   rankdir=LR;
#>   S_1 [label="S1" shape=circle style=filled fillcolor=lightskyblue];
#>   S_2 [label="S2" shape=circle style=filled fillcolor=lightskyblue];
#>   T_1 [label="T1" shape=box style=filled fillcolor=lightsalmon];
#>   S_1 -> T_1;
#>   S_2 -> T_1;
#>   T_1 -> S_2;
#>   T_1 -> S_2;
#> }
```

A recovery transition: I → R:

``` r
pn_rec <- PetriNet()
add_parts(pn_rec, "S", 2)         # S:1 = I, S:2 = R
#> [1] 1 2
add_parts(pn_rec, "T", 1)         # T:1 = recovery
#> [1] 1
add_part(pn_rec, "I", is = 1L, it = 1L)   # I → recovery
#> [1] 1
add_part(pn_rec, "O", os = 2L, ot = 1L)   # recovery → R
#> [1] 1
cat("Recovery PN: S =", nparts(pn_rec, "S"),
    ", T =", nparts(pn_rec, "T"), "\n")
#> Recovery PN: S = 2 , T = 1
cat(petri_to_dot(pn_rec))
#> digraph PetriNet {
#>   rankdir=LR;
#>   S_1 [label="S1" shape=circle style=filled fillcolor=lightskyblue];
#>   S_2 [label="S2" shape=circle style=filled fillcolor=lightskyblue];
#>   T_1 [label="T1" shape=box style=filled fillcolor=lightsalmon];
#>   S_1 -> T_1;
#>   T_1 -> S_2;
#> }
```

### Opening Petri nets at species

We open Petri nets at the species object (`"S"`), exposing which species
are interface points. Each port of a box corresponds to one leg:

``` r
# Infection has 2 species (S, I) — expose both as separate legs
sc_pn_inf <- open_acset(pn_inf, "S", 1L, 2L)
cat("Infection legs:", nlegs(sc_pn_inf), "\n")
#> Infection legs: 2

# Recovery has 2 species (I, R) — expose both as separate legs
sc_pn_rec <- open_acset(pn_rec, "S", 1L, 2L)
cat("Recovery legs:", nlegs(sc_pn_rec), "\n")
#> Recovery legs: 2
```

### Composing into an SIR Petri net

Use the same SIR wiring diagram as before. The junction `"i"` is shared,
so the I species of infection is identified with the I species of
recovery:

``` r
w_sir_pn <- uwd(
  c("s", "i", "r"),
  infection = c("s", "i"),
  recovery  = c("i", "r")
)

sir_pn <- oapply_cospans(w_sir_pn, list(sc_pn_inf, sc_pn_rec))
sir_apex <- cospan_apex(sir_pn)
cat("SIR Petri net:\n")
#> SIR Petri net:
cat("  Species:", nparts(sir_apex, "S"), "\n")
#>   Species: 3
cat("  Transitions:", nparts(sir_apex, "T"), "\n")
#>   Transitions: 2
cat("  Input arcs:", nparts(sir_apex, "I"), "\n")
#>   Input arcs: 3
cat("  Output arcs:", nparts(sir_apex, "O"), "\n")
#>   Output arcs: 3
cat(petri_to_dot(sir_apex))
#> digraph PetriNet {
#>   rankdir=LR;
#>   S_1 [label="S1" shape=circle style=filled fillcolor=lightskyblue];
#>   S_2 [label="S2" shape=circle style=filled fillcolor=lightskyblue];
#>   S_3 [label="S3" shape=circle style=filled fillcolor=lightskyblue];
#>   T_1 [label="T1" shape=box style=filled fillcolor=lightsalmon];
#>   T_2 [label="T2" shape=box style=filled fillcolor=lightsalmon];
#>   S_1 -> T_1;
#>   S_2 -> T_1;
#>   S_2 -> T_2;
#>   T_1 -> S_2;
#>   T_1 -> S_2;
#>   T_2 -> S_3;
#> }
```

The composed Petri net has 3 species (S, I, R), 2 transitions (infection
and recovery), and the appropriate input/output arcs — built
compositionally from two independent components.

## Typed graphs for stratification

Typed ACSets and products provide a principled way to perform
**stratification** — combining a base model (e.g., SIR disease dynamics)
with additional structure (e.g., age groups).

### Setting up a type system

We define a type system with two vertex types (“state” and “transition”)
and one edge type (state → transition). This captures the abstract
structure shared by both the disease model and the age structure:

``` r
T_strat <- Graph()
invisible(add_vertices(T_strat, 2))    # 1 = state, 2 = transition
invisible(add_edge(T_strat, 1, 2))     # state → transition
```

### Base SIR graph

An SIR model as a graph: three states (S, I, R) and two transitions
(infection, recovery), with edges from states to the transitions they
feed into:

``` r
sir_g <- Graph()
invisible(add_vertices(sir_g, 5))
# S(1), I(2), R(3) are states; inf(4), rec(5) are transitions
invisible(add_edge(sir_g, 1, 4))   # S → infection
invisible(add_edge(sir_g, 2, 4))   # I → infection
invisible(add_edge(sir_g, 2, 5))   # I → recovery

tG_sir <- typed_acset(sir_g, T_strat,
  V = c(1L, 1L, 1L, 2L, 2L),     # S,I,R = state; inf,rec = transition
  E = c(1L, 1L, 1L)               # all edges: state → transition
)
cat("SIR states:", sum(tG_sir@typing@components$V == 1L), "\n")
#> SIR states: 3
cat("SIR transitions:", sum(tG_sir@typing@components$V == 2L), "\n")
#> SIR transitions: 2
```

### Age stratification graph

Two age groups (young, old) with a single contact pattern:

``` r
age_g <- Graph()
invisible(add_vertices(age_g, 3))
# young(1), old(2) are states; contact(3) is a transition
invisible(add_edge(age_g, 1, 3))   # young → contact
invisible(add_edge(age_g, 2, 3))   # old → contact

tG_age <- typed_acset(age_g, T_strat,
  V = c(1L, 1L, 2L),              # young,old = state; contact = transition
  E = c(1L, 1L)                   # both edges: state → transition
)
cat("Age groups:", sum(tG_age@typing@components$V == 1L), "\n")
#> Age groups: 2
cat("Age transitions:", sum(tG_age@typing@components$V == 2L), "\n")
#> Age transitions: 1
```

### Stratified SIR-by-age model

The typed product pairs states with states and transitions with
transitions, but only where the types match:

``` r
stratified <- typed_product(tG_sir, tG_age)
strat_g <- flatten_typed(stratified)
cat("Stratified model:\n")
#> Stratified model:
cat("  Vertices:", nv(strat_g), "\n")
#>   Vertices: 8
cat("  Edges:", ne(strat_g), "\n")
#>   Edges: 6
cat("  Vertex types:", stratified@typing@components$V, "\n")
#>   Vertex types: 1 1 1 1 1 1 2 2
```

The 6 state-type vertices correspond to (S,young), (S,old), (I,young),
(I,old), (R,young), (R,old) — the product of 3 disease states × 2 age
groups. The 2 transition-type vertices correspond to (inf,contact) and
(rec,contact). The edges connect each stratified state to the
appropriate stratified transition.

This is the power of the typed product: the stratified model is derived
automatically from the component models and their shared type system,
without manually constructing every combination.

## Summary

| Function                       | Purpose                                 |
|--------------------------------|-----------------------------------------|
| `typed_acset(acs, T, ...)`     | Create typed ACSet with typing morphism |
| `typed_product(t1, t2)`        | Pullback over shared type system        |
| `typed_coproduct(t1, t2)`      | Disjoint union preserving types         |
| `flatten_typed(t)`             | Forget typing, get underlying ACSet     |
| `is_typed_morphism(f, t1, t2)` | Check type preservation                 |
| `discrete_typed(T, ...)`       | Create from type assignments            |
| `open_acset(apex, ob, ...)`    | Create structured cospan (open system)  |
| `compose_cospans(M, N)`        | Sequential composition via pushout      |
| `otimes_cospans(M, N)`         | Parallel composition via coproduct      |
| `oapply_cospans(w, cospans)`   | Compose via UWD wiring diagram          |
| `cospan_apex(sc)`              | Extract apex ACSet                      |
| `nlegs(sc)`, `foot_sizes(sc)`  | Query cospan structure                  |

Typed ACSets and structured cospans bring compositional modeling to R:
build complex models from simple components with well-defined
interfaces, compose them using categorical operations, and add type
constraints for stratification. The wiring diagram abstraction separates
*architecture* from *dynamics*, enabling modular, reusable model design.
