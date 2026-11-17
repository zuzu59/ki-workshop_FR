# Runbook – Configuration sur place

Objectif : passer, en **40 min**, de votre ordinateur portable et du gPlug à un agent opérationnel ainsi qu'au « Starter » installé sur l'appareil. Ensuite, place aux exercices (`EXERCISES.md`). Chaque étape indique ce que vous devriez observer.
Si quelque chose diffère : levez la main, des assistants viendront vous aider. Glossaire : [`LEGENDE.md`](LEGENDE.md).

| Étape | Action | Durée |
|---|---|---|
| 1 | Télécharger le dossier de l'atelier | 5 min |
| 2 | Identifiants pour le modèle de langage | – |
| 3 | Charger l'image Docker, tester l'agent | 10 min |
| 4 | Connecter le gPlug au Wi-Fi de l'atelier | 10 min |
| 5 | Vérifier le firmware et le fuseau horaire | 5–10 min |
| 6 | Installer le « Starter » sur l'appareil | 5 min |

Commencez par l'ordinateur portable (étapes 1 à 3), puis passez au gPlug (étapes 4 et 5) avec l'aide des assistants, et enfin installez le « Starter » (étape 6).

## Ce dont vous avez besoin

- Matériel à apporter : gPlug, ordinateur portable avec son chargeur, câble de données USB (pas un simple câble de recharge), éditeur de texte.
[Docker Desktop](https://docs.docker.com/get-started/get-docker/) doit être installé et opérationnel. Si Docker Desktop manque : le téléchargement pèse environ 1 Go et l'installation prend 10 min ; lancez cette opération en priorité. L'idéal est de le faire avant de venir.
- Sur la table : une fiche contenant les informations du Wi-Fi de l'atelier (nom du réseau et mot de passe).
- Terminal : *Terminal* sous macOS, n'importe quel terminal sous Linux, et **Ubuntu via WSL** sous Windows (voir ci-dessous). Exécutez toutes les commandes depuis le dossier de l'atelier. Les blocs de code peuvent être copiés et exécutés tels quels ; ils vous demanderont les valeurs nécessaires. Vérification du bon fonctionnement de Docker :

```sh
docker run --rm hello-world
```

Pour Windows (configuration unique, avant l'installation de Docker Desktop ; Windows sans Ubuntu, via PowerShell uniquement :
[`WINDOWS_POWERSHELL.md`](WINDOWS_POWERSHELL.md)) :
1. Ouvrez PowerShell **en tant qu'administrateur** (clic droit sur le menu Démarrer → *Terminal (Administrateur)*),
puis redémarrez votre ordinateur. Si Windows indique que la virtualisation est désactivée, activez *Intel VT-x* ou *AMD-V/SVM* dans le BIOS/UEFI. 
```powershell
wsl --install -d Ubuntu
```
2. Ouvrez Ubuntu (menu Démarrer → *Ubuntu*) et définissez un nom d'utilisateur et un mot de passe pour Linux.
3. Installez Docker Desktop, puis allez dans *Settings* → *Resources* → *WSL integration*, activez *Ubuntu* et cliquez sur *Apply & restart*. Ensuite, exécutez le test Docker mentionné plus haut depuis Ubuntu.

Connectez d'abord votre ordinateur au réseau Wi-Fi de l'atelier ; les étapes 1 à 3 nécessitent une connexion Internet.

## 1. Téléchargement du dossier de l'atelier

```sh
cd ~
curl -L -o ki-workshop.zip https://github.com/gplug-ch/ki-workshop/archive/refs/heads/main.zip
unzip -q ki-workshop.zip && mv ki-workshop-main ki-workshop && rm ki-workshop.zip
cd ki-workshop
```

Si Ubuntu affiche `unzip: command not found`, installez le paquet correspondant, puis répétez les commandes ci-dessus. 

```sh
sudo apt install -y unzip
```

Si vous connaissez Git, clonez plutôt le dépôt :

```sh
cd ~
git clone https://github.com/gplug-ch/ki-workshop.git
cd ki-workshop
```

Vérifiez le contenu ; vous devriez y trouver, entre autres, `RUNBOOK.md`, `EXERCISES.md`, `app` et `docker-run.sh` :

```sh
ls
```

## 2. Identifiants pour le modèle de langage

Rien à faire : l'accès à Infomaniak prévu pour l'atelier est déjà intégré dans l'image Docker. Il n'est valide que le jour de l'atelier. Si vous souhaitez utiliser vos propres accès (Infomaniak ou Claude), consultez `SETUP_OPENCODE.md`, étape 3 ou la section *Alternative : modèles Claude d'Anthropic*.

## 3. Charger l'image Docker et tester l'agent

1. Chargez l'image et vérifiez la version d'opencode. Lors de la première exécution, le script télécharge l'image depuis GitHub (environ 300 Mo, 1 à 2 minutes). Résultat attendu : `opencode v2.0.32`. 
```sh
./docker-run.sh opencode --version
```
2. Uniquement si vous avez cloné le dépôt : configurez votre identité pour les commits (le script vous demandera votre nom et votre adresse e-mail). Sinon, passez cette étape (vous pourrez sauvegarder votre travail en copiant le fichier `app/spot.be` durant l'exercice) :
```sh
./docker-run.sh bash -c 'read -rp "Name: " n; read -rp "E-Mail: " e; git config user.name "$n"; git config user.email "$e"'
```
3. Lancez l'agent :
```sh
./docker-run.sh
```
Résultat attendu : l'interface opencode s'affiche, avec le modèle `Qwen3.5 122B-A10B (Infomaniak AI (Schweiz))` indiqué en bas. 4. Saisir la première question :
```
Lis app/spot.be. Explique en 5 phrases ce que fait l'application. 
```
Résultat attendu : L'agent lit les fichiers (les appels aux outils sont visibles) et fournit une réponse pertinente. 
Quitter avec `/exit`.

## 4. Connexion du gPlug au réseau Wi-Fi de l'atelier

L'appareil ne connaît que votre réseau Wi-Fi domestique et ne le trouve pas ici.

1. Branchez le gPlug à un ordinateur portable ou à un adaptateur secteur via un câble USB, puis patientez 1 à 2 minutes.
2. À l'aide de votre ordinateur portable ou de votre smartphone, recherchez le réseau Wi-Fi du gPlug (le nom commence par `gPlug` ou `tasmota`) et connectez-vous. Si aucune page ne s'ouvre automatiquement, saisissez `http://192.168.4.1` dans votre navigateur.
3. Sélectionnez le réseau Wi-Fi de l'atelier, saisissez le mot de passe indiqué sur la fiche, puis cliquez sur *Enregistrer* (Speichern). La page affichera la **nouvelle adresse IP** du gPlug : notez-la.
4. Reconnectez votre ordinateur portable au réseau Wi-Fi de l'atelier, puis ouvrez `http://<adresse-ip-du-gplug>` dans votre navigateur. 

Résultat attendu : La page d'accueil Tasmota du gPlug s'affiche.

Si le réseau Wi-Fi du gPlug n'apparaît pas après 3 minutes, faites appel à un animateur.

## 5. Vérification du firmware, fuseau horaire

Les noms des menus correspondent à ceux du gPlug (en allemand ; les équivalents en anglais sont indiqués entre parenthèses).

1. *Informationen* (*Information*), ligne *Tasmota Version* (*Program Version*) :
- **15.3.0 ou version ultérieure** : passez à l'étape 2.
- **Version antérieure** : demandez de l'aide ; ne procédez pas vous-même à la mise à jour. Le gPlug nécessite son propre firmware,
disponible sur gplug.ch (incluant un script pour le compteur) ; le firmware standard de Tasmota n'est pas compatible.
2. *Werkzeuge* (*Tools*) → *Konsole* (*Console*). Ne pas utiliser le terminal : saisissez ces deux lignes une par une dans
la console, en validant chacune par la touche Entrée. 
```
Timezone 99
```
```
Time
```
Résultat attendu : la commande `Time` affiche l'heure actuelle (avec prise en compte correcte de l'heure d'été/hiver).

Laissez la page de l'interface web (WebUI) ouverte ; vous en aurez besoin pour la suite de l'exercice.

## 6. Installation du « Starter » sur l'appareil

1. Saisissez l'adresse IP. La commande vous demande l'adresse IP obtenue à l'étape 4 (saisissez uniquement l'adresse IP, par ex. `192.168.1.50`) :
```sh
printf 'gPlug-IP: '; read -r ip; echo "$ip" > .gplug
```
2. Dans l'interface web, allez dans *Werkzeuge* (*Tools*) → *Dateisystem verwalten* (*Manage File system*) : un fichier
`autoexec.be` existe-t-il déjà ? 
- **Non** :
```sh
./upload.sh app/spot.be app/autoexec.be
```
- **Oui** : ne l'écrasez pas. Modifiez-le via l'interface web, ajoutez la ligne `load("spot")`,
enregistrez, puis exécutez uniquement :
```sh
./upload.sh app/spot.be
```

Résultat attendu : `OK  /spot.be (… Byte)`, `OK  BrRestart`, `OK  heap_free … kB`.
3. Vérifiez. Journal (log) : attendez-vous à voir `SPOT: v… geladen` ; aucun message d'erreur lié à `BRY:`
(les messages `BRY: Berry initialized` et `BRY: Successfully loaded …` sont normaux) :
```sh
./log.sh
```
État (status) : attendez-vous à un JSON contenant `"Sim":true` :
```sh
./brcmd.sh 'tasmota.cmd("SpotStatus")'
```
4. Rechargez l'interface Web (Cmd+R / F5). 

Résultat attendu : trois en-têtes (prix spot actuel, injection aujourd'hui, rémunération aujourd'hui) et un graphique
affichant une courbe de prix cyan sur une journée. Survolez le graphique avec la souris : l'heure et le prix s'affichent.

## C'est prêt ?

| Vérification | Résultat attendu |
|---|---|
| `./docker-run.sh` | opencode avec le modèle Qwen3.5 ; répond correctement |
| `./log.sh` | `SPOT: v… geladen` ; aucune erreur `BRY:` |
| `./brcmd.sh 'tasmota.cmd("SpotStatus")'` | `"Sim":true` ; Heap supérieur à 100 ko |
| Interface Web | Courbe de prix ; le curseur affiche les valeurs |

Tout est au vert ? Passez à la suite : [`EXERCISES.md`, section *Préparation*](https://github.com/gplug-ch/ki-workshop/blob/main/EXERCISES.md#vorbereitung-5-min) (notez la valeur `HeapFree`).

## Problèmes fréquents

| Symptôme | Solution |
|---|---|
| `docker: command not found` / `Cannot connect to the Docker daemon` | Lancez Docker Desktop (sous Windows : activez l'intégration WSL pour Ubuntu), ouvrez un nouveau terminal et recommencez l'étape 3 |
| Le téléchargement de l'image s'interrompt | Relancez `./docker-run.sh bash` ; vérifiez votre connexion Wi-Fi ; demandez de l'aide |
| `Permission denied` lors de l'exécution de `./upload.sh` | Exécutez `chmod +x *.sh` |
| `AVERTISSEMENT : INFOMANIAK_PRODUCT_ID … non défini` / `method_not_found` | Appeler un animateur (image de l'atelier manquante ?) |
| `ERREUR : http://… inaccessible` | Adresse IP incorrecte dans `.gplug`, ou l'ordinateur n'est pas connecté au réseau Wi-Fi de l'atelier |
| Le téléchargement indique « Espace insuffisant » | Exécuter à nouveau `./upload.sh` |
| `!! heap_free … < 100 ko : redémarrage de l'appareil` | Normal ; le script attend de lui-même (environ 20 s) |
| Graphique absent, heure incorrecte | Oubli de `Timezone 99` (étape 5.2) |
| Autres erreurs liées à l'agent | Consulter la section *Dépannage* dans `SETUP_OPENCODE.md` |

## Après l'atelier

- Reconnecter le gPlug au réseau Wi-Fi domestique : branchez-le chez vous ; il diffusera à nouveau son propre réseau Wi-Fi. Répétez l'étape 4
avec votre réseau Wi-Fi domestique.
- Utiliser les valeurs réelles du compteur intelligent (Smart Meter) au lieu du simulateur : modifiez `app/spot.be` en réglant `"sim": false`, puis exécutez `./upload.sh app/spot.be`.
- Poursuivre avec l'IA : [`SETUP_OPENCODE.md`](SETUP_OPENCODE.md) ; sans IA (utilisation d'un éditeur et téléchargement manuel) :
[`SETUP_OHNE_KI.md`](SETUP_OHNE_KI.md).

Passer à l'**exercice (45 min)** : [lien](https://github.com/gplug-ch/ki-workshop/tree/main#%C3%BCbung-45-min).
