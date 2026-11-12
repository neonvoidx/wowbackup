# EnhanceQoL Roadmap

## Hohe Priorität

- [x] **Eigene Aura-Einstellungen für Pet-Frames — lokal umgesetzt**
  - **Aufgenommen:** 2026-11-10; hohe Priorität auf Wunsch von Philipp.
  - **Ziel:** Auren auf Gruppen-Pet-Frames unabhängig von den Party-Frames konfigurieren können, insbesondere Größe und Position passend zur eigenen Pet-Framegröße.
  - **Anlass:** LucyON berichtet in Forever, dass Pet-Frames die Aura-Einstellungen der Party-Frames übernehmen. Bei unterschiedlich großen Frames passt die Darstellung dadurch nicht. Die gemeinsame Aura-Konfiguration wurde in den Laufzeitpfaden aller drei Clients bestätigt.
  - **Umsetzung (2026-11-11):** Im Edit Mode unter „Party pet frames“ eigene Aura-Einstellungen aktivieren. Separate Tabs für Buffs, Debuffs und Externals verwenden dieselben Aura-Steuerelemente mit unabhängiger Speicherung. Beim ersten Aktivieren werden die aktuellen Party-Einstellungen kopiert; bestehende Profile behalten bis dahin ihre Vererbung. Deaktivieren stellt die Vererbung wieder her und behält die eigenen Werte für später.
  - **Clients:** Retail, Forever und TBC lokal umgesetzt, einschließlich Live-Auren, Vorschau, Layoutspeicherung und Tab-Resets. Code-/Modelltests bestanden. Philipp bestätigt am 2026-11-11, dass die Änderung ingame funktioniert; der getestete Client wurde nicht benannt.
  - **Abnahme:** Unterschiedliche Größen von Party- und Pet-Frames testen; Änderungen an Pet-Auren dürfen die Party-Auren nicht verändern. Bestehende Profile sowie Buffs und Debuffs berücksichtigen.
  - **Quelle:** [Discord – LucyON, forever-general](https://discord.com/channels/794661593480691723/1550238236972941484/1569826127428591776).
