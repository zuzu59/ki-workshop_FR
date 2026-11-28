# Mission : Intégrer l'émulateur gPlug dans le dépôt `ki-workshop_FR`

## Contexte
Je dispose de deux dépôts locaux dans mon dossier de travail (`~/dev/` ou le dossier parent) :
1. **`glue-workshop-smart-energy`** (source de l'émulateur) : contient un émulateur Tasmota/Berry complet sous Docker (`emulator/`, `docker/`, `docker-compose.yml`, `build.sh`).
2. **`ki-workshop_FR`** (projet cible) : contient les exercices d'un atelier Smart Energy en français (`app/spot.be`, `app/autoexec.be`, `app/steps/`, `upload.sh`, `brcmd.sh`, `log.sh`, `EXERCISES_FR.md`).

À l'origine, `ki-workshop_FR` est prévu pour déployer le code sur un boîtier physique gPlug via HTTP (en lisant l'IP dans un fichier `.gplug`).
**Mon objectif** est de rapatrier l'émulateur de `glue-workshop-smart-energy` dans `ki-workshop_FR` et d'adapter les scripts existants (`upload.sh`, `brcmd.sh`, `log.sh`, et la documentation) pour que tout l'atelier puisse être réalisé et testé localement sur l'émulateur (`http://localhost:8080`) sans matériel physique.

---

## Étapes à réaliser

### 1. Copier l'infrastructure de l'émulateur
Depuis le dépôt `glue-workshop-smart-energy`, copie vers la racine de `ki-workshop_FR` :
- Le dossier `emulator/`
- Le dossier `docker/`
- Le fichier `build.sh`
- Les services nécessaires de `docker-compose.yml` (notamment `emulator` sur le port `8080` et `tools` pour la compilation). *Note : vérifie s'il existe déjà un `docker-compose.yml` ou `Dockerfile` dans `ki-workshop_FR` et fusionne-les proprement sans casser les outils existants (comme `opencode` s'il est configuré).*
- Ajoute `build/` et `.tmp_build/` dans le `.gitignore` de `ki-workshop_FR`.

### 2. Analyser et résoudre les différences de structure Berry
Inspecte `build.sh` (venant de `glue-workshop-smart-energy`) ainsi que `app/autoexec.be` et `app/spot.be` (dans `ki-workshop_FR`) :
- Comprends comment `build.sh` assemble les fichiers `.be` d'un dossier source pour générer `build/autoexec.be` et le paquet `build/gplug.tapp`, puis comment il l'envoie à l'émulateur (`http://emulator:8080`).
- Attention : `ki-workshop_FR/app/` contient déjà un fichier `autoexec.be`, un fichier `spot.be` et un sous-dossier `steps/`. Assure-toi que `build.sh` ne compile pas les fichiers de `app/steps/` par erreur et qu'il n'y ait pas de conflit entre `app/autoexec.be` et le `build/autoexec.be` généré (par exemple en préparant un répertoire de travail temporaire `.tmp_build/` lors de l'appel à `build.sh`, où `autoexec.be` est renommé en `main.be` si nécessaire).
- Vérifie également si `spot.be` ou `autoexec.be` ont besoin d'ajustements mineurs pour fonctionner dans l'émulateur (par exemple l'activation du mode simulation `"sim": true` par défaut ou la compatibilité des APIs Tasmota simulées).

### 3. Adapter les scripts d'interaction (`upload.sh`, `brcmd.sh`, `log.sh`)
Inspecte les scripts `upload.sh`, `brcmd.sh` et `log.sh` de `ki-workshop_FR` ainsi que les endpoints HTTP exposés par l'émulateur (`emulator/`).
Adapte ces scripts pour qu'ils fonctionnent par défaut avec l'émulateur local (`http://localhost:8080`) tout en conservant, si possible, la compatibilité avec un boîtier physique si `.gplug` contient une autre IP :

1. **`upload.sh`** :
   - Prépare un dossier source propre (contenant uniquement `app/spot.be` et `app/autoexec.be`, sans `app/steps/`).
   - Lance `docker compose run --rm tools bash build.sh <dossier_propre> build` pour compiler le `.tapp` et le téléverser automatiquement dans le conteneur `emulator` actif.
   - Ignore les éventuels arguments passés en ligne de commande (comme `./upload.sh app/spot.be app/autoexec.be` mentionné dans les consignes) afin que les commandes exactes de `EXERCISES_FR.md` fonctionnent telles quelles.
2. **`brcmd.sh` et `log.sh`** :
   - Vérifie comment ces scripts interrogent l'appareil (ex: `/cm?cmnd=...`).
   - Fais en sorte que si le fichier `.gplug` n'existe pas (ou contient `localhost:8080`), ces scripts pointent automatiquement vers `http://localhost:8080` (l'émulateur).

### 4. Mettre à jour les instructions (`AGENTS_FR.md` / `README_FR.md`)
- Mets à jour `AGENTS_FR.md` (et `AGENTS.md` si lu par l'agent) pour expliquer que les tests et déploiements se font désormais via `docker compose up -d emulator` et `./upload.sh`, et non plus sur un appareil physique.
- Ajoute une courte section dans `README_FR.md` indiquant comment démarrer l'émulateur (`docker compose up -d emulator`), accéder à l'interface (`http://localhost:8080/` et `http://localhost:8080/emu`) et déployer avec `./upload.sh`.

### 5. Validation de bout en bout
Une fois les modifications effectuées :
1. Lance `docker compose up -d emulator` dans `ki-workshop_FR`.
2. Exécute `./upload.sh app/spot.be app/autoexec.be`.
3. Vérifie via `curl` ou `./log.sh` que l'application démarre sans erreur Berry (`BRY:`) et que la courbe des prix s'affiche bien sur `http://localhost:8080/`.
4. Résume-moi les fichiers créés/modifiés et les commandes à utiliser pour faire mes exercices.
