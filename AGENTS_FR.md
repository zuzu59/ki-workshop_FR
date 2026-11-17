# AGENTS.md – Règles pour l'agent de codage

Projet : Application Berry `app/spot.be` pour le gPlug (Tasmota 15.3.0+, ESP32-C3). Récupère les prix d'injection pour les installations photovoltaïques (BKW),
mesure l'énergie par tranches de 15 minutes et affiche un graphique dans l'interface web de Tasmota. Lors de l'atelier, vous ferez évoluer le code de départ
par **petites étapes** (`EXERCISES.md`) pour aboutir à l'application de référence ; ne créez pas une nouvelle application.

**Travaillez uniquement dans le dossier du projet.** Ne lisez ni n'écrivez aucun fichier ou dossier situé en dehors du répertoire racine du projet (celui
qui contient ce fichier `AGENTS.md`), même via des commandes shell : n'utilisez pas de chemins absolus externes, pas de `..` pour sortir du projet,
pas de `~`, et ne touchez pas aux fichiers d'environnement ou de configuration du notebook. Créez les fichiers temporaires uniquement dans le dossier du projet.
Si une tâche nécessite un élément extérieur, arrêtez-vous et demandez à l'humain.

## 1. Lire d'abord

Avant toute modification, lisez la documentation ; ne devinez pas :

- `TASMOTA_BERRY_API.md` – l'API Berry de Tasmota. Utilisez **uniquement** les fonctions qui y sont répertoriées,
celles présentes dans `app/spot.be`, ou celles figurant dans la référence du langage Berry
(<https://tasmota.github.io/docs/_media/BERRY_LANGUAGE_REFERENCE.txt>). S'il manque quelque chose, signalez-le ; n'inventez rien.
- `app/spot.be` – le code existant. Intégrez vos ajouts au niveau des commentaires `# ERWEITERUNGSPUNKT` (point d'extension).
- `EXERCISES.md` – l'énoncé, les consignes et les étapes de vérification de l'exercice.

## 2. Fichiers

| Fichier | Utilité | Sur l'appareil ? |
|---|---|---|
| `app/spot.be` | l'application | oui | | `app/autoexec.be` | charge `spot` au démarrage et lors de `BrRestart` | oui, uniquement si nécessaire |
| `app/desktop_harness.be`, `app/persist.be`, `app/path.be`, `app/webserver.be` | test sur ordinateur (desktop), stubs | **jamais** |
| `reference/` | exemples de `read_sensors` (chemin des compteurs) | non |
| `app/steps/spot_N.be` | état final correspondant à l'étape N ; ne pas modifier ; l'utilisateur doit en copier un vers `app/spot.be` | non (uniquement en tant que `app/spot.be`) |
| `tools/make_steps.py` | préparation pour l'encadrement du cours ; ne jamais appeler avec `--write` (cela écrase `app/spot.be`) | non |

## 3. Outils (Appareil)

L'appareil est défini dans `.gplug` (une ligne, adresse IP) ou dans la variable `$GPLUG`. Interagir avec l'appareil **uniquement** via ces scripts ; ne pas utiliser `curl` directement vers l'appareil.

| Script | Action |
|---|---|
| `./upload.sh app/spot.be` | téléversement, vérification de la taille, `BrRestart` (recharge l'application) |
| `./upload.sh --no-restart <fichier>` | téléversement uniquement |
| `./brcmd.sh '<berry>'` | exécute une expression Berry, renvoie le résultat au format JSON ; ex. : `./brcmd.sh 'tasmota.cmd("SpotStatus")'` |
| `./log.sh [n]` | affiche les n dernières lignes de la console (par défaut 40, exclut la télémétrie SENSOR/STATE) ; `-a` = tout afficher | Vérifications utiles :

```sh
./brcmd.sh 'tasmota.cmd("SpotStatus")'        # État, prix, mémoire (heap)
./brcmd.sh 'tasmota.cmd("SpotPrices")'        # 10 prochaines heures
./brcmd.sh 'tasmota.gc()'                      # Nettoyage mémoire, puis :
./brcmd.sh 'tasmota.memory("heap_free")'      # Mémoire libre (heap) en ko ; doit rester > 100
./brcmd.sh 'load("spot")'                     # Recharger l'application sans téléversement (premier rechargement : +20 ko, ensuite stable)
```

## 4. Cycle de travail

1. Décrire le plan en 3 à 5 phrases : point d'extension, source de données, résultat attendu, étape de vérification.
2. Apporter une petite modification dans `app/spot.be`.
3. Test sur ordinateur (optionnel) : `cd app && berry desktop_harness.be` (nécessite `app/bkw.json` ; à récupérer une fois via
`curl -s -o app/bkw.json https://api.bkw.ch/api/dyntariffs/v1/Tariffs/energyreturn`). Doit se terminer par
`HARNESS OK`.
4. Exécuter `./upload.sh app/spot.be`, puis consulter **systématiquement** les logs avec `./log.sh`. Analyser littéralement les lignes commençant par `BRY:` ou `SPOT:`, ainsi que tout message d'erreur.
5. Vérifier via `./brcmd.sh` si le résultat attendu est obtenu. Contrôler la mémoire (heap).
6. Faire un bref compte-rendu : modifications apportées, vérifications effectuées, points restant à traiter. L'utilisateur effectue lui-même une vérification via l'interface web (WebUI).

Si une étape échoue deux fois de la même manière : interrompre le processus, afficher le message d'erreur et demander conseil à l'utilisateur. 

## 5. Opérations interdites sur l'appareil

Ne jamais exécuter les commandes suivantes, y compris via `tasmota.cmd(...)` : `Reset`, `Restart`, `BrRestart` (l'exécution depuis Berry provoque un plantage de l'appareil ; le redémarrage de l'application n'est alors possible que via `./upload.sh` ou `load("spot")`), `Upgrade`, `OtaUrl`, `Backlog`, les commandes relatives au Wi-Fi et aux mots de passe (`Ssid`, `Password`, `WebPassword`, `Wifi…`), `Module`, `Template`, `Gpio…`, `SetOption…`, `Script` (le script gPlug lit le compteur), ainsi que la suppression ou le renommage de fichiers (à l'exception de vos propres fichiers de test CSV). Bien que `brcmd.sh` bloque la plupart de ces commandes, veillez à ne pas les utiliser. En cas de doute sur l'innocuité d'une commande, demandez à une personne compétente.

## 6. Règles de codage (Berry sur Tasmota)

- Berry peut bloquer Tasmota : aucun *callback* ne doit durer plus de 50 ms, aucune attente active (*busy waiting*) dans des boucles n'est autorisée ; les tâches longues doivent être découpées à l'aide de `tasmota.set_timer`.
- `tasmota.web_send` ne doit être utilisé que dans `web_sensor()` ou dans le gestionnaire (*handler*) `pag`e_svg()` (`/spot.svg`) et les fonctions d'assistance `send_*` ; 
`webserver.on` doit être utilisé uniquement dans `web_add_handler()`.
- Mode strict : ne pas lire de variables globales non déclarées ; déclarer les membres de classe avec `var`.
- Mémoire vive (RAM) limitée (~110 ko disponibles) : éviter de construire de grandes chaînes de caractères ou des listes ; envoyer le code HTML/SVG par fragments ; ne jamais analyser la réponse du système photovoltaïque (BKW) avec `json.load`.
- Surveiller le tas (heap) : après chaque téléchargement, `upload.sh` affiche `heap_free`. Si la valeur descend en dessous de 100 ko, l'appareil redémarre automatiquement (chaque `BrRestart` consomme environ 1 ko ; seul un redémarrage complet permet de récupérer cet espace). Si, après une modification, la taille du tas diminue de manière persistante (constaté en répétant la même action, après avoir appelé `tasmota.gc()`), c'est que la modification est en cause : il faut en identifier la source avant de poursuivre le développement.
- Ne jamais lire les fichiers par blocs via `f.read(n)` (dans Tasmota 15.3, cela entraîne une fuite mémoire d'environ 1,5 × n octets par itération) : utiliser plutôt `f.readbytes(n).asstring()` ou `f.readline()` (voir `parse_file` dans `spot.be`).
- Préserver la mémoire flash : limiter les écritures dans les fichiers au strict nécessaire (par exemple, une écriture CSV par jour ou par heure).
- Envelopper le corps de chaque fonction de rappel (callback) dans un bloc `try ... except .. as e, m ... end` et journaliser les erreurs via `log("SPOT: ...", 2)`.
- Enregistrer les nouvelles commandes via `tasmota.add_cmd` et définir des identifiants fixes pour les tâches planifiées (cron), afin d'éviter les doubles enregistrements lors de l'exécution de `load("spot")`.
- Graphiques (Chart) : ajouter de nouvelles courbes uniquement via `chart_curves()` combiné à `send_polyline` ou `send_bars` (voir section `F3 Chart`). Ne pas implémenter de boucle de dessin personnalisée, ni inclure de balises `<script>` ou de cases à cocher dans la zone dédiée aux capteurs (cette zone étant mise à jour par Tasmota via AJAX, les scripts qu'elle contient ne seront pas exécutés). - Axes : sont autorisés un axe pour le prix à droite (ct./kWh), **un** axe pour les kWh à gauche (étape 1) et, dans le graphique de rémunération, un axe pour les CHF à gauche (étape 4). Toute autre demande d'axe supplémentaire doit faire l'objet d'une concertation préalable.
- Adopter le style de `spot.be` : commentaires en allemand, méthodes courtes, pas d'astuces complexes.

## 7. Git

Sauvegarder les versions fonctionnelles (avec l'accord de l'utilisateur) : si le dossier du projet est un dépôt Git (présence d'un répertoire `.git`), effectuer un petit commit ; ​​sinon, créer une copie nommée `spot_étapeN.be` dans le dossier du projet. Ne jamais inclure dans les commits les fichiers `.gplug`, les clés API ou le fichier `bkw.json`.