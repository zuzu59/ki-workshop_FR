# Windows sans Ubuntu : PowerShell

L'utilisation d'Ubuntu dans WSL est recommandée (voir [`RUNBOOK.md`](RUNBOOK.md), section *Prérequis*) ; toutes les commandes indiquées dans les supports y sont valables telles quelles. Cette page s'adresse uniquement aux utilisateurs sous Windows **sans** terminal Ubuntu : Docker Desktop avec WSL 2 est utilisé, et les commandes sont exécutées dans PowerShell. Seules les différences sont mentionnées ici.

## RUNBOOK Étape 1 : Télécharger le dossier de l'atelier

```powershell
cd $HOME
Invoke-WebRequest https://github.com/gplug-ch/ki-workshop/archive/refs/heads/main.zip -OutFile ki-workshop.zip
Expand-Archive ki-workshop.zip -DestinationPath . ; Rename-Item ki-workshop-main ki-workshop ; Remove-Item ki-workshop.zip
cd ki-workshop
```

## RUNBOOK Étape 3 : Charger l'image Docker, démarrer l'agent

Au lieu de `./docker-run.sh`, utilisez :

```powershell
.\docker-run.ps1 bash           # Shell dans le conteneur
.\docker-run.ps1                # opencode dans le conteneur
.\docker-run.ps1 --build        # Construire l'image localement (après l'atelier)
```

Si PowerShell affiche une erreur `UnauthorizedAccess` ou indique que « l'exécution de scripts est désactivée », autorisez-la dans la fenêtre actuelle (cette autorisation ne s'applique qu'à cette fenêtre), puis relancez la commande :

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

## RUNBOOK Étape 6 et exercice : Scripts pour les appareils

Les commandes `upload.sh`, `log.sh`, `brcmd.sh` ainsi que `echo … > .gplug` ne fonctionnent pas directement dans PowerShell. Ouvrez d'abord le shell du conteneur (`.\docker-run.ps1 bash`) et saisissez-y les commandes comme indiqué dans les supports. L'agent (`.\docker-run.ps1`) les exécute lui-même à l'intérieur du conteneur. ## SETUP_OPENCODE Étape 3 : configuration de l'accès

Uniquement pour la fenêtre actuelle :

```powershell
$env:INFOMANIAK_PRODUCT_ID = "123456"
$env:INFOMANIAK_API_KEY    = "xxxxxxxxxxxxxxxx"

curl.exe -s "https://api.infomaniak.com/2/ai/$env:INFOMANIAK_PRODUCT_ID/openai/v1/models" `
-H "Authorization: Bearer $env:INFOMANIAK_API_KEY"
```

De manière permanente pour votre utilisateur ; ensuite, fermez **toutes** les fenêtres du terminal et rouvrez-les :

```powershell
[Environment]::SetEnvironmentVariable("INFOMANIAK_PRODUCT_ID", "123456", "User")
[Environment]::SetEnvironmentVariable("INFOMANIAK_API_KEY", "xxxxxxxxxxxxxxxx", "User")
```

Vérification (le jeton n'est pas affiché) ; le résultat attendu est `ID=123456 KEY=True` :

```powershell
"ID=$env:INFOMANIAK_PRODUCT_ID KEY=$([bool]$env:INFOMANIAK_API_KEY)"
```

Les variables Windows ne sont pas visibles sous Ubuntu/WSL ; utilisez le fichier `~/.bashrc` dans cet environnement.