# Légende

Termes et abréviations utilisés dans l'atelier.

| Terme | Signification |
|---|---|
| **gPlug** | Petit adaptateur pour le port du compteur intelligent (P1/HAN) ; fonctionne avec Tasmota sur un ESP32-C3. |
| **Tasmota** | Micrologiciel (firmware) open source pour appareils ESP, doté d'une interface web (WebUI), d'une console et prenant en charge les scripts Berry. |
| **ESP32-C3** | Microcontrôleur utilisé dans le gPlug (Wi-Fi, mémoire vive limitée, environ 110 ko disponibles). |
| **Berry** | Langage de script léger intégré à Tasmota ; l'application `app/spot.be` est écrite en Berry. |
| **WebUI** | Interface web de l'appareil, accessible via `http://<gplug-ip>`. |
| **Smart Meter** | Compteur électrique électronique équipé d'une interface de transmission de données. |
| **SML** | Smart Message Language : protocole utilisé par le gPlug pour lire les données du compteur. |
| **UFS** | Micro File System : système de fichiers situé dans la mémoire flash de l'appareil (utilisé pour les scripts et les fichiers CSV). |
| **OTA** | Over-the-Air : mise à jour du micrologiciel via Wi-Fi, sans connexion filaire. |
| **Heap / `HeapFree`** | Mémoire vive (RAM) disponible sur l'appareil. Elle doit rester supérieure à 100 ko. |
| **BKW** | Fournisseur d'énergie dont l'API fournit les tarifs dynamiques d'injection. |
| **Tarif d'injection / Prix spot** | Rémunération par kWh pour l'électricité injectée sur le réseau (ici, calculée par tranche de 15 minutes). |
| **Injection** | Énergie transmise au réseau (index du compteur d'exportation `z.Eo`). |
| **Rémunération** | Injection × tarif, exprimée en CHF. |
| **kWh** | Kilowattheure, unité d'énergie. |
| **¼ h / Quart d'heure** | Pas de temps utilisé pour les prix et les mesures (96 valeurs par jour). |
| **Slot** | Entrée correspondant à un quart d'heure dans la mémoire. |
| **Simulateur (`sim`)** | Génère des valeurs de test lorsqu'aucun compteur intelligent (*Smart Meter*) n'est connecté. |
| **Accélération temporelle** | Cadence du simulateur (`sim_tick`, 5/15/60 min) : à chaque cycle, le temps simulé avance d'un quart d'heure, ce qui permet au graphique de se remplir plus rapidement. |
| **CSV** | Fichier texte contenant des valeurs séparées par des points-virgules ; une ligne par jour. |
| **SVG** | Graphique vectoriel ; le graphique journalier est généré au format SVG dans l'interface web (*WebUI*). |
| **Bande du curseur** | Colonne claire apparaissant dans le graphique sous la souris ; elle affiche l'heure ainsi que les valeurs correspondant à ce quart d'heure ou à cette heure. |
| **JSON** | Format textuel pour les données, utilisé par exemple pour la réponse du fournisseur d'énergie (BKW) et les résultats des commandes. |
| **API** | Interface de programmation ; ici, il s'agit de l'interrogation des tarifs BKW et de l'API Berry de Tasmota. |
| **Télémétrie / Tele** | Rapport d'état périodique de l'appareil, transmis au format JSON. |
| **Commande (*Command*)** | Commande Tasmota (par ex. `SpotStatus`) ; utilisable dans la console ou via `brcmd.sh`. |
| **`BrRestart`** | Commande Tasmota qui redémarre l'environnement Berry et charge le fichier `autoexec.be`. |
| **`autoexec.be`** | Script de démarrage qui exécute `load("spot")` au lancement. |
| **Point d'extension** | Commentaire `# ERWEITERUNGSPUNKT` dans `spot.be` : c'est ici que s'articule l'exercice. |
| **Point de départ (*Starter*)** | État initial de l'exercice dans `app/spot.be` : le graphique affiche uniquement la courbe des prix spot sur une journée. |
| **Application de référence** | État final après l'étape 4 : 3 jours, injection sur le réseau, prix négatifs, graphique de rémunération (`app/steps/spot_4.be`). |
| **Étape 5** | Extension pour un niveau avancé (après l'application de référence) : 2 jours avec des données par quart d'heure (96 valeurs par jour) au lieu de valeurs horaires ; le prix est représenté sous forme de courbe en escalier (`app/steps/spot_5.be`). |
| **Point de contrôle (Checkpoint)** | État abouti après une étape donnée (`app/steps/spot_N.be`) ; peut être copié vers `app/spot.be` pour rattraper le niveau si nécessaire. |
| **Agent de codage (Coding Agent)** | Assistant basé sur l'IA capable de lire et de modifier du code, ainsi que d'utiliser divers outils (shell, fichiers). |
| **opencode** | Agent de codage open source utilisé dans le cadre de cet atelier. |
| **TUI** | *Text User Interface* (interface utilisateur textuelle) : interface de contrôle située dans le terminal ; ici, il s'agit de celle d'opencode. |
| **Modes `plan` / `build`** | Modes disponibles dans opencode : `plan` se limite à la planification sans effectuer de modifications, tandis que `build` procède à la mise en œuvre. On passe de l'un à l'autre via `Shift+Tab`. |
| **LLM** | *Large Language Model* (grand modèle de langage) : le modèle qui propulse l'agent (ici, Qwen3.5 122B-A10B). |
| **Prompt** | Saisie ou instruction adressée au modèle de langage. |
| **Infomaniak AI Tools** | Service suisse fournissant le LLM ; l'accès s'effectue via un identifiant de produit (*Product-ID*) et un jeton API (*API-Token*). |
| **Jeton API (API-Token)** | Clé secrète permettant d'accéder à un service. Ne jamais l'inclure dans un commit (ne jamais le partager dans le code source). |
| **Docker / Conteneur** | Environnement d'exécution isolé ; au sein de celui-ci, l'agent ne perçoit que le dossier du projet. |
| **WSL / Ubuntu** | Sous-système Windows pour Linux : terminal Ubuntu sous Windows, où s'appliquent les commandes Linux mentionnées dans les supports. |
| **Sandbox** | Environnement isolé qui restreint l'agent au dossier du projet. |
| **`AGENTS.md`** | Fichier de règles lu automatiquement par l'agent de codage. |
| **Desktop-Harness** | Test sur PC à l'aide de l'interpréteur Berry, sans appareil physique (`HARNESS OK`). |
| **git / Commit** | Gestion de versions / état figé des modifications. |
| **WLAN / IP** | Réseau sans fil / adresse réseau de l'appareil (indiquée dans `.gplug`). |
| **Tour de table final** | Fin de l'exercice : chacun fait un bref compte-rendu (prompt utilisé, obstacles rencontrés, fichiers téléversés et `HeapFree` — voir la liste de contrôle dans `EXERCISES.md`). |
