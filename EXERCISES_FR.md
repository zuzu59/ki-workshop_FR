# Exercices – Travailler avec l'agent de codage sur le gPlug

📄 [Cet exercice en PDF (A4)](docs/EXERCISES_FR.pdf) · [Terminologie : LEGENDE_FR.md](LEGENDE_FR.md)

Ces exercices portent sur le **cycle de travail avec l'agent** : fournir le contexte → formuler une tâche petite et vérifiable → charger le code sur l'appareil → consulter la console → rapporter les erreurs textuellement. L'application Berry `app/spot.be` sert uniquement de support à l'exercice. Les exercices modifient uniquement l'affichage, jamais le flux de données ; en cas d'erreur, le cœur de l'application reste intact.

Bases : `AGENTS_FR.md` (règles et outils, lus automatiquement par l'agent), `TASMOTA_BERRY_API_FR.md` (l'API Tasmota ; sans elle, l'agent doit deviner), `SETUP_OPENCODE_FR.md` §7 (fonctionnement de l'agent).

## Aperçu : du point de départ à l'application finale en 4 étapes, plus une étape 5

Dans un conteneur Docker, les participants disposent d'un **point de départ** (*starter*) et développent l'interface graphique en quatre étapes pour aboutir au résultat visuel cible : `docs/zielbild.jpg`. L'étape 5, destinée aux utilisateurs avancés, va plus loin : elle propose une vue sur 2 jours avec des intervalles de 15 minutes, au lieu de 3 jours avec des valeurs horaires.

| Étape | Objectif | Résultat visible | Objectif pédagogique (IA) |
|---|---|---|---|
| 0 Starter | – | Courbe des prix, 1 jour, intervalles de ¼ h | – |
| 1 Barres d'énergie | Injection par ¼ h (barres vertes), axe kWh dédié à gauche | Courbe solaire sous la courbe des prix | Fournir le contexte : indiquer le point d'extension et la source de données |
| 2 Prix négatifs | Barres orange si prix < 0, zone sous 0 Rp. ombrée, légende | Mise en évidence du creux de midi | Petite tâche vérifiable ; définir un cas de test (ex : creux de la mi-journée < 0) |
| 3 3 jours, valeurs horaires | Axe X : 72 h, noms des jours, repères 00/12 ; heure = moyenne (prix) ou somme (énergie) | Jeu–Sam : conforme au résultat visé | Refactoriser plutôt qu'ajouter ; mesurer l'utilisation du tas (heap) avant/après |
| 4 Graphique de rémunération | Second graphique en dessous : CHF/h (jaune/rouge), Σ sur 3 jours | Résultat visé complet | S'appuyer sur le travail précédent ; privilégier la réutilisation |
| 5 2 jours, pas de ¼ d'heure | 192 valeurs (¼ h) : hier + aujourd'hui, basées sur les prix (demain inclus) ; prix représentés en escalier | Pics de prix visibles au sein de l'heure | Utiliser des constantes plutôt que des nombres ; mesurer les coûts (octets, ms, tas) |

- Chaque étape est visible dans l'interface web (WebUI) et fonctionnelle de manière autonome. Les étapes 1 et 2 ne modifient qu'une seule journée
(rapide et léger) ; l'étape 3 constitue une refonte, et l'étape 4 s'appuie sur la 3. Les étapes 1 et 2 restent valides même si l'étape 3 échoue.
- **Obligatoire : étapes 1 et 2. Étapes 3 et 4 pour les plus rapides. Étape 5 pour les avancés**
(s'appuie sur l'étape 4 et modifie le résultat visé). Temps imparti pour cet exercice : 45 min.
- **Points de contrôle (Checkpoints)** : les fichiers `app/steps/spot_1.be` à `spot_5.be` contiennent l'état final de chaque étape. 
En cas de blocage, copiez le point de contrôle précédent vers `app/spot.be` pour poursuivre le travail
(`cp app/steps/spot_2.be app/spot.be && ./upload.sh app/spot.be`). 

### Starter (Étape 0)

![Starter : uniquement la courbe des prix, 1 jour](docs/steps/schritt_0.png)

Données complètes, affichage minimaliste :

- En arrière-plan : récupération des prix (F1), compteur avec simulateur incluant une accélération temporelle, `Po` et jours précédents renseignés (F2), fichier CSV journalier (F4), `SpotPrices` (F5). La mémoire conserve les prix et l'énergie sur **3 jours**.
- Lignes de texte au-dessus du graphique : prix spot actuel, injection aujourd'hui, rémunération aujourd'hui. Cela permet de visualiser les données avant même qu'elles ne soient tracées ; l'étape 1 peut être vérifiée via la valeur « Injection aujourd'hui ».
- Graphique : **uniquement la courbe des prix** (cyan, `COL_PRICE`), sur 1 jour avec 96 valeurs par quart d'heure, axe en Rp./kWh à droite, ligne zéro, repère « maintenant » (gris), légende générée par `chart_curves()`. Couleurs identiques à l'image finale ; `COL_ENERGY` (vert), `COL_NEG` (orange), `COL_PAY` (jaune) et `COL_COST` (rouge) sont déjà définies.
- Le simulateur intègre une baisse des prix à la mi-journée, avec des tarifs négatifs (cas de test pour l'étape 2).
- Utilitaires disponibles : `chart_curves()`, `send_polyline(...)`, `value_range(...)`, `nice_range(...)` (pour des graduations d'axe arrondies), `y_scale(...)`, `send_data_attr(...)` (valeurs pour le curseur), constantes de couleur `COL_...`, accès aux données via `self.store.price(key, slot)` (en 1/10 000 CHF/kWh) et `self.store.energy_at(key, slot)` (en 0,01 kWh) — une valeur `nil` indique une donnée manquante. 
- Commentaires `# POINT D'EXTENSION Étape 1` … `Étape 4` au début de `F3 Chart` ; chaque
point de contrôle ne contient plus que les éléments correspondant aux étapes en cours.
- Script du curseur identique à toutes les étapes : il affiche chaque valeur présente (`data-p`, `data-e`,
`data-v`) et calcule la durée à partir de `data-m` (15 ou 60 min). Aucune étape ne modifie ce script.

## Préparation (5 min)

1. Vérifier l'adresse IP de l'appareil (indiquée dans le RUNBOOK, étape 6.1). Résultat attendu : l'adresse IP, par ex. `192.168.1.50`. 
```sh
cat .gplug
```
2. L'appareil répond ; on attend un JSON contenant `"Sim":true`. **Notez la valeur de `HeapFree`** (valeur initiale, par ex. 125). 
```sh
./brcmd.sh 'tasmota.cmd("SpotStatus")'
```
3. Laissez l'interface Web (WebUI) du gPlug ouverte dans votre navigateur (`http://192.168.x.y`).
4. Lancez opencode :
```sh
./docker-run.sh
```
Si vous n'utilisez pas Docker (installation native, voir `SETUP_OPENCODE_FR.md`), depuis le dossier du dépôt :
```sh
opencode
```
opencode démarre dans l'agent **build** ; avant la première invite (prompt), basculez sur l'agent **plan** (touche `SHIFT+TAB`, voir
*Déroulement par étape*).

## Déroulement par étape

opencode dispose de deux agents. L'agent actif est indiqué en bas, dans la zone de saisie (`Plan` ou `Build`).
Pour basculer de l'un à l'autre, utilisez la touche **`Tab`** (ou `Maj+Tab`) ; chaque pression permet de passer à l'autre agent. L'historique de la conversation est conservé lors du changement : l'agent build a connaissance du plan.

| Agent | Autorisations | Usage |
|---|---|---|
| **plan** | Lecture seule (aucune modification ni téléversement) | Élaboration du plan |
| **build** | Modification de fichiers, exécution de commandes (après validation) | Mise en œuvre, signalement d'erreurs |

opencode démarre dans l'agent **build**. Chaque étape se déroule comme suit :

1. **Passer à l'agent plan** : appuyez sur `SHIFT+TAB` jusqu'à ce que `Plan` s'affiche en bas.
2. Saisissez la consigne de « planification » pour l'étape en cours et validez. Examinez le plan ; s'il s'écarte des directives (apparition de boucles infinies, cases à cocher, JavaScript, etc.), refusez-le dans l'agent plan, rappelez la consigne initiale et demandez un nouveau plan. Ne poursuivez que lorsque le plan est conforme. 
3. **Passer en mode « build »** : appuyez sur la touche `SHIFT+TAB` jusqu'à ce que « Build » s'affiche en bas.
4. Saisissez et envoyez la consigne « mettre en œuvre » (valable pour toutes les étapes, en bas). Autorisez les commandes shell une par une
(uniquement `./upload.sh`, `./log.sh`, `./brcmd.sh`, `berry`, `cp`, `git`).
5. Signalez toute erreur survenue dans l'agent **build** en utilisant la consigne « signaler l'erreur » (ne changez pas de mode).
6. Effectuez vous-même les étapes de vérification, consultez les résultats dans l'interface web (WebUI) et sauvegardez l'état actuel : faites une copie
`cp app/spot.be spot_etape1.be` (en indiquant le numéro de l'étape) ; si vous maîtrisez `git`, utilisez `git commit`.
7. Étape suivante : recommencez à partir du point 1, en revenant au mode **plan**.

Mnémonique : **planifier = plan, tout le reste = build.** Si, suite à la consigne « mettre en œuvre », l'agent répond uniquement par du texte sans rien modifier, c'est que le mode « plan » est toujours actif : passez en mode « build » et renvoyez la consigne.

### Consigne « mettre en œuvre » (pour toutes les étapes, dans l'agent « build »)

```
Mets en œuvre le plan, dans l'ordre suivant :
1. Modification dans app/spot.be.
2. cd app && berry desktop_harness.be – doit se terminer par « HARNESS OK ».
3. ./upload.sh app/spot.be, puis ./log.sh. Affiche intégralement chaque ligne commençant par « BRY: » ou « SPOT: ».
4. ./brcmd.sh 'tasmota.gc()' et ./brcmd.sh 'tasmota.memory("heap_free")', puis indique la valeur du « heap » (mémoire libre).
Fais un rapport en cinq lignes : ce qui a été modifié, ce qui a été vérifié, et ce qui reste à faire.
Je vérifierai moi-même l'interface web (WebUI).
```

### Invite « Renvoyer l'erreur » (dans l'agent de build)

```
./log.sh affiche, après le téléversement :
<Insérer les lignes telles quelles>
Corrigez uniquement cette erreur, téléversez à nouveau et consultez à nouveau le journal (log).
```

## Étape 1 – Barres d'énergie (Obligatoire, ~20 min)

![Objectif de l'étape 1 : barres d'énergie vertes, axe des kWh à gauche](docs/steps/schritt_1.png)

### Tâche

Le graphique n'affiche actuellement que la courbe des prix. Ajoutez l'**énergie injectée par quart d'heure (kWh) sous forme de barres vertes** derrière la courbe, avec un axe dédié situé à gauche.

Spécifications :

- Source des données : `self.store.energy_at(key, slot)` (unité : 0,01 kWh ; `nil` = absence de donnée, pas de barre).
- Identifiant court : `e` (groupe SVG : `se`), couleur : `COL_ENERGY` (vert).
- Axe situé **à gauche** avec des valeurs en kWh allant de 0 au maximum journalier ; étiquette « kWh » en haut à gauche. Il s'agit du seul nouvel axe ; l'axe des prix situé à droite reste inchangé.
- Entrée « Injection » dans la légende, accompagnée du symbole de barre `&#9632;` ; doit pouvoir être affichée ou masquée, tout comme le prix spot.
- Les barres doivent être dessinées derrière la courbe des prix (la courbe reste au premier plan).
- Utilisez les outils existants (`chart_curves`, `value_range`, `y_scale`). Ne créez pas de nouvelle boucle sur les créneaux (slots) en dehors d'une méthode `send_bars` ; n'ajoutez pas de JavaScript et ne modifiez rien d'autre. 

### Consigne « planifier » (dans plan-Agent, appuyer sur `SHIFT+TAB` jusqu'à ce que `Plan` s'affiche en bas)

```
Consultez @AGENTS.md, @TASMOTA_BERRY_API.md ainsi que la section « F3 Chart » dans @app/spot.be,
repérée par le commentaire « ERWEITERUNGSPUNKT Schritt 1 » (POINT D'EXTENSION Étape 1).

Tâche : Dans le graphique journalier, l'énergie injectée par quart d'heure (en kWh) doit apparaître sous forme de barres vertes, situées derrière la ligne de prix.

Spécifications : Source des données : `self.store.energy_at(key, slot)` (0,01 kWh ; `nil` indique une lacune). Identifiant court : `e`. Couleur : `COL_ENERGY`. Ajoutez un nouvel axe à gauche, gradué en kWh de 0 jusqu'au maximum journalier (cette approche est explicitement autorisée) ; l'axe des prix, situé à droite, doit rester inchangé. Ajoutez une entrée « Einspeisung » (Injection) dans la légende, représentée par le symbole &#9632; et pouvant être affichée ou masquée. Utilisez les outils existants : `chart_curves`, `value_range`, `y_scale`. N'utilisez pas de JavaScript et ne modifiez aucun autre élément.

Élaborez un plan : quellesMéthodes que vous modifiez ou créez, et vérification du résultat
(Desktop-Harness, upload.sh, log.sh, Heap). N'hésitez pas à demander des précisions si un point n'est pas clair. Ne modifiez rien pour l'instant.
```

### Résultat attendu

- Barres vertes représentant la courbe journalière (Simulateur : maximum à 12h40, base de 0,3 kW = 0,075 kWh/¼ h).
- Axe de gauche en kWh ; axe des prix (à droite) inchangé ; légende incluant « Injection ».
- Somme des barres ≈ « Injection aujourd'hui » dans l'en-tête.
- `app/sensor.html` (Harness) contient `<g id='se'>`.

> [!WARNING]
> **Le résultat fourni par l'agent peut être erroné, même si tout indique « OK ».**
> Un message `HARNESS OK`, un journal (log) propre et un graphique avec des barres vertes prouvent seulement que le code s'exécute, **pas qu'il effectue des calculs corrects**. L'agent affirmera « terminé » avec la même assurance, même si les valeurs sont fausses.
>
> Exemple typique : **une échelle incorrecte.**
>
> - Barres tracées selon l'échelle des prix au lieu d'une échelle dédiée aux kWh : 0,075 kWh sur un axe gradué de 0 à 15 ct. donne des barres de 1 à 2 pixels ; le graphique semble alors « presque vide ».
> - Axe de gauche libellé en valeurs brutes (0,01 kWh) : on lit « 30 » au lieu de « 0,30 » kWh.
> - Axe de gauche correctement libellé, mais barres mises à l'échelle avec un maximum différent : la hauteur des barres ne correspond pas au chiffre indiqué sur l'axe.
>
> **Vérifiez par vous-même, ne faites pas aveuglément confiance à l'agent :** La barre la plus haute correspond-elle bien au chiffre indiqué en haut de l'axe des kWh ? > Base ≈ 0,075 kWh ? Total ≈ « Injection aujourd'hui » ? Ligne de prix inchangée ? Si un
> chiffre est incorrect : signaler l'erreur à l'agent en précisant les valeurs concernées.

## Étape 2 – Mettre en évidence les prix négatifs (Obligatoire, ~15 min)

![Objectif Étape 2 : barres orange lorsque le prix < 0, zone sous 0 ombrée](docs/steps/schritt_2.png)

### Tâche

L'injection d'énergie lorsque le prix est négatif entraîne un coût. Rendez cela visible : **barres en orange si le prix dans
l'intervalle (slot) est < 0**, et **zone en dessous de 0 Rp. ombrée** avec la mention « prix négatif ».

Consignes :

- Couleur `COL_NEG` (orange) pour les barres où `self.store.price(key, slot) < 0` ; sinon, `COL_ENERGY`.
- Ombrage : un rectangle allant de la ligne zéro jusqu'au bord inférieur, semi-transparent, placé en arrière-plan. 
À afficher uniquement si la journée comporte des prix négatifs (l'axe des prix descend alors en dessous de 0).
- Entrée dans la légende : « Injection à prix < 0 » en orange.
- Cas de test : en mode simulation, la journée actuelle présente une baisse à la mi-journée avec des prix négatifs (la ligne de prix
dans le graphique passe sous 0). Ne pas se baser sur `SpotPrices` : cela n'affiche que les 10 prochaines heures ; le soir, la baisse de la mi-journée est déjà passée.

### Prompt « planifier » (dans l'agent `plan`, appuyer sur `SHIFT+TAB` jusqu'à ce que `Plan` s'affiche en bas)

```
Consultez la section « F3 Chart » dans le fichier @app/spot.be, repérée par le commentaire « ERWEITERUNGSPUNKT Schritt 2 ».

Tâche : Afficher les barres d'énergie en orange (`COL_NEG`) au lieu de vert pour les intervalles (slots) où le prix est négatif.
Appliquer une ombre semi-transparente sous la ligne zéro, accompagnée du texte « prix négatif », uniquement si la journée comporte des prix négatifs. Ajouter une entrée de légende « Injection à prix < 0 » en orange.

Ne rien modifier d'autre. Indiquez dans votre plan comment vous vérifiez que les barres orange apparaissent précisément lorsque le prix est négatif (le simulateur génère actuellement un creux < 0 à la mi-journée). Ne procédez à aucune modification pour le moment.
```

### Résultat attendu

- Barres orange situées exactement là où la courbe des prix passe sous 0 (Sim : creux à la mi-journée).
- Ombrage présent uniquement si la journée contient des prix négatifs ; dans le cas contraire, le graphique doit rester identique à celui obtenu à l'étape 1.

## Étape 3 – 3 jours avec des données horaires (pour les plus rapides, ~20 min)

![Objectif étape 3 : 3 jours avec des données horaires et les noms des jours](docs/steps/schritt_3.png)

### Tâche

Le graphique affiche **les 3 jours stockés en mémoire** (tampon circulaire, le plus ancien à gauche ; à partir de ~17h, le jour le plus récent correspond au lendemain) **avec des données horaires**, remplaçant la vue sur une seule journée avec des données au quart d'heure.

Spécifications :

- 72 valeurs. Données horaires : prix = **moyenne**, énergie = **somme** des 4 quarts d'heure. Si les 4 valeurs sont manquantes : laisser un vide. Les données horaires doivent être calculées **une seule fois par appel** de `page_svg` (gestionnaire `/spot.svg`) via `fill_hours(start)` et stockées dans des tampons `bytes` fixes ; les courbes accèdent ensuite à ces données via `hour_p(i)`/`hour_e(i)`. 
Raison : effectuer 72 × 4 accès au stockage par courbe dépasserait la limite de 50 ms.
- Axe des x : délimitations des jours en pointillés, repères à 00h et 12h, nom du jour suivi de la date sous chaque journée (ex. : « Jeu 11.06 »).
- Marqueur « jetzt » (maintenant) positionné à l'heure correcte sur l'ensemble des 3 jours.
- La règle « orange » de l'étape 2 s'applique heure par heure (prix horaire < 0).
- Modifier les méthodes existantes plutôt que de les dupliquer : `value_range`, `send_polyline`, `send_bars` et `send_x_axis` reçoivent désormais la plage (jour de début, nombre de valeurs) en paramètre.
- **Tas (Heap)** : mesurer `tasmota.gc()` et `heap_free` avant et après la modification, puis signaler la différence. 
Si la baisse dépasse 5 ko lors du rendu : interrompre l'opération.

### Prompt « planifier » (dans l'agent `plan`, onglet « Plan » tout en bas)

```
Consultez la section « F3 Chart » dans `@app/spot.be`, marquée par le commentaire « ERWEITERUNGSPUNKT Schritt 3 » (Point d'extension - Étape 3).

Tâche : Le graphique doit afficher 3 jours avec des valeurs horaires (72 au total), au lieu d'une seule journée avec 96 valeurs par quart d'heure.
Valeur horaire : Prix = moyenne ; Énergie = somme des 4 quarts d'heure ; absence de donnée (lacune) si les 4 quarts d'heure sont manquants.
Le calcul des valeurs horaires doit être effectué une seule fois par appel à `page_svg` et stocké dans des tampons d'octets fixes (`fill_hours`), et non recalculé pour chaque courbe.
Axe X : délimiteurs de jours en pointillés, repères « 00 » et « 12 », nom du jour accompagné de la date (ex. : « Jeu 11.06 »).
Le repère « maintenant » doit s'afficher correctement sur l'ensemble des 3 jours. La règle orange définie à l'étape 2 doit s'appliquer par heure.

Modifiez les méthodes existantes (en passant la plage de données en paramètre) plutôt que de les dupliquer. Mesurez la taille du tas (heap) avant et après la modification (via `tasmota.gc()`, puis `heap_free`). Dans la section « Plan », listez chaque méthode modifiée ainsi que la raison de cette modification. Ne procédez à aucune modification pour le moment.
```

### Résultat attendu

- 3 jours affichés côte à côte, noms des jours, 72 barres, ligne de prix représentée par paliers horaires.
- Comparaison avec la sauvegarde de l'étape précédente : les méthodes existantes ont été adaptées ; aucune variante du type `send_..._3d` n'a été dupliquée.
- Après le téléversement et l'exécution de `tasmota.gc()`, la taille du tas (heap) ne doit pas être inférieure de plus de ~2 ko par rapport à sa valeur initiale avant cette étape. 

## Étape 4 – Graphique de rémunération (pour les plus rapides, ~15 min)

![Objectif Étape 4 : second graphique de rémunération en CHF/h avec total](docs/steps/schritt_4.png)

### Tâche

Sous le graphique existant, ajoutez un **second graphique, plus plat : rémunération par heure (CHF)**, partageant le même axe des abscisses (x), avec un **total Σ sur les 3 jours** affiché en haut à droite.

Spécifications :

- Rémunération par heure = somme, sur les 4 quarts d'heure, du produit (prix × énergie). Utilisez les données calculées dans `fill_hours` à l'étape 3 (troisième tampon, `hour_v(i)`) ; ne créez pas de nouvelle boucle.
- Barres jaunes (`COL_PAY`) si ≥ 0, rouges (`COL_COST`) si < 0. Ligne de base à zéro ; axe des ordonnées (y) à gauche indiquant les valeurs max/0/min en CHF. Texte « négatif = l'injection coûte » en bas à gauche (uniquement si des valeurs négatives sont présentes).
- Titre « Rémunération CHF/h » à gauche, « Σ x.xx CHF » à droite.
- Alignement horizontal identique au graphique supérieur (l'heure *n* doit être superposée dans les deux graphiques) ; le marqueur « maintenant » doit également figurer en bas.
- Envoi par segments, comme pour le graphique supérieur (via `tasmota.web_send` pour chaque partie), sans construire une chaîne de caractères globale.

### Prompt « planifier » (dans l'agent `plan`, appuyez sur `SHIFT+TAB` jusqu'à ce que `Plan` s'affiche en bas)

```
Lisez la section "F3 Chart" dans le fichier @app/spot.be, identifiée par le commentaire "ERWEITERUNGSPUNKT Schritt 4".

Tâche : Sous le graphique principal, ajoutez un second graphique, plus plat, intitulé « Rémunération CHF/h ». Il doit afficher, pour chaque heure, la somme du produit (prix × énergie) des 4 quarts d'heure correspondants. Utilisez des barres jaunes (`COL_PAY`) pour les valeurs ≥ 0 et rouges (`COL_COST`) pour les valeurs < 0. L'axe de gauche doit être gradué en CHF, et la somme totale (« Σ x.xx CHF ») doit apparaître en haut à droite, couvrant l'ensemble des 3 jours. Les positions sur l'axe des abscisses (x) doivent correspondre à celles du graphique supérieur ; le repère « maintenant » doit également être affiché en bas.

Réutilisez la méthode auxiliaire de calcul des valeurs horaires créée à l'étape 3, ainsi que les méthodes de dessin existantes. Envoyez les données par segments via `tasmota.web_send`. Dans votre plan, précisez quelles méthodes sont réutilisées et lesquelles sont nouvelles. Ne modifiez rien pour le moment.
```

### Résultat attendu

- L'objectif illustré dans `docs/zielbild.jpg` est atteint : deux graphiques superposés, alignés sur les heures. La somme totale (« Σ ») correspond bien au cumul des valeurs journalières (en-tête « Rémunération aujourd'hui » + jours précédents).
- Après le chargement et l'appel à `tasmota.gc()`, l'espace mémoire disponible (heap) est supérieur à 100 ko ; le rendu s'effectue sans chute de mémoire supérieure à 5 ko.

## Étape 5 – 2 jours avec données par quart d'heure (niveau avancé, ~25 min)

![Objectif étape 5 : 2 jours avec 192 quarts d'heure, prix représentés sous forme d'escalier](docs/steps/schritt_5.png)

Contexte : BKW publie désormais des **prix distincts pour chaque quart d'heure** (par ex.
à 16h : 32,8 / 34,4 / 46,5 / 48,9 centimes). La moyenne horaire utilisée à l'étape 3
gomme les pics (moyenne : 40,6 centimes). Les données stockées en mémoire sont déjà exprimées par quarts d'heure ; seule la représentation graphique effectue un regroupement.

Prérequis : Étape 4 terminée ; sinon, exécutez `cp app/steps/spot_4.be app/spot.be && ./upload.sh app/spot.be`.

### Tâche

Les deux graphiques doivent afficher **2 jours, chacun découpé en tranches de 15 minutes** (soit 96 intervalles par jour, pour un total de 192 valeurs), au lieu de 3 jours avec des données horaires.

Spécifications :

- Jours : **hier (historique) + aujourd'hui** ; dès que les prix pour demain sont disponibles (généralement vers 17h00), l'affichage doit passer à **aujourd'hui + demain**. À gérer dans `chart_start`.
- Définir les nouvelles constantes `CH_DAYS = 2` et `CH_Q = 1` (nombre de tranches de 15 minutes par valeur), ainsi que `CH_N = 192` et `CH_MIN = 15`. Aucun nombre « en dur » (2, 96, 192 ou 24) ne doit subsister dans le code du graphique. Vérification : en réglant `CH_DAYS = 3`, `CH_Q = 4`, `CH_N = 72` et `CH_MIN = 60`, le graphique doit redevenir identique à celui de l'étape 4.
- Modifier `fill_hours` (renommer en `fill_values`, remplacer `hour_*` par `val_*`) : utiliser `CH_Q` tranches de 15 minutes par valeur ; le prix correspond à la moyenne, tandis que l'énergie et la rémunération correspondent à la somme (comme précédemment).
- Afficher le prix sous forme de **ligne en escalier** : chaque valeur est représentée par un segment horizontal couvrant toute sa largeur (adapter `send_polyline` ; ne pas ajouter de seconde méthode de dessin).
- `send_bars`envoie un tracé dès qu'il atteint une taille de `PATH_MAX` (600) octets, puis en entame un nouveau. 
Raison : 192 barres représenteraient environ 3 ko par chaîne de tracé.
- Axe des x par jour : repères 00/06/12/18, nom du jour ; `data-d` avec une entrée par jour. Graphique
inférieur : « Rémunération CHF/¼h ».
- **Mesure et rapport des coûts** : taille de `/spot.svg` dans l'environnement de bureau (`SVG … octets`),
durée d'exécution de `fill_values` sur l'appareil, état du tas (heap) avant/après. Seuils : SVG < 16 ko, tas > 100 ko.

### Consigne « planifier » (dans l'agent `plan`, utiliser la touche `SHIFT+TAB` jusqu'à ce que « Plan » s'affiche en bas)

```
Consultez la section « F3 Chart » dans le fichier `@app/spot.be`, identifiée par le commentaire « ERWEITERUNGSPUNKT Schritt 5 » (POINT D'EXTENSION Étape 5).

Tâche : Les deux graphiques doivent désormais afficher 2 jours, chacun composé de 96 tranches d'un quart d'heure (soit 192 valeurs), au lieu de 3 jours avec des valeurs horaires. Jours concernés : hier + aujourd'hui ; dès que les prix pour demain sont disponibles, le graphique affichera aujourd'hui + demain (via `chart_start`). Définissez les nouvelles constantes suivantes : `CH_DAYS = 2`, `CH_Q = 1` (nombre de quarts d'heure par valeur), `CH_N = 192` et `CH_MIN = 15` ; aucune de ces valeurs ne doit être codée en dur dans le code du graphique. La fonction `fill_hours` devient `fill_values` et calcule désormais `CH_Q` quarts d'heure par valeur. Les prix doivent être représentés sous forme de ligne en escalier (chaque valeur est tracée horizontalement sur toute sa largeur) dans `send_polyline`. La fonction `send_bars` doit envoyer les tracés par segments dès qu'ils atteignent 600 octets. L'axe des x doit être organisé par jour avec les repères 00/06/12/18, `data-d` doit être défini par jour, et l'axe inférieur doit indiquer « CHF/¼h ».

Modifiez les méthodes existantes, ne vous contentez pas de les copier. Indiquez dans votre plan chaque méthode modifiée, ainsi que la manière dont vous mesurez la taille du SVG (via le *desktop-harness*), la durée d'exécution de `fill_values` (à l'aide de `tasmota.millis()` via `brcmd.sh`) et l'utilisation du *heap* (mémoire tas). Ne procédez à aucune modification pour le moment.
```

### Résultat attendu

- Affichage de 2 jours côte à côte, avec 192 barres étroites ; les prix sont représentés sous forme d'escalier par paliers de ¼ d'heure. Avec les tarifs réels de BKW, les pics sont visibles à l'intérieur d'une même heure (comparaison : courbe Grafana/BKW).
- Avant 17h00 : affichage de « hier » et « aujourd'hui », avec le marqueur « maintenant » situé sur la journée de droite ; après 17h00 : affichage de « aujourd'hui » et « demain », avec le marqueur « maintenant » situé sur la journée de gauche.
- Le curseur indique le jour et l'heure, avec une précision au quart d'heure (`data-m` = 15).
- Valeurs de référence (`spot_5.be`) : *Harness* `SVG … bytes = 12204` (étape 4 : 7010), `fill_values` 57 ms
sur un C3, *heap* stable à 111 ko après plusieurs rendus.

## Étapes de vérification (toutes les étapes)

```sh
cd app && berry desktop_harness.be | tail -1      # HARNESS OK
cd ..
./upload.sh app/spot.be                           # OK ... heap_free N ko
./log.sh                                          # aucune erreur BRY:
./brcmd.sh 'tasmota.cmd("SpotStatus")'            # « Days » présent, HeapFree proche de la valeur initiale
./brcmd.sh 'tasmota.gc()'; ./brcmd.sh 'tasmota.memory("heap_free")'
diff spot_schritt2.be app/spot.be | head -40      # quelques lignes (ou git diff --stat)
```

Dans le navigateur : **recharger** la page (Cmd+R / F5), afficher ou masquer les courbes via la légende, et survoler les valeurs avec la souris.

## Écueils fréquents (relevés lors d'un essai : 30 min, 14 téléversements)

1. **Axes supplémentaires.** Seul l'axe des kWh à gauche (issu de l'étape 1) est autorisé (ainsi que l'axe des CHF dans un graphique dédié, issu de l'étape 4) ; c'est ce qui est stipulé dans `AGENTS_FR.md`. Si l'agent tente d'ajouter d'autres libellés : refusez et rappelez la consigne.
2. **Cases à cocher / `onchange` dans le graphique :** ne fonctionnent jamais. Tasmota remplace la zone du capteur toutes les quelques secondes via AJAX, ce qui empêche l'exécution des scripts qu'elle contient. Il faut étendre la légende via `chart_curves()`.
3. **Boucle de dessin personnalisée.** L'agent duplique la logique de tracé de lignes (parfois deux fois). Exigez l'utilisation de `send_polyline` ou `send_bars`.
4. **Duplication au lieu de modification** (étapes 3/4) : utilisation de `send_x_axis_3d`, `value_range2`, etc. Consigne : « Modifiez la méthode existante et supprimez la copie. »
5. **Mémoire (Heap).** Chaque téléversement consomme environ 1 ko, qui n'est récupéré qu'après un redémarrage ; `upload.sh` redémarre automatiquement l'appareil si la mémoire disponible passe sous les 100 ko. Si l'agent échoue deux fois de la même manière : interrompez le processus et examinez vous-même les logs.
6. **API inventée** (ex: `webserver.content_send` dans `web_sensor`, ou des fonctions `tasmota.*` inexistantes). Renvoyez vers `TASMOTA_BERRY_API_FR.md` ; seuls les éléments qui y figurent sont valides.
7. **`BrRestart` / `Restart` via `brcmd.sh` :** interdits (provoquent un plantage ou un redémarrage). Recharger l'application
uniquement via `./upload.sh`.
8. **`var` manquant** pour une nouvelle variable d'instance → erreur `BRY:` avec numéro de ligne lors du chargement
(mode strict). Ligne transmise telle quelle à l'agent.
9. **Dérive du périmètre** (« j'en ai profité pour… ») : rappeler la consigne « ne rien modifier d'autre »,
annuler la modification avec `/undo`.
10. **Stubs sur l'appareil** (`persist.be`, `path.be`, `webserver.be`, `desktop_harness.be`) : `upload.sh` refuse. 
L'agent ne doit charger que `app/spot.be`.
11. **Graphique ou curseur absent** après un chargement : la page utilise encore l'ancien script, qui
récupère `/spot.svg` et dessine le curseur (Tasmota ne remplace via AJAX que la zone du capteur ; le scri(le graphique ne se charge que lors de l'appel de la page). Rechargement de la page, aucune erreur dans le code. Le graphique ne se trouve pas
dans la zone des capteurs ; il provient du gestionnaire `/spot.svg` (`page_svg`). `web_sensor` envoie uniquement
des chiffres et l'espace réservé `#spotchart`. L'agent a-t-il tenté d'intégrer le graphique dans `web_sensor` ?
Non (cela coûtait 1,2 s par rafraîchissement et provoquait le plantage de l'appareil).
12. **Autorisations Shell.** « opencode » demande confirmation avant chaque commande. N'autoriser que `./upload.sh`, `./log.sh`,
`./brcmd.sh`, `berry`, `cp` et `git` ; refuser tout le reste et demander à l'agent de justifier sa requête.

## Bonus (pour ceux qui ont terminé)

- **CSV avec valeurs horaires** : en plus du fichier journalier `spot_h_YYYY-MM.csv`, avec une conservation de deux
mois. Points d'extension : `cfg["csv_hourly"]` et `day_end()`. Objectif pédagogique : exiger la testabilité
(demander une fonction acceptant un paramètre de date).
- **Seuil via Shelly/MQTT** : si le prix passe en dessous ou au-dessus d'un seuil, déclencher un appareil (via HTTP)
ou envoyer une notification via `mqtt.publish`. Points d'extension : `json_append()` / nouvelle commande. Objectif pédagogique :
fournir le contexte de l'API tierce (extrait de la documentation Shelly), sinon l'agent devra deviner.

## Liste de vérification pour le bilan final

- Le prompt qui a fonctionné (texte exact).
- Le prompt qui a échoué, et le résultat produit par l'agent.
- Nombre de cycles de téléversement (upload) et étape atteinte.
- Valeur de `HeapFree` au début et à la fin.