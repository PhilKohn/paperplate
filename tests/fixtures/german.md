---
title: "Beispielarbeit auf Deutsch"
subtitle: "Zitate, Abbildungen und Verzeichnisse"
author: "Max Mustermann"
supervisor: "Prof. Dr. Erika Musterfrau"
institution: "Beispiel-Universität"
faculty: "Fakultät für Beispiele"
degree: "Bachelorarbeit"
student-id: "1234567"
date: auto
show-word-count: true
lang: de
keywords: [Reproduzierbarkeit, Satz, Markdown]
abstract: |
  Diese Beispielarbeit prüft die deutsche Ausgabe: Verzeichnisse, Beschriftungen
  und die Eigenständigkeitserklärung.
acknowledgements: |
  Danke an alle, die Entwürfe gelesen haben.
---

# Einleitung {#sec:einleitung}

Reproduzierbare Arbeitsweisen verbinden Quelltext und Ergebnis [@knuth1984]. In
@sec:ergebnisse stehen eine Abbildung und eine Tabelle.

# Ergebnisse {#sec:ergebnisse}

@fig:ablauf zeigt den Ablauf, @tbl:werte die Werte und @eq:mittel die Definition des
Mittelwerts.

![Vom Markdown zum PDF.](figures/pipeline.svg){#fig:ablauf width=100%}

| Name | Wert |
|:-----|-----:|
| A    |   42 |
| B    |   67 |

: Beispielwerte. {#tbl:werte}

$$ \bar{x} = \frac{1}{n} \sum_{i=1}^{n} x_i $$ {#eq:mittel}

Sätze mit Umlauten: Übung, Größe, Straße.
