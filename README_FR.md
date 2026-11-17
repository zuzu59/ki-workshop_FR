# Application « Prix spot » pour gPlug (Tasmota Berry)

![Du modèle de base (à gauche, courbe de prix uniquement) à l'application de référence (à droite) en 4 étapes](docs/stufen.png)

*Du modèle de base (à gauche, prix spot uniquement) à l'application de référence (à droite) : injection, prix négatifs, horizon de 3 jours,
rémunération. Lors de l'atelier, vous réaliserez ces étapes avec l'aide d'un agent de codage.*

Supports pour l'atelier DIY **« Travailler avec un agent de codage sur un appareil embarqué »**.
Version des supports : voir le fichier `VERSION`. L'application Berry pour le [gPlug](https://gplug.ch) récupère les
tarifs dynamiques d'injection (pour les installations photovoltaïques domestiques), mesure l'énergie injectée et affiche le tout sous forme de graphique dans
l'interface web de Tasmota.

## Programme

Détails par session dans le dossier [`workshop-instances/`](workshop-instances/) :

- [Jeu 12.11.2026, 17h00–20h00](workshop-instances/2026-11-12.md)

## Matériel à prévoir

Votre propre gPlug ([gplug.ch](https://gplug.ch)), un ordinateur portable (macOS, Linux ou Windows avec Ubuntu via WSL) accompagné de son chargeur,
et un câble de données USB. Logiciels requis : [Docker Desktop](https://docs.docker.com/get-started/get-docker/)
et un éditeur de texte. Aucune autre préparation n'est nécessaire.

## Introduction

Diapositives d'introduction : <https://zuzu59.github.io/ki-workshop_FR/slides/>

## Configuration sur place

Guide étape par étape avec les résultats attendus : [`RUNBOOK_FR.md`](RUNBOOK_FR.md). En résumé :

1. Téléchargez le dossier de l'atelier (au format ZIP) et lancez `./docker-run.sh`. Chargement
Charge l'image prête à l'emploi et lance l'agent opencode. L'accès au modèle de langage
est intégré.
2. Connectez le gPlug au réseau Wi-Fi de l'atelier et ouvrez `http://<gplug-ip>`. Vérifiez le firmware et le fuseau horaire.
3. Saisissez l'adresse IP et chargez le programme de démarrage :
```sh
echo <gplug-ip> > .gplug
./upload.sh app/spot.be app/autoexec.be
./log.sh                                  # résultat attendu : SPOT: v… chargé, aucune erreur BRY
```
L'interface web affiche désormais la courbe des prix (simulateur ; aucun compteur intelligent requis).

Commandes pour Linux, macOS et Ubuntu sous WSL. Pour Windows, utilisez uniquement PowerShell :
[`WINDOWS_POWERSHELL.md`](WINDOWS_POWERSHELL_FR.md).

## Exercice (45 min)

Déroulement, prompts et étapes de vérification : [`EXERCISES_FR.md`](EXERCISES_FR.md) ([PDF, A4](docs/EXERCISES.pdf)).

1. Graphique en barres de l'énergie avec axe en kWh — **Obligatoire**
2. Prix négatif : barres en orange, zone sous 0 ombrée — **Obligatoire**
3. 3 jours avec valeurs horaires — pour les plus rapides
4. Graphique de rémunération avec Σ — pour les plus rapides

En cas de blocage : copiez le point de contrôle de l'étape précédente (`app/steps/spot_N.be`) vers `app/spot.be`.

## Après l'atelier

- Reconnectez le gPlug à votre réseau Wi-Fi domestique.
- Pour une utilisation avec un compteur intelligent : définissez `"sim": false` dans `app/spot.be` et exécutez `./upload.sh app/spot.be`.
- Poursuivez le travail avec votre propre accès au modèle de langage : [`SETUP_OPENCODE_FR.md`](SETUP_OPENCODE.md) ;
construisez l'image localement avec `./docker-run.sh --build`. - Poursuivre le travail sans IA, en utilisant uniquement un éditeur de texte et un transfert manuel (via script ou interface web) :
[`SETUP_OHNE_KI.md`](SETUP_OHNE_KI_FR.md).

## Fichiers importants

- `app/spot.be` – l'application sur laquelle vous travaillez. `app/steps/` – points de contrôle (checkpoints) après chaque étape.
- `upload.sh`, `brcmd.sh`, `log.sh` – outils de gestion de l'appareil (téléversement, exécution de commandes Berry, console).
- `AGENTS_FR.md` – règles destinées à l'agent de codage (lit automatiquement `opencode`).
- `LEGENDE_FR.md` – terminologie et abréviations.
- `WINDOWS_POWERSHELL_FR.md` – spécificités pour Windows (sans Ubuntu).


## Licence

MIT, voir `LICENSE`.