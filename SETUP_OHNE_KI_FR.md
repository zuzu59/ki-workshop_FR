# Configuration : Développer des « Berry-Apps » sans IA

Pour travailler après l'atelier : modifiez l'application `app/spot.be` (ou une application de votre choix) à l'aide d'un éditeur de texte, puis chargez-la manuellement sur le gPlug. Aucun modèle de langage ni accès externe n'est requis. Temps estimé : environ 5 minutes.

Commandes pour Linux, macOS et Ubuntu sous WSL. Pour Windows avec PowerShell :
consultez [`WINDOWS_POWERSHELL.md`](WINDOWS_POWERSHELL.md) (scripts à exécuter dans le shell du conteneur via
`.\docker-run.ps1 bash`).

## 1. Prérequis

- Un gPlug connecté à votre réseau Wi-Fi domestique, avec une interface Web (WebUI) accessible (`http://<gplug-ip>`).
- Un éditeur de texte, par exemple VS Code.
- Pour la méthode A : un terminal avec `sh` et `curl` (disponibles par défaut sur macOS et Linux). Pour la méthode B : un simple navigateur Web.

## 2. Méthode A : Utilisation des scripts de l'atelier (recommandé)

Il s'agit des mêmes scripts que ceux utilisés lors de l'atelier ; vous les lancez simplement vous-même.

1. Saisissez l'adresse IP (à faire une fois, ou à nouveau en cas de changement de réseau Wi-Fi) :
```sh
printf 'gPlug-IP: '; read -r ip; echo "$ip" > .gplug
```
2. Modifiez le fichier `app/spot.be` dans votre éditeur de texte et enregistrez les modifications.
3. Téléversez le fichier. Le script vérifie la taille disponible sur l'appareil, recharge l'application (`BrRestart`) et
redémarre le gPlug si la mémoire disponible (heap) tombe en dessous de 100 ko :
```sh
./upload.sh app/spot.be
```
Résultat attendu : `OK  /spot.be (… Byte)`, `OK  BrRestart`, `OK  heap_free … kB`.
4. Consultez la console. Vérifiez la présence du message `SPOT: … geladen` (chargé) ; aucun message d'erreur ne doit apparaître avec `BRY:`
(les messages `BRY: Berry initialized` et `BRY: Successfully loaded …` sont normaux) :
```sh
./log.sh
```
5. Vérifiez et rechargez l'interface Web (Cmd+R / F5) :
```sh
./brcmd.sh 'tasmota.cmd("SpotStatus")'
```

## 3. Méthode B : uniquement via le navigateur

Les noms des menus correspondent à ceux du gPlug (en allemand ; les équivalents anglais sont indiqués entre parenthèses).

1. *Werkzeuge* (*Tools*) → *Dateisystem verwalten* (*Manage File system*).
2. Sélectionnez le fichier (`app/spot.be`) et téléversez-le. Il est également possible d'effectuer de légères modifications directement à cet endroit : modifiez le fichier, puis enregistrez-le.
3. *Werkzeuge* → *Konsole* (*Console*), rechargez l'application :
```
BrRestart
```
Consultez la console : vérifiez la présence de `SPOT: … geladen` et l'absence de message d'erreur avec `BRY:`.
4. Vérifiez la mémoire tas (*heap*) ; elle doit être supérieure à 100 ko. Chaque commande `BrRestart` consomme environ 1 ko ; seul un redémarrage complet permet de récupérer cet espace :
```
Br tasmota.gc() return tasmota.memory("heap_free")
```

Si la valeur est inférieure à 100 ko, exécutez `Restart 1` (le gPlug redémarrera, ce qui prend environ 20 secondes).

## 4. Optionnel : test sur ordinateur portable

Détectez les erreurs rapidement, sans avoir besoin de téléverser des fichiers. L'interpréteur `berry` est inclus dans l'image Docker ; en l'absence d'accès au modèle linguistique, `docker-run.sh` affichera simplement un `HINWEIS` (avertissement/note), mais le shell restera fonctionnel. 
```sh
curl -s -o app/bkw.json https://api.bkw.ch/api/dyntariffs/v1/Tariffs/energyreturn   # une seule fois
./docker-run.sh bash
cd app && berry desktop_harness.be
```

Résultat attendu : la dernière ligne doit être `HARNESS OK`.

## 5. Règles pour Berry sur le gPlug

S'appliquent avec ou sans IA. Détails dans [`AGENTS.md`](AGENTS.md) §6 ; API décrite dans
[`TASMOTA_BERRY_API.md`](TASMOTA_BERRY_API.md).

- Aucun callback ne doit dépasser 50 ms ; divisez les tâches longues à l'aide de `tasmota.set_timer`.
- Mémoire vive (RAM) limitée (~110 ko disponibles) : évitez les chaînes de caractères ou les listes volumineuses ; envoyez le code HTML par fragments.
- Enveloppez le corps de chaque callback dans un bloc `try ... except .. as e, m ... end`.
- Déclarez les nouvelles variables d'instance avec `var` (mode strict).
- Préservez la mémoire flash : limitez l'écriture de fichiers.
- Insérez vos ajouts au niveau des commentaires `# ERWEITERUNGSPUNKT` (point d'extension) dans `app/spot.be`.
- Sauvegardez les versions fonctionnelles : `cp app/spot.be spot_v1.be` ou `git commit`.

## Dépannage

| Symptôme | Cause / Solution |
|---|---|
| Ligne commençant par `BRY:` suivie d'un numéro | Erreur de syntaxe ou d'exécution ; vérifiez la ligne correspondante dans `app/spot.be` |
| `FEHLER: http://… nicht erreichbar` | Adresse IP incorrecte dans `.gplug` ou l'ordinateur n'est pas sur le même réseau Wi-Fi |
| Le téléversement indique `Nicht genug Speicherplatz` (espace insuffisant) | Relancez `./upload.sh` ; dans la méthode B, rouvrez la page *Gérer le système de fichiers* |
| Le curseur sur le graphique n'affiche rien | Rechargez la page de l'interface web (WebUI) |
| Perdu(e) ? | Copier le point de contrôle `app/steps/spot_N.be` vers `app/spot.be`, puis le téléverser |

## Sources

- Référence du langage Berry : <https://tasmota.github.io/docs/_media/BERRY_LANGUAGE_REFERENCE.txt>
- Tasmota Berry : <https://tasmota.github.io/docs/Berry/>
