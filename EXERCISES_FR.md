# Exercices – Travailler avec l'agent de codage sur le gPlug

📄 [Cet exercice en PDF (A4)](docs/EXERCISES.pdf) · [Terminologie : LEGENDE.md](LEGENDE.md)

Ces exercices portent sur le **cycle de travail avec l'agent** : fournir le contexte → formuler une tâche petite et vérifiable → charger le code sur l'appareil → consulter la console → rapporter les erreurs textuellement. L'application Berry `app/spot.be` sert uniquement de support à l'exercice. Les exercices modifient uniquement l'affichage, jamais le flux de données ; en cas d'erreur, le cœur de l'application reste intact.

Bases : `AGENTS.md` (règles et outils, lus automatiquement par l'agent), `TASMOTA_BERRY_API.md` (l'API Tasmota ; sans elle, l'agent doit deviner), `SETUP_OPENCODE.md` §7 (fonctionnement de l'agent).

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
(`cp app/steps/spot_2.be app/spot.be && ./upload.sh app/spot.be`). ### Starter (Étape 0)

![Starter : uniquement la courbe des prix, 1 jour](docs/steps/schritt_0.png)

Données complètes, affichage minimaliste :

- En arrière-plan : récupération des prix (F1), compteur avec simulateur incluant une accélération temporelle, `Po` et jours précédents renseignés (F2), fichier CSV journalier (F4), `SpotPrices` (F5). La mémoire conserve les prix et l'énergie sur **3 jours**.
- Lignes de texte au-dessus du graphique : prix spot actuel, injection aujourd'hui, rémunération aujourd'hui. Cela permet de visualiser les données avant même qu'elles ne soient tracées ; l'étape 1 peut être vérifiée via la valeur « Injection aujourd'hui ».
- Graphique : **uniquement la courbe des prix** (cyan, `COL_PRICE`), sur 1 jour avec 96 valeurs par quart d'heure, axe en Rp./kWh à droite, ligne zéro, repère « maintenant » (gris), légende générée par `chart_curves()`. Couleurs identiques à l'image finale ; `COL_ENERGY` (vert), `COL_NEG` (orange), `COL_PAY` (jaune) et `COL_COST` (rouge) sont déjà définies.
- Le simulateur intègre une baisse des prix à la mi-journée, avec des tarifs négatifs (cas de test pour l'étape 2).
- Utilitaires disponibles : `chart_curves()`, `send_polyline(...)`, `value_range(...)`, `nice_range(...)` (pour des graduations d'axe arrondies), `y_scale(...)`, `send_data_attr(...)` (valeurs pour le curseur), constantes de couleur `COL_...`, accès aux données via `self.store.price(key, slot)` (en 1/10 000 CHF/kWh) et `self.store.energy_at(key, slot)` (en 0,01 kWh) — une valeur `nil` indique une donnée manquante. - Commentaires `# POINT D'EXTENSION Étape 1` … `Étape 4` au début de `F3 Chart` ; chaque
point de contrôle (*checkpoint*) ne contient désormais que les points des étapes en cours.
- Le script du curseur est identique à toutes les étapes : il affiche chaque valeur disponible (`data-p`, `data-e`,
`data-v`) et calcule la durée à partir de `data-m` (15 ou 60 min). Aucune étape ne modifie ce script.

## Préparation (5 min)

1. Vérifier l'adresse IP de l'appareil (indiquée dans le RUNBOOK, étape 6.1). Résultat attendu : l'adresse IP, par ex. `192.168.1.50`. 
```sh
cat .gplug
```
2. L'appareil répond ; on attend un JSON contenant `"Sim":true`. **Noter la valeur `HeapFree`** (valeur initiale, par ex. 125). 
```sh
./brcmd.sh 'tasmota.cmd("SpotStatus")'
```
3. Laisser l'interface Web (WebUI) du gPlug ouverte dans le navigateur (`http://192.168.x.y`).
4. Lancer opencode :
```sh
./docker-run.sh
```
Si Docker n'est pas utilisé (installation native, voir `SETUP_OPENCODE.md`), depuis le dossier du dépôt :
```sh
opencode
```
opencode démarre dans l'agent **build** ; avant l'apparition de la première invite (*prompt*), basculer sur **plan** (touche `Tab`, voir
*Déroulement par étape*).

## Déroulement par étape

op