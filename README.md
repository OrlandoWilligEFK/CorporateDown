# CorporateDown

> Ein Corporate Design einmal definieren – und alle ggplot2-Abbildungen erscheinen
> automatisch darin.

<!-- badges: start -->
[![R-CMD-check](https://github.com/OrlandoWilligEFK/CorporateDown/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/OrlandoWilligEFK/CorporateDown/actions/workflows/R-CMD-check.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

`CorporateDown` ist ein R-Package, mit dem sich ein **Corporate Design** (Farben,
Schriften, Grössen, Logo) als deklarative YAML-Datei beschreiben lässt. Nach einem
einzigen Aufruf folgen **alle** danach erstellten ggplot2-Abbildungen automatisch
diesem Design – ohne dass in jeder Grafik Theme oder Farbskalen wiederholt werden
müssen.

Entwickelt und getestet wird das Paket am **CD Bund** / an den Abbildungen der
**EFK** (Eidgenössische Finanzkontrolle). Das entsprechende Design ist als
Referenz mitgeliefert.

## Warum?

Wer viele Abbildungen im selben Look braucht, kopiert sonst überall dieselben
`theme_*()`- und `scale_*()`-Bausteine. `CorporateDown` verschiebt diese Definition
an **eine** Stelle (eine YAML-Datei) und aktiviert sie global. Vorteile:

- **Konsistenz:** jede Grafik nutzt exakt dieselben Farben, Schriften und Abstände.
- **Wartbarkeit:** Design-Änderung an einer Stelle wirkt überall.
- **Teilbarkeit:** das YAML-Design lässt sich weitergeben – auch an Personen ohne
  R-Kenntnisse.

## Installation

```r
# install.packages("devtools")
devtools::install_github("OrlandoWilligEFK/CorporateDown")
```

## Quickstart

```r
library(CorporateDown)
library(ggplot2)

# 1) Design laden und global aktivieren
design <- corporate_design(
  system.file("designs/efk.yml", package = "CorporateDown")
)
set_corporate_design(design)

# 2) Ganz normaler ggplot-Code – erscheint automatisch im Corporate Design
p <- ggplot(mpg, aes(class, fill = drv)) +
  geom_bar() +
  labs(title = "Fahrzeuge nach Klasse", subtitle = "Beispiel im EFK-Design")

# 3) Für den Export: Logo, Titel und Quelle setzen und speichern
finalise_plot(
  p,
  source    = "Quelle: EFK",
  save_path = "abbildung.png"
)
```

Danach wieder zum ggplot2-Standard zurück:

```r
reset_corporate_design()
```

## So funktioniert das „automatisch"

`set_corporate_design()` registriert das Design über die dafür vorgesehenen
ggplot2-Mechanismen global:

- **Theme** via `theme_set(theme_corporate(design))`
- **Default-Farbskalen** via `options(ggplot2.discrete.colour = …, ggplot2.discrete.fill = …, …)`
- **Geom-Defaults** (Balken-, Linien-, Punkt-, Textfarben) via `update_geom_defaults()`
- **Schriften** via `systemfonts` + `ragg`

Man kann die Bausteine natürlich auch einzeln verwenden
(`theme_corporate()`, `scale_fill_corporate()`), z. B. für eine einzelne Abbildung.

## Ein Corporate Design definieren (YAML)

Ein Design ist eine YAML-Datei mit Design-Tokens. Beispiel (verkürztes EFK/CD-Bund-Design):

```yaml
meta:
  name: "EFK"
  version: "1.0.0"

colors:
  qualitative: ["#DC0018", "#4D4D4D", "#7A9CC6", "#E8A33D", "#5C8A5C", "#8C6BB1"]
  sequential:  ["#FDE5E7", "#DC0018"]
  diverging:   { low: "#4D6FA9", mid: "#F2F2F2", high: "#DC0018" }
  semantic:
    background: "#FFFFFF"
    text:       "#1A1A1A"
    grid:       "#E6E6E6"
    axis:       "#4D4D4D"
    muted:      "#8C8C8C"
    highlight:  "#DC0018"

typography:
  family:          "Frutiger"
  family_fallback: "Liberation Sans"
  sizes:   { title: 16, subtitle: 12, axis: 10, legend: 10, caption: 8 }
  weights: { title: "bold", body: "regular" }

geometry:
  margin:          { t: 10, r: 15, b: 10, l: 10 }
  grid:            { major_x: false, major_y: true, minor: false }
  legend_position: "top"
  line_width:      0.5

logo:
  path:     "efk.png"
  position: "bottom-right"
  width:    0.12
```

Ist die CD-Schrift (z. B. Frutiger) nicht installiert, fällt das Paket automatisch
auf `family_fallback` zurück und warnt statt zu scheitern.

Für ein **eigenes** Design genügt es, diese Datei zu kopieren, die Werte anzupassen
und den Pfad an `corporate_design()` zu übergeben:

```r
design <- corporate_design("pfad/zu/mein_design.yml")
set_corporate_design(design)
```

## Funktionsübersicht

| Funktion | Zweck |
|---|---|
| `corporate_design(path)` | YAML laden und validieren → Design-Objekt |
| `set_corporate_design(design)` | Design global aktivieren |
| `reset_corporate_design()` | zurück zum ggplot2-Standard |
| `theme_corporate(design)` | Theme für eine einzelne Abbildung |
| `scale_color_corporate()` / `scale_fill_corporate()` | Farbskalen (diskret + kontinuierlich) |
| `corporate_pal(design, type)` | Palettenfunktion (qualitative/sequential/diverging) |
| `finalise_plot(plot, title, source, logo, save_path)` | Logo/Titel/Quelle setzen + exportieren |
| `add_logo(plot, logo)` | nur Logo auf eine Abbildung legen |

## Roadmap

**v1**
- [x] `corporate_design()` inkl. YAML-Validierung
- [x] `theme_corporate()` und Farbskalen
- [x] `set_corporate_design()` / `reset_corporate_design()` (globales Auto-Apply)
- [x] Schrift-Handling mit Fallback (`systemfonts` + `ragg`)
- [x] `finalise_plot()` / `add_logo()` (Logo + Export)
- [x] Mitgeliefertes EFK-Design (`inst/designs/efk.yml`)

**Später**
- Weitere Bundes-/Ämter-Designs, pkgdown-Website, `vdiffr`-Grafiktests.

## Mitwirken

Konventionen und Zielarchitektur sind in [`CLAUDE.md`](CLAUDE.md) beschrieben.

## Lizenz

MIT © 2026 Orlando Willig – siehe [`LICENSE`](LICENSE).
