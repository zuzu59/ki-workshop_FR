# Mission : intégrer l’émulateur gPlug à `ki-workshop_FR`

## Objectif

Permettre de suivre et tester l’atelier Smart Energy en français avec l’émulateur local Tasmota/Berry, sans boîtier physique. L’émulateur doit être accessible sur `http://localhost:8080`. Conserver autant que possible la possibilité de déployer sur un gPlug physique.

## Dépôts et limites

Le dépôt cible est `ki-workshop_FR`. L’émulateur d’origine se trouve dans `glue-workshop-smart-energy` et contient notamment `emulator/`, `docker/`, `docker-compose.yml` et `build.sh`.

Respecte les instructions `AGENTS.md` du dépôt cible. Ne lis ni ne modifies de fichiers hors du dépôt cible sans autorisation explicite. Si les sources nécessaires de l’émulateur ne sont pas disponibles dans le périmètre autorisé, arrête-toi et demande à l’utilisateur de les rendre accessibles ou de confirmer l’accès. Ne copie aucun secret, identifiant ou fichier local sensible.

## Travail demandé

### 1. Examiner le dépôt cible et l’émulateur

- Lire les consignes du dépôt, `app/autoexec.be`, `app/spot.be`, `upload.sh`, `brcmd.sh`, `log.sh` et la documentation existante.
- Si les sources de l’émulateur sont accessibles dans le périmètre autorisé, examiner son `build.sh`, ses fichiers Docker et les endpoints HTTP réellement exposés.
- Avant toute modification, résumer brièvement le plan, les points d’intégration et les éventuelles contraintes ou informations manquantes.

### 2. Intégrer l’infrastructure

- Ajouter l’infrastructure nécessaire à l’émulateur (`emulator/`, `docker/`, `build.sh` et services requis dans `docker-compose.yml`).
- Fusionner avec la configuration existante sans supprimer ni casser les services utiles.
- Ajouter `build/` et `.tmp_build/` à `.gitignore`.
- Vérifier que le processus de compilation n’inclut pas `app/steps/` et ne confond pas `app/autoexec.be` avec le fichier `autoexec.be` généré. Utiliser un répertoire de préparation propre si nécessaire.
- N’ajuster `spot.be` ou `autoexec.be` que si l’inspection confirme un problème de compatibilité. Ne pas activer un mode simulation ni inventer des API sans preuve dans le code ou la documentation de l’émulateur.

### 3. Adapter les commandes de déploiement et de diagnostic

Adapter `upload.sh`, `brcmd.sh` et `log.sh` pour utiliser l’émulateur local par défaut lorsque `.gplug` est absent, ou qu’il désigne explicitement `localhost:8080`. Préserver le fonctionnement avec un gPlug physique si `.gplug` indique une autre adresse.

Pour `upload.sh` :
- Préparer une source ne contenant que les fichiers nécessaires, notamment `app/spot.be` et `app/autoexec.be`, sans le dossier `app/steps/`.
- Compiler et téléverser via les outils Docker de l’émulateur, selon les interfaces effectivement disponibles.
- Maintenir la compatibilité avec les invocations documentées, notamment `./upload.sh app/spot.be app/autoexec.be`, ou mettre à jour la documentation si l’interface doit changer.
- Ne pas ignorer silencieusement des arguments qui influencent le comportement.

Pour `brcmd.sh` et `log.sh`, confirmer les endpoints et formats de requête à partir du code de l’émulateur avant de les modifier.

### 4. Mettre à jour la documentation

Mettre à jour les fichiers de documentation français pertinents (`AGENTS_FR.md`, `AGENTS.md` si nécessaire, et `README_FR.md`) pour expliquer :

```sh
docker compose up -d emulator
./upload.sh
```

Indiquer les interfaces `http://localhost:8080/` et `http://localhost:8080/emu`, ainsi que la procédure de diagnostic. Garder les instructions pour le matériel physique si cette compatibilité est conservée. Éviter les consignes qui contredisent les instructions du dépôt.

### 5. Valider et rendre compte

Si l’environnement et les dépendances sont disponibles :

1. Démarrer l’émulateur avec `docker compose up -d emulator`.
2. Déployer l’application avec la commande documentée, par exemple `./upload.sh app/spot.be app/autoexec.be`.
3. Vérifier les journaux et l’état de l’application, rechercher les erreurs Berry (`BRY:`) et confirmer que l’interface web répond.
4. Exécuter les tests ou contrôles disponibles.

Ne prétends pas qu’une validation a réussi si elle n’a pas été exécutée. Si une étape échoue deux fois avec la même erreur, arrête-toi, rapporte l’erreur exacte et demande conseil.

Termine par un résumé concis des fichiers modifiés, des vérifications effectuées et des commandes à utiliser pour l’atelier. Signale clairement toute validation impossible ou tout point restant.
