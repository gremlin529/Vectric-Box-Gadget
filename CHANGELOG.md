## Changelog

Aenderungen an diesem Gadget-Fork ("Vectric-Box-Gadget_claude"), damit auch nach einer neuen Chat-Sitzung nachvollziehbar bleibt, was wann und warum geaendert wurde.

### 2026-09-22

- **Fix: Nut in Side 1/Side 2 an der End-1-Ecke (vorne) um halbe Materialstaerke verkuerzt**
  Die Nut fuer den Schiebeboden in Side 1/Side 2 lief bisher ueber die gesamte Wandlaenge bis in beide Ecken hinein. An der End-1-Ecke (vorne) ist das nicht noetig, da der Boden dort nur einsitzt statt hindurchzugleiten (das Einschieben passiert an End 2, hinten). Auf Wunsch wird die Nut jetzt an der Vorderseite (End 1) um eine halbe Materialstaerke zurueckgesetzt; an der Hinterseite (End 2) bleibt sie unveraendert voll durchgehend. Fix in `CreateFaces.xlua` (`MakeSideFace`, Nutkontur `groove_x0`/`groove_x1`): welches Ende "vorne" (End 1) ist, haengt von `is_side1` ab (Side 1: linke Seite = End 1 -> `groove_x0` wird um `0.5*thickness` nach innen verschoben; Side 2: rechte Seite = End 1 -> `groove_x1` wird um `0.5*thickness` nach innen verschoben), analog zur bestehenden `makeTabsForLeftFace`/`makeTabsForRightFace`-Zuordnung.

### 2026-09-21

- **Feature: "Bottom aus gleichem Material" bei Grooved-Boden**
  Neue Checkbox "Same material (rabbet 3 sides)" fuer Bottom Type = Grooved: der Bodenpanel wird aus der vollen (gleichen) Materialstaerke wie die Waende gefertigt statt aus einem duenneren Einlege-Boden. Dazu wird an den 3 genuteten Kanten (Side 1, Side 2, End 1) ein Falz gefraest, der das Panel auf die Nutbreite herunterbringt; End 2 bleibt auf voller Dicke, da der Boden dort eingeschoben wird. Zwei neue Feinjustage-Felder: "Groove clearance" ("Luft", verkuerzt wie weit das Panel in die 3 Nuten hineinreicht, fuer leichteren Schiebesitz) und "Rabbet correction" (Korrektur der Falztiefe). Umsetzung in `CreateFaces.xlua` (`MakeBottomFaceContour`: `rabbet_contours`/`rabbet_depth` je Face, neue Funktion `CreateBottomRabbetToolpath`), `Simple_Box_Creator_dev.lua` (neue Optionen `bottomSameMaterial`, `bottomGrooveClearance`, `bottomRabbetDepthCorrection`, neuer Toolpath-Aufruf), `DisplayDialog.xlua` (Dialogfelder, Validierung, Registry-Persistenz) und `Simple_Box_Creator_dev.html` (eigener vollbreiter Abschnitt "Bottom Type: Grooved Options", analog zu "Side Top Overhang").

- **Fix: Bodenpanel-Groesse bei Grooved-Boden (Breite/Tiefe und Anlage an End 2)**
  Die Bodenpanel-Abmessung auf der End1/End2-Achse hat eine volle Materialstaerke gefehlt: da End 2s eigenes Wandmaterial unterhalb der Nut weggeschnitten ist (Einschubseite), liegt dort nichts an, woran das Panel innen anstossen koennte - es laeuft tatsaechlich bis zur Aussenkante von End 2 durch und liegt dort voll auf. Fix in `CreateFaces.xlua` (`MakeBottomFaceContour`: `panel_width` um eine zusaetzliche `thickness` erweitert). Die Formel auf der Side1/Side2-Achse ("Laden Breite") war bereits korrekt (2x Nuttiefe, 2x Clearance) und wurde nicht veraendert. Nutzer-getestet und bestaetigt ("bodengroesse passt").

- **Fix: "Groove offset" misst jetzt bis zur Oberkante statt zur Unterkante der Nut**
  `bottomGrooveOffset` bezog sich bisher auf die Unterkante der Nut; auf Wunsch bezieht er sich jetzt auf die Oberkante (entspricht der Skizze im Dialog). Betroffen: die Nutgeometrie in Side 1/Side 2 (`MakeSideFace`) und End 1 (`MakeEndFace`) wird jetzt aus der Oberkante rueckwaerts (minus Nutbreite) berechnet; die Berechnung, wieviel Material End 2 unten verliert (`EndGrooveShortfall`, `bottom_thickness`), braucht kein `+ Nutbreite` mehr, da der Offset das jetzt schon direkt ist; der Standardwert wurde von 0.25 auf `0.25 + Nutbreite` angehoben, damit die Nut nicht unter die Unterkante der Wand rutscht; neue Validierung in `DisplayDialog.xlua` prueft, dass Offset >= Nutbreite ist. Umsetzung in `CreateFaces.xlua`, `Simple_Box_Creator_dev.lua`, `DisplayDialog.xlua`.

- **Fix: Falzbreite am Bodenpanel wurde faelschlich um die Groove clearance verkuerzt**
  Die Falzfraesung an allen 3 Seiten (End 1, Side 1, Side 2) nutzte bisher dieselbe (um die Clearance/"Luft" verkuerzte) Reichweite wie die Aussenkontur des Panels. Dadurch blieb am Nutgrund ein schmaler Streifen in voller Dicke stehen statt gefalzt zu sein. Fix in `CreateFaces.xlua` (`MakeBottomFaceContour`): die Falzbaender (`r1`/`r2`/`r3`) nutzen jetzt die volle "Groove depth", die Clearance wirkt weiterhin nur auf die Aussenkontur (wie weit der Boden tatsaechlich in die Nut hineinreicht). Nutzer-getestet und bestaetigt.

- **UI: Skizze fuer Grooved-Boden-Optionen**
  Der Dialog zeigt jetzt eine kleine technische Skizze (`Images/GrooveSketch.png`) neben der "Same material"-Checkbox, die den Nut/Falz-Querschnitt mit Masslinien fuer "Groove offset", "Groove clearance" und "Rabbet correction" zeigt (deutsche Beschriftung fett/schwarz, englische Feldnamen grau darunter, passend zur handgezeichneten Vorlage des Nutzers). Eine urspruengliche Fassung mit eingebettetem SVG wurde verworfen, da der Dialog (alter IE7-Browser) kein SVG rendert - stattdessen ein per PIL erzeugtes PNG. "Rabbet correction" wurde nachtraeglich korrigiert: die Massline zeigt jetzt nur noch den kleinen Feinkorrektur-Betrag (Abstand zwischen tatsaechlicher Feder-Unterkante und der gestrichelten Referenzlinie fuer die exakte Passung), nicht mehr die komplette Falztiefe.

- **Fix: Kerbe in Side 1/Side 2 an der Ecke zum Hinterstueck (End 2) bei Grooved-Boden**
  An der Ecke, wo Side 1/Side 2 auf das (bei Grooved-Boden verkuerzte) Hinterstueck End 2 trifft, wurde der Bereich von der Unterkante bis zur Nut-Oberkante bisher als gerade Linie ohne Erreichen der wahren Aussenkante gezogen ("plain margin", siehe `EndGrooveShortfall`) - das erzeugte eine tatsaechliche Kerbe/Aussparung in der Seitenwand selbst, sichtbar als Fehlstelle nach dem Zusammenbau (das Hinterstueck selbst war bereits korrekt). Fix in `CreateFaces.xlua` (`MakeSideFace`, beide `right_shortfall`/`left_shortfall`-Bloecke): die Seitenwand reicht in diesem Bereich jetzt fuer die gesamte Hoehe bis zur wahren Aussenkante hinaus (unverzahntes Vollmaterial, da dort nichts zum Verzahnen vorhanden ist), statt zurueckversetzt zu bleiben. Die Zinkenteilung darueber bleibt unveraendert. Nutzer-getestet an einer gebauten Lade und bestaetigt (an den Box-Zinken; Kerbe war dort vorher sichtbar).

### 2026-09-20

- **Feature: Unabhaengige End-Hoehe fuer Front und Back bei "Englischer Zug"**
  Bisher hatte der seitliche Ueberstand ("Englischer Zug", Lid Type = None) nur eine gemeinsame End-Hoehe fuer beide Stirnseiten. Jetzt lassen sich End Height Front (End 1) und End Height Back (End 2) unabhaengig voneinander einstellen. Umsetzung in `CreateFaces.xlua` (`MakeSideFace`: `corner_height_left`/`corner_height_right`, `num_flaps_side_left`/`_right`, `tab_space_side_left`/`_right`), `Simple_Box_Creator_dev.lua` (Optionen `end1Height`/`end2Height`) und `DisplayDialog.xlua`/HTML (getrennte Felder "End height (Front)"/"End height (Back)").

- **Feature: Chamfer als Winkel statt als Breite**
  Die Fase des Ueberstands ("Englischer Zug") wird jetzt ueber einen Winkel (Grad von der Senkrechten, 1-89 Grad) definiert statt ueber eine feste Breite, und ebenfalls getrennt fuer Front/Back (`end1ChamferAngle`/`end2ChamferAngle`, Standard je 45 Grad = alte symmetrische Fase). Die Fasenbreite wird daraus berechnet (Ueberstand * tan(Winkel)). Umsetzung in `CreateFaces.xlua`, `Simple_Box_Creator_dev.lua`, `DisplayDialog.xlua` (Validierung: 0 < Winkel < 90, plus Pruefung dass beide Fasen zusammen nicht breiter als die Innenbreite sind) und HTML (Felder "Chamfer angle (Front)"/"(Back)").

- **Fix: Zinkenversatz von 2,7 mm bei Grooved-Boden + kurzer Nachbarhoehe (`Dovetails.xlua`, `ComputeFingerTrim`)**
  Die Schleife zum Weglassen eines Fingers griff nur, wenn der fehlende Rest (Shortfall) mindestens `tab_space + min_width` betrug. Lag der Shortfall knapp darunter (z.B. 14 mm bei tab_space=11,25/min_width=15), wurde der Rest stillschweigend verworfen und die Zinkenteilung um genau diesen Betrag verschoben. Fix: Schleifenbedingung korrigiert, sodass auch teilweise Shortfalls korrekt im letzten Feld (edge_gap) beruecksichtigt werden.

- **Fix: Zinkenversatz um eine volle Teilung (26,3 mm) nach dem ersten Fix (`CreateFaces.xlua`, `MakeSideFace`)**
  Nach dem Fix oben kam ein zweiter, bis dahin verdeckter Fehler zum Vorschein: der Trimm-Rand fuer die an die Nut angrenzende Ecke wurde am falschen Ende der Zinkenreihe platziert (am oberen statt am unteren/nutseitigen Ende). Dadurch verschob sich die gesamte Zinkenteilung um eine volle Rastereinheit, sobald tatsaechlich ein Finger weggelassen wurde. Fix: Trimm-Rand (Shortfall + edge_gap) wird jetzt zuerst gezeichnet, direkt an der Nutseite, wie bei End 2 selbst. Nutzer-getestet und bestaetigt.

- **UI: Chamfer-Winkel-Feld neben End-Hoehe-Feld**
  Im HTML-Dialog stehen "Chamfer angle (Front)"/"(Back)" jetzt jeweils in derselben Zeile neben "End height (Front)"/"(Back)" statt darunter (`Simple_Box_Creator_dev.html`, `.clearfix`-Wrapper mit zwei nebeneinander schwebenden `.field-row`-Boxen).

- **UI: Farbschema auf Gruen umgestellt**
  Das komplette Farbschema (`stylesheets/layout-css-8.css`, hell und dunkel) wurde von Blau auf Gruen umgestellt - Akzentfarben (Section-Header, Tool-Picker, Sub-Panel-Titel, Type-Panel-Header) ebenso wie die dezenten Hintergrund-/Grautoene. Der Akzentgruenton wurde danach auf Wunsch eine Nuance dunkler gesetzt (`#22AA55` -> `#1C8F47`).

### 2026-09-19

- **Fix: Zinkengroesse an der Grooved-Ecke (Side/End) bei "Englischer Zug"**
  Bei kombinierter Nutzung von Bottom Type = Grooved (Schiebeboden) und Side Top Overhang ("Englischer Zug") stimmte die Zinkenteilung an der Ecke zu End 2 nicht. Ursache: die Zinkenteilung wurde aus der tatsaechlichen (durch die Nut verkuerzten) Hoehe berechnet statt aus einer einheitlichen Referenzhoehe. Fix in `CreateFaces.xlua` (`MakeSideFace`, `MakeEndFace`) und `Dovetails.xlua` (`ComputeFingerTrim`, `*TrimEnd`-Varianten): die Zinkenteilung wird jetzt immer aus der Referenzhoehe berechnet, der fehlende Rest (Shortfall) wird als eigenes, randseitiges Blindstueck neben der Nut abgeschnitten.

- **Fix: Sprachunabhaengige Sheet-Erkennung**
  Das Gadget suchte bisher nach dem hart codierten englischen Sheet-Namen "Sheet 1"/"Sheet N", was auf einer deutschen VCarve-Installation ("Seite 1") nicht gefunden wurde. Fix in `SheetArrangement.xlua`: Sheets werden jetzt ausschliesslich ueber ihre ID (`job.SheetManager:GetSheetIds()` / `ActiveSheetId`) gesucht/erstellt/aktiviert, unabhaengig von der angezeigten (lokalisierten) Bezeichnung.

- **Fix: Keine Nut bei End 1, wenn Joint Type = Dovetail**
  Bei Bottom Type = Grooved wurde bisher immer eine Nut in End 1 gefraest (als fester Anschlag fuer den Schiebeboden). Bei Dovetail-Zinken kollidiert diese Nut mit den schraegen Schwalbenschwanz-Zinken an dieser Kante. Fix in `CreateFaces.xlua` (`MakeEndFace`): die Nut wird bei End 1 nur noch gefraest, wenn Joint Type = Box ist; bei Dovetail entfaellt sie komplett.

- **Verfeinerung: Gestoppte Nut bei End 1 (nur Joint Type = Box)**
  Die Nut in End 1 lief bisher komplett von Kante zu Kante durch die Zinkenbereiche. Auf Wunsch endet sie jetzt links und rechts jeweils eine halbe Materialstaerke vor der Kante, sodass an den Ecken ein durchgehender Materialsteg stehen bleibt statt die Nut bis in die Zinkenluecke zu ziehen.

### Vor dem 19.09.2026 (rueckwirkend rekonstruiert)

Diese Aenderungen liegen vor dem Beginn dieser Changelog-Datei und wurden damals nicht dokumentiert. Der urspruengliche Chatverlauf aus dieser Zeit liegt nicht mehr vor; die folgenden Punkte wurden daher nachtraeglich durch einen Code-Vergleich zwischen dem oeffentlichen Original-Repo (github.com/gremlin529/Vectric-Box-Gadget) und dem aktuellen Stand dieses Ordners rekonstruiert - nicht aus dem tatsaechlichen Gespraech. Datierung und Reihenfolge stuetzen sich vor allem auf "by Claude <Datum>"-Kommentare im Code selbst; wo das nicht eindeutig war, ist es unten als Vorbehalt vermerkt.

- **Feature: Neuer Bottom-Typ "Grooved" (Schiebeboden) - Kerngeometrie**
  Das Original-Repo kennt fuer den Boden nur die Typen Inset/Fingers/Flat/None; ein Schiebeboden existiert dort nicht. Der Fork fuegt einen fuenften Typ `FaceJointType.Grooved` hinzu: In Side 1, Side 2 und End 1 wird eine einfache Nut (Dado) nahe der Unterkante in die Wand gefraest; End 2 bleibt bewusst ungenutet, damit der Bodenpanel nach dem Verleimen der uebrigen Teile von hinten eingeschoben werden kann. Der Bodenpanel selbst ist bei diesem Typ ein schlichtes Rechteck ohne Finger/Zinken, dessen Groesse sich aus der Nuttiefe ergibt. Umsetzung in `CreateFaces.xlua`: neuer Eintrag `FaceJointType.Grooved`, ein eigener Rueckgabezweig in `MakeBottomFaceContour` fuer den reinen Panel-Umriss, sowie `groove_contours` als neues Feld auf dem `Face`-Objekt, das in `MakeSideFace` (Side 1/Side 2) und `MakeEndFace` (End 1) mit der jeweiligen Nutkontur befuellt wird. Durchgehend mit "by Claude 9/18/2026" markiert. Alle spaeteren Korrekturen daran (Zinkengroesse an der Ecke, sprachunabhaengige Sheets, keine/gestoppte Nut bei Dovetail bzw. bei End 1, Groove-offset-Bezug, "Bottom aus gleichem Material", Bodenpanel-Groesse, Kerbe an der Ecke, Nutverkuerzung an End 1) sind bereits ab dem 19.09.-Eintrag oben dokumentiert.

- **Feature: Grooved-Boden - Dialog-Integration, Registry und eigener Fraes-Toolpath**
  Ergaenzend zur Nutgeometrie: eine neue Funktion `CreateGroovePocketToolpath` in `CreateFaces.xlua`, die alle `groove_contours` eines Sheets sammelt und als eigenen Fraes-Durchgang abarbeitet; in `Simple_Box_Creator_dev.lua` die neuen Optionen `bottomGrooveOffset`/`bottomGrooveDepth`/`bottomGrooveWidth` samt Defaultwerten und Einheiten-Umrechnung; in `DisplayDialog.xlua` die drei zugehoerigen Zahlenfelder, eine erste Validierung sowie Speichern/Laden in der Registry; und in `Simple_Box_Creator_dev.html` der neue Dropdown-Eintrag "Grooved" fuer Bottom Type samt Ein-/Ausblend-Logik. Ebenfalls durchgehend "by Claude 9/18/2026". Die feinere Ausgestaltung (Same material/Groove clearance/Rabbet correction, die Skizze, der geaenderte Bezugspunkt des Offsets) kam erst ab 20./21.09. dazu und ist dort bereits dokumentiert.

- **Robustheit: Auffangen eines ungueltigen Lid-/Bottom-Type-Dropdownwerts**
  In `DisplayDialog.xlua` faengt `GetOptionsFromDialog` jetzt einen unbekannten Dropdown-Wert fuer Lid Type/Bottom Type ab und faellt auf einen Default zurueck (Inset bzw. Fingers), statt die Option stillschweigend auf `nil` zu lassen, was spaeter zu einem schwer nachvollziehbaren Laufzeitfehler gefuehrt haette. Mit "by Claude 9/18/2026" markiert, direkt neben den neuen Grooved-Feldern eingefuehrt.

- **Feature, mit Vorbehalt: "Englischer Zug" - erste Fassung des seitlichen Ueberstands mit Fase**
  Auch dieses Konzept (seitlicher Ueberstand mit Fase) kommt im Original-Repo nirgends vor. Der Changelog-Eintrag vom 20.09. beschreibt seine dortige Aenderung ausdruecklich als Erweiterung einer bereits vorhandenen Funktion ("Bisher hatte der seitliche Ueberstand [...] nur eine gemeinsame End-Hoehe fuer beide Stirnseiten") - es muss also schon vorher eine erste, einfachere Fassung mit EINER gemeinsamen End-Hoehe gegeben haben. Diese urspruengliche Fassung wurde am 20.09. jedoch direkt durch die neue End1Height/End2Height- und Winkel-basierte Version ersetzt und ist im heutigen Code nicht mehr getrennt sichtbar; ob sie noch vor dem 19.09. oder erst am 19.09. selbst entstand, laesst sich aus dem Diff allein nicht sicher sagen (der zugehoerige HTML-Abschnitt traegt bereits ein 9/19-Datum). Deshalb hier nur mit Vorbehalt aufgefuehrt.

### Hinweis zur Nachvollziehbarkeit

Diese Datei wird bei zukuenftigen Aenderungen fortgeschrieben. Der eigentliche Chat-Verlauf bleibt zusaetzlich in der Cowork-Sitzungshistorie erhalten und kann bei Bedarf dort erneut aufgerufen werden; diese Datei dient als kompakte technische Zusammenfassung direkt im Gadget-Ordner. Der Abschnitt "Vor dem 19.09.2026" oben ist eine nachtraegliche Rekonstruktion aus einem Code-Vergleich, kein Original-Protokoll.
