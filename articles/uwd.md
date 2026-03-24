# Undirected Wiring Diagrams

## Introduction

**Undirected wiring diagrams** (UWDs) are a categorical formalism for
describing how open systems compose by sharing interfaces. In a UWD,
each subsystem is a *box* with *ports*, and composition happens by
wiring ports of different boxes to common *junctions*. Because the wires
are undirected, junctions model **shared variables** rather than
directed signal flow.

UWDs originate from applied category theory and are a core data
structure in the [AlgebraicJulia](https://www.algebraicjulia.org/)
ecosystem. They are used to compose dynamical systems, agent-based
models, Petri nets, stock-flow models, and more. The key idea is that
you can specify the *architecture* of a composed system (which
subsystems share which variables) separately from the *dynamics* of each
subsystem.

For example, an SIR epidemiological model can be decomposed into two
sub-processes—infection and recovery—that share populations through
junctions:

- **Infection** involves the susceptible (`s`) and infected (`i`)
  populations.
- **Recovery** involves the infected (`i`) and recovered (`r`)
  populations.

The junction `i` is shared between both boxes, expressing that the same
infected population participates in both processes.

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

## The UWD schema

A UWD is defined as an ACSet (attributed C-set) over the schema
`SchUWD`. The schema has four object types and three morphisms:

| Object      | Role                                                    |
|-------------|---------------------------------------------------------|
| `Box`       | A subsystem / process                                   |
| `Port`      | An interface point on a box                             |
| `OuterPort` | An interface point exposed to the outside world         |
| `Junction`  | A shared variable that ports and outer ports connect to |

| Morphism         | Signature            | Meaning                              |
|------------------|----------------------|--------------------------------------|
| `box`            | Port → Box           | Which box a port belongs to          |
| `junction`       | Port → Junction      | Which junction a port is wired to    |
| `outer_junction` | OuterPort → Junction | Which junction an outer port exposes |

Junctions also carry a `name` attribute (`name: Junction → Name`) so
that each shared variable has a human-readable label.

``` r
SchUWD
#> <acsets::BasicSchema>
#>  @ obs      : chr [1:4] "Box" "Port" "OuterPort" "Junction"
#>  @ homs     :List of 3
#>  .. $ :List of 3
#>  ..  ..$ name : chr "box"
#>  ..  ..$ dom  : chr "Port"
#>  ..  ..$ codom: chr "Box"
#>  .. $ :List of 3
#>  ..  ..$ name : chr "junction"
#>  ..  ..$ dom  : chr "Port"
#>  ..  ..$ codom: chr "Junction"
#>  .. $ :List of 3
#>  ..  ..$ name : chr "outer_junction"
#>  ..  ..$ dom  : chr "OuterPort"
#>  ..  ..$ codom: chr "Junction"
#>  @ attrtypes: chr "Name"
#>  @ attrs    :List of 1
#>  .. $ :List of 3
#>  ..  ..$ name : chr "name"
#>  ..  ..$ dom  : chr "Junction"
#>  ..  ..$ codom: chr "Name"
```

An empty UWD is created with
[`UWD()`](https://catrgory.github.io/catlab/reference/UWD.md):

``` r
w <- UWD()
nparts(w, "Box")
#> [1] 0
nparts(w, "Junction")
#> [1] 0
```

## Creating UWDs with `relation()`

The
[`relation()`](https://catrgory.github.io/catlab/reference/relation.md)
function provides a DSL inspired by relational algebra. Outer port
junction names are passed as bare (unquoted) arguments, and boxes are
specified through a `.boxes` list of
[`box_spec()`](https://catrgory.github.io/catlab/reference/box_spec.md)
calls.

### Step 1: Define box specifications

Each
[`box_spec()`](https://catrgory.github.io/catlab/reference/box_spec.md)
takes a name and a set of junction names that the box connects to:

``` r
inf_box <- box_spec("infection", "s", "i")
rec_box <- box_spec("recovery", "i", "r")
inf_box
#> $name
#> [1] "infection"
#> 
#> $ports
#> [1] "s" "i"
rec_box
#> $name
#> [1] "recovery"
#> 
#> $ports
#> [1] "i" "r"
```

### Step 2: Build the UWD with `relation()`

Pass the outer port junction names as bare symbols, and the box
specifications via `.boxes`:

``` r
w_rel <- relation(s, i, r, .boxes = list(
  box_spec("infection", "s", "i"),
  box_spec("recovery", "i", "r")
))
```

This creates a UWD with:

- **3 junctions** named `s`, `i`, `r`
- **3 outer ports** (one for each junction exposed externally)
- **2 boxes** (infection and recovery)
- **4 ports** (infection has 2 ports, recovery has 2 ports)

``` r
nparts(w_rel, "Junction")
#> [1] 3
nparts(w_rel, "OuterPort")
#> [1] 3
nparts(w_rel, "Box")
#> [1] 2
nparts(w_rel, "Port")
#> [1] 4
```

## Creating UWDs with `uwd()`

The [`uwd()`](https://catrgory.github.io/catlab/reference/UWD.md)
function provides a more concise syntax. The first argument is a
character vector of outer port junction names, and subsequent named
arguments define boxes as character vectors of junction names:

``` r
w <- uwd(
  c("s", "i", "r"),
  infection = c("s", "i"),
  recovery  = c("i", "r")
)
```

This produces the same structure as the
[`relation()`](https://catrgory.github.io/catlab/reference/relation.md)
call above:

``` r
nparts(w, "Junction")
#> [1] 3
nparts(w, "OuterPort")
#> [1] 3
nparts(w, "Box")
#> [1] 2
nparts(w, "Port")
#> [1] 4
```

The [`uwd()`](https://catrgory.github.io/catlab/reference/UWD.md) syntax
is generally preferred for its brevity, while
[`relation()`](https://catrgory.github.io/catlab/reference/relation.md)
may be more readable when box specifications are complex or built
programmatically.

## Inspecting UWDs

### Counting parts

Use
[`nparts()`](https://catrgory.github.io/acsets/reference/nparts.html) to
count elements of each type:

``` r
nparts(w, "Box")
#> [1] 2
nparts(w, "Port")
#> [1] 4
nparts(w, "Junction")
#> [1] 3
nparts(w, "OuterPort")
#> [1] 3
```

### Querying morphisms with `subpart()`

Use
[`subpart()`](https://catrgory.github.io/acsets/reference/subpart.html)
to follow morphisms and attributes. For example, to find which box each
port belongs to:

``` r
# Port 1 belongs to which box?
subpart(w, 1, "box")
#> [1] 1

# Port 3 belongs to which box?
subpart(w, 3, "box")
#> [1] 2
```

To find which junction each port connects to:

``` r
# Port 1 connects to which junction?
subpart(w, 1, "junction")
#> [1] 1

# Port 2 connects to which junction?
subpart(w, 2, "junction")
#> [1] 2
```

### Reading junction names

Each junction has a `name` attribute:

``` r
# Name of junction 1
subpart(w, 1, "name")
#> [1] "s"

# Name of junction 2
subpart(w, 2, "name")
#> [1] "i"

# Name of junction 3
subpart(w, 3, "name")
#> [1] "r"
```

### Listing all junction names

Use [`parts()`](https://catrgory.github.io/acsets/reference/parts.html)
to get all part IDs, then retrieve their names:

``` r
junc_ids <- parts(w, "Junction")
junction_names <- vapply(junc_ids, function(j) subpart(w, j, "name"), character(1))
junction_names
#> [1] "s" "i" "r"
```

### Querying outer port connections

Each outer port connects to a junction via `outer_junction`:

``` r
# Outer port 1 connects to which junction?
subpart(w, 1, "outer_junction")
#> [1] 1

# Outer port 2 connects to which junction?
subpart(w, 2, "outer_junction")
#> [1] 2
```

## Visualizing UWDs

The
[`uwd_to_dot()`](https://catrgory.github.io/catlab/reference/uwd_to_dot.md)
function generates a Graphviz DOT string for visualizing a UWD. In the
output:

- **Circles** represent junctions (labeled with the junction name)
- **Rectangles** represent boxes
- **Diamonds** represent outer ports (the external interface)
- **Edges** connect boxes to junctions (via ports) and outer ports to
  junctions

``` r
to_graphviz(w)
```

If you have the `DiagrammeR` package installed, you can render this
interactively with `to_graphviz(w)`.

## Epidemiological example: SIR model

The classic SIR (Susceptible-Infected-Recovered) compartmental model is
a natural example of system composition. The model consists of two
processes:

1.  **Infection**: susceptible individuals become infected through
    contact with infected individuals. This process involves the `s` and
    `i` compartments.
2.  **Recovery**: infected individuals recover. This process involves
    the `i` and `r` compartments.

The junction `i` is shared between both processes, expressing that the
infected population is the interface between infection and recovery.

``` r
sir <- uwd(
  c("s", "i", "r"),
  infection = c("s", "i"),
  recovery  = c("i", "r")
)
nparts(sir, "Box")
#> [1] 2
nparts(sir, "Port")
#> [1] 4
nparts(sir, "Junction")
#> [1] 3
```

The DOT visualization shows the two boxes connected through their shared
junction:

``` r
to_graphviz(sir)
```

This architecture can be used downstream to compose ODE systems, Petri
nets, or agent-based models for each process into a complete SIR model.

## Predator-prey example: Lotka-Volterra

The Lotka-Volterra predator-prey model decomposes into three processes:

1.  **Growth**: prey (`x`) reproduce, depending only on the prey
    population.
2.  **Predation**: predators (`y`) consume prey (`x`), involving both
    populations.
3.  **Decline**: predators (`y`) die, depending only on the predator
    population.

``` r
lv <- uwd(
  c("x", "y"),
  growth    = c("x"),
  predation = c("x", "y"),
  decline   = c("y")
)
```

Let’s verify the structure:

``` r
nparts(lv, "Box")       # 3 boxes: growth, predation, decline
#> [1] 3
nparts(lv, "Junction")  # 2 junctions: x, y
#> [1] 2
nparts(lv, "OuterPort") # 2 outer ports
#> [1] 2
nparts(lv, "Port")      # 4 ports: growth(1) + predation(2) + decline(1)
#> [1] 4
```

The key feature here is that the `x` junction is shared between growth
and predation, and the `y` junction is shared between predation and
decline. Predation is the process that couples the two populations.

``` r
to_graphviz(lv)
```

## Multi-component systems

UWDs naturally express more complex architectures where multiple
subsystems share variables in overlapping ways. Consider an SEIR
(Susceptible-Exposed-Infected-Recovered) epidemiological model with
three processes:

1.  **Exposure**: susceptible individuals are exposed through contact
    with infected individuals (involves `s`, `e`, `i`).
2.  **Progression**: exposed individuals become infectious (involves
    `e`, `i`).
3.  **Recovery**: infected individuals recover (involves `i`, `r`).

``` r
seir <- uwd(
  c("s", "e", "i", "r"),
  exposure    = c("s", "e", "i"),
  progression = c("e", "i"),
  recovery    = c("i", "r")
)
```

``` r
nparts(seir, "Box")       # 3 boxes
#> [1] 3
nparts(seir, "Junction")  # 4 junctions: s, e, i, r
#> [1] 4
nparts(seir, "OuterPort") # 4 outer ports
#> [1] 4
nparts(seir, "Port")      # 7 ports: exposure(3) + progression(2) + recovery(2)
#> [1] 7
```

The junction `i` appears in all three processes: as an input to exposure
(infected individuals drive new exposures), as the output of
progression, and as the input to recovery. This is the power of
UWDs—junctions naturally express many-to-many sharing of variables
across subsystems.

``` r
to_graphviz(seir)
```

### A larger example: coupled SIR with vital dynamics

Consider two SIR-like processes augmented with vital dynamics (birth and
death). This model has five processes sharing four compartments:

``` r
coupled <- uwd(
  c("s", "i", "r"),
  birth     = c("s"),
  infection = c("s", "i"),
  recovery  = c("i", "r"),
  waning    = c("r", "s"),
  death     = c("s", "i", "r")
)
```

``` r
nparts(coupled, "Box")       # 5 boxes
#> [1] 5
nparts(coupled, "Junction")  # 3 junctions
#> [1] 3
nparts(coupled, "OuterPort") # 3 outer ports
#> [1] 3
nparts(coupled, "Port")      # 9 ports
#> [1] 10
```

Here the junction `s` participates in four processes (birth, infection,
waning, and death), while `i` participates in three (infection,
recovery, and death). The `death` box connects to all three
compartments, showing how UWDs easily represent processes with broad
interfaces.

``` r
to_graphviz(coupled)
```

## Summary

| Function                                                                    | Purpose                                                                                            |
|-----------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------|
| `SchUWD`                                                                    | The UWD schema (objects, homs, attrs)                                                              |
| [`UWD()`](https://catrgory.github.io/catlab/reference/UWD.md)               | Create an empty UWD                                                                                |
| [`relation()`](https://catrgory.github.io/catlab/reference/relation.md)     | DSL for building UWDs with [`box_spec()`](https://catrgory.github.io/catlab/reference/box_spec.md) |
| [`box_spec()`](https://catrgory.github.io/catlab/reference/box_spec.md)     | Define a box with its junction connections                                                         |
| [`uwd()`](https://catrgory.github.io/catlab/reference/UWD.md)               | Concise syntax for building UWDs                                                                   |
| [`nparts()`](https://catrgory.github.io/acsets/reference/nparts.html)       | Count parts of a given type                                                                        |
| [`subpart()`](https://catrgory.github.io/acsets/reference/subpart.html)     | Query morphisms and attributes                                                                     |
| [`parts()`](https://catrgory.github.io/acsets/reference/parts.html)         | List all part IDs of a given type                                                                  |
| [`uwd_to_dot()`](https://catrgory.github.io/catlab/reference/uwd_to_dot.md) | Generate Graphviz DOT visualization                                                                |

UWDs provide a compositional architecture language: they describe *how*
subsystems connect without prescribing *what* each subsystem does. This
separation of architecture from dynamics is the foundation for
compositional modeling in the AlgebraicJulia ecosystem, and `catlab`
brings this approach to R.
