# CLAUDE.md — Arbeitsanweisung für `CorporateDown`

Diese Datei richtet sich an Claude-Sessions, die an diesem Repository arbeiten.
Sie beschreibt Zweck, Zielarchitektur, Konventionen und Build-Befehle des Pakets.

## Was ist `CorporateDown`?

`CorporateDown` ist ein R-Package, mit dem man **ein Corporate Design einmalig
definiert** (Farben, Schriften, Grössen, Logo) und danach **alle Abbildungen mit
ggplot2 automatisch in diesem Design** erstellt werden.

**Kernidee — „set once, apply everywhere":** Nach einem einzigen Aufruf
(`set_corporate_design(...)`) erscheint ganz normaler ggplot-Code ohne weitere
Theme- oder Skalen-Aufrufe im Corporate Design.

Referenz- und Testfall ist das **CD Bund** (Corporate Design der Schweizerischen
Bundesverwaltung), konkret die Abbildungen der **EFK** (Eidgenössische
Finanzkontrolle): Bundesrot `#DC0018`, Schrift Frutiger. Das entsprechende Design
wird als `inst/designs/efk.yml` mitgeliefert.

## Getroffene Grundsatzentscheidungen

- **Design-Input:** deklarative **YAML-Datei** mit Design-Tokens ist die Single
  Source of Truth. Ein R-Konstruktor lädt/validiert diese Datei.
- **Schriften:** **systemfonts + ragg**. Installierte Fonts (z. B. Frutiger)
  werden registriert; fehlt die CD-Schrift, wird sauber auf eine freie Alternative
  (Liberation Sans / Arial) zurückgefallen — mit Warnung, ohne Fehler.
- **Umfang v1:** Kern (Theme + Skalen + globales Auto-Apply) **plus Logo/Export**
  (`finalise_plot()` / `add_logo()` im Stil von BBC `bbplot`).
- **Paketname:** `CorporateDown`.

## Wie „automatisch" funktioniert (idiomatische ggplot2-Mechanismen)

`set_corporate_design()` registriert das Design global über die dafür vorgesehenen
ggplot2-Mechanismen. Beim Implementieren diese nutzen — kein Monkeypatching:

- `ggplot2::theme_set(theme_corporate(design))` — setzt das Default-Theme.
- `options(ggplot2.discrete.colour = , ggplot2.discrete.fill = ,`
  `ggplot2.continuous.colour = , ggplot2.continuous.fill = )` — setzt Default-Skalen,
  sodass ohne expliziten `scale_*()`-Aufruf die CD-Palette greift.
- `ggplot2::update_geom_defaults()` — Default-Farbe/Schrift für einzelne Geome
  (`"col"`, `"bar"`, `"line"`, `"point"`, `"text"`, `"label"` …).
- `systemfonts::register_font()` / `register_variant()` + ragg-Grafikdevice für die
  Typografie.

`reset_corporate_design()` macht all das rückgängig (vorherige Options/Theme sichern
und wiederherstellen).

## Zielarchitektur (Paketstruktur)

```
CorporateDown/
├── DESCRIPTION            # Metadaten, Imports (roxygen2-gepflegt)
├── NAMESPACE              # von roxygen2 generiert — NICHT von Hand editieren
├── LICENSE                # MIT (bereits vorhanden)
├── CLAUDE.md              # diese Datei
├── README.md
├── R/
│   ├── design.R           # corporate_design(): YAML laden + validieren -> S3-Objekt
│   ├── fonts.R            # register_design_fonts(): systemfonts + Fallback-Logik
│   ├── theme.R            # theme_corporate(): ggplot2-Theme aus Design-Tokens
│   ├── scales.R           # corporate_pal(), scale_color/fill_corporate() (diskret+kontinuierlich)
│   ├── apply.R            # set_corporate_design() / reset_corporate_design()
│   └── finalise.R         # finalise_plot(), add_logo(): Logo/Titel/Quelle + Export
├── inst/
│   ├── designs/
│   │   └── efk.yml        # mitgeliefertes EFK/CD-Bund-Design (Referenz + Test)
│   └── logos/             # Logo-Assets (PNG/SVG)
├── man/                   # von roxygen2 generiert
├── tests/
│   └── testthat/          # Unit-Tests
└── vignettes/             # Einführung + eigenes CD definieren
```

## Design-Objekt / YAML-Tokens

Ein Design (S3-Klasse `corporate_design`) entspricht 1:1 der YAML-Struktur:

- `meta`: `name`, `version`
- `colors`:
  - `qualitative`: kategoriale Palette (Vektor von Hex-Werten)
  - `sequential`: Endpunkte/Stufen für kontinuierliche Skalen
  - `diverging`: Low/Mid/High für divergierende Skalen
  - `semantic`: `background`, `text`, `grid`, `axis`, `muted`, `highlight`
- `typography`: `family`, optional `family_fallback`, Grössen (`title`, `subtitle`,
  `axis`, `legend`, `caption`), Gewichte
- `geometry`: Ränder/`margin`, Grid-Linien (welche an/aus), `legend_position`,
  Basis-Linienstärke
- `logo`: `path`, `position`, `width`

`corporate_design()` validiert Pflichtfelder und Hex-Codes und gibt hilfreiche
Fehlermeldungen (`cli`) aus.

## Öffentliche API (Zielbild)

| Funktion | Zweck |
|---|---|
| `corporate_design(path)` | YAML laden/validieren → `corporate_design`-Objekt |
| `theme_corporate(design, ...)` | ggplot2-Theme aus dem Design |
| `corporate_pal(design, type)` | Palettenfunktion (qualitative/sequential/diverging) |
| `scale_color_corporate()` / `scale_fill_corporate()` | diskrete + kontinuierliche Skalen |
| `set_corporate_design(design)` | Design global aktivieren (Theme + Optionen + Geom-Defaults + Fonts) |
| `reset_corporate_design()` | globalen Zustand zurücksetzen |
| `register_design_fonts(design)` | Fonts registrieren, Fallback-Logik |
| `finalise_plot(plot, title, source, logo, save_path, ...)` | Logo/Titel/Quelle platzieren + exportieren |
| `add_logo(plot, logo, ...)` | nur Logo auf Plot legen |

## Konventionen

- **Doku & NAMESPACE:** roxygen2. `NAMESPACE` und `man/` nie von Hand editieren —
  nach Änderungen `devtools::document()` laufen lassen.
- **Tests:** testthat (Edition 3). Für Grafik-Regression optional `vdiffr`.
- **Stil:** tidyverse-Style-Guide; snake_case für Funktionen/Argumente.
- **Abhängigkeiten (Imports):** `ggplot2`, `systemfonts`, `ragg`, `yaml`,
  `scales`, `cli`, `grid`. Für Logo/Export ggf. `magick` und/oder `patchwork`/`cowplot`.
  Neue Deps sparsam und über `usethis::use_package()` aufnehmen.
- **Datenfluss:** YAML ist die einzige Quelle der Wahrheit; R-Code leitet Theme,
  Skalen und Geom-Defaults deterministisch daraus ab.

## Build- & Check-Befehle

```r
devtools::load_all()    # Paket interaktiv laden
devtools::document()    # roxygen -> man/ + NAMESPACE
devtools::test()        # Tests
devtools::check()       # R CMD check (vor jedem Commit größerer Änderungen)
```

Schneller manueller Rauchtest mit dem EFK-Design:

```r
devtools::load_all()
set_corporate_design(corporate_design(system.file("designs/efk.yml", package = "CorporateDown")))
library(ggplot2)
ggplot(mpg, aes(class, fill = drv)) + geom_bar()   # sollte im EFK-CD erscheinen
```

## Git-Workflow

- Entwicklung auf dem zugewiesenen Branch
  `claude/r-package-corporate-design-ggplot-oj8126`.
- Klare Commit-Messages; Push mit `git push -u origin <branch>`.
- **Keinen Pull Request öffnen**, außer der User verlangt es ausdrücklich.
