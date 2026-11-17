# Configuration : opencode avec accès personnel

Pour le travail après l'atelier : agent de codage [opencode](https://opencode.ai) utilisant un
modèle open source d' [Infomaniak AI Services](https://www.infomaniak.com/en/hosting/ai-services/open-source-models)
(traitement en Suisse) ou Claude d'Anthropic. Ce n'est pas nécessaire le jour de l'atelier, car
l'accès sera déjà intégré dans l'image Docker. Temps requis : environ 15 min.

Commandes pour Linux, macOS et Ubuntu sous WSL. Pour Windows avec PowerShell :
[`WINDOWS_POWERSHELL.md`](WINDOWS_POWERSHELL.md).

## 1. Activer les outils d'IA d'Infomaniak (AI Tools)

1. Créez un compte ou connectez-vous : <https://manager.infomaniak.com>.
2. Ouvrez la section AI Tools : <https://manager.infomaniak.com/v3/ng/products/cloud/ai-tools> et
commandez/activez le produit (un seul par organisation). Les nouveaux clients bénéficient d'un million de crédits gratuits
valables pendant un mois. Une **carte de crédit** doit être enregistrée ; sans cela, l'API ne répondra pas. 
Recommandation : définissez une **limite de dépenses**.
3. Notez l'**ID du produit** (Product-ID) : il s'agit du nombre présent dans l'URL (`…/products/cloud/ai-tools/<PRODUCT_ID>`).

## 2. Créer un jeton (token) API

1. <https://manager.infomaniak.com/v3/ng/profile/user/token/list> → **Créer un jeton**.
2. Sélectionnez la portée (scope) **AI Tools** (`ai-tools`) ; définissez la durée de validité selon vos besoins.
3. **Copiez immédiatement** le jeton, car il ne s'affichera qu'une seule fois.

> **Sécurité :** L'utilisation de ce jeton entraîne des coûts. Ne le publiez jamais dans un dépôt de code (commit),
> et ne le montrez pas dans des discussions ou des captures d'écran. Si vous n'en avez plus besoin,
> révoquez-le via le Manager. 

## 3. Tester l'accès et définir les variables

```sh
export INFOMANIAK_PRODUCT_ID=123456          # votre propre ID de produit
export INFOMANIAK_API_KEY=xxxxxxxxxxxxxxxx   # votre propre jeton (token)

curl -s https://api.infomaniak.com/2/ai/$INFOMANIAK_PRODUCT_ID/openai/v1/models \
-H "Authorization: Bearer $INFOMANIAK_API_KEY"
```

Résultat attendu : un JSON contenant `"data": [...]` et des identifiants de modèles. Si vous obtenez `"Invalid Authentication"`, cela signifie que le jeton ou l'ID de produit est incorrect, ou qu'aucune carte bancaire n'est enregistrée.

La commande `export` ne s'applique qu'au terminal actuel ; `opencode` ne peut accéder qu'aux variables définies dans le terminal depuis lequel il est lancé. Pour une configuration permanente, ajoutez les deux lignes `export` à la fin du fichier `~/.bashrc` (ou `~/.zshrc` sous macOS) — par exemple en utilisant `nano ~/.bashrc` — puis ouvrez un **nouveau** terminal. Notez que le jeton sera alors stocké en clair dans votre répertoire personnel (home directory) ; veillez donc à ce que cela ne concerne que votre propre ordinateur portable.

Vérification (le jeton n'est pas affiché) ; le résultat attendu est `ID=123456 KEY=gesetzt` :

```sh
echo "ID=$INFOMANIAK_PRODUCT_ID KEY=${INFOMANIAK_API_KEY:+gesetzt}"
```

## 4. Lancer opencode

**Par défaut : Docker.** L'agent n'a accès qu'au dossier de l'atelier (workshop). Pour configurer Docker, consultez la section *Ce dont vous avez besoin* dans le fichier `RUNBOOK.md`. Dans le dossier de l'atelier :

```sh
./docker-run.sh             # opencode dans le conteneur
./docker-run.sh bash        # Shell dans le conteneur, test : opencode --version → v2.0.32
./docker-run.sh --build     # Construire l'image localement à partir du Dockerfile (2–3 min)
```

En dehors du tag de l'atelier, le script télécharge l'image de base sans accès préconfiguré : les variables de l'étape 3
doivent être définies.

Les variables `INFOMANIAK_*` définies sont prioritaires sur les accès intégrés à l'image ; `GPLUG` est
transmis. Les sessions sont conservées dans le volume Docker `gplug-workshop-data`. L'image contient également
`berry` (test de bureau) et `git`. Depuis le conteneur, le gPlug n'est accessible que via son **adresse IP**
(pas via `.gplug` ou les noms en `.local`).

**Sans Docker** (uniquement si Docker n'est pas disponible) : `curl -fsSL https://opencode.ai/v2/install | bash`
(sans `/v2`, c'est la version 1.x qui est installée ; pour une version 1.x existante : `opencode upgrade --major`). Ensuite, placez-vous dans le dossier du dépôt et lancez `opencode`. L'agent a alors accès à l'intégralité du notebook ; bien que `opencode.json` et `AGENTS.md` permettent de restreindre cet accès, ils ne garantissent pas une isolation totale : lisez bien les commandes shell avant de les valider.

Après le démarrage, l'inscription `Qwen3.5 122B-A10B (Infomaniak AI (Schweiz))` s'affiche en bas de l'interface (TUI). Première question :
`Lies app/spot.be. Erkläre in 5 Sätzen, was die App tut.` Le fichier `AGENTS.md` est chargé automatiquement ;
la commande `/init` n'est pas nécessaire.

| Commande dans la TUI | Action |
|---|---|
| `/models` | Changer de modèle |
| `/new` | nouvelle session (contexte réinitialisé) |
| `/undo`, `/redo` | annuler / rétablir la dernière modification effectuée par l'agent |
| `Shift+Tab` | changer d'agent : **build** (modifie les fichiers) ↔ **plan** (lecture/planification uniquement) |
| `@fichier` | ajouter un fichier au contexte, par ex. `@TASMOTA_BERRY_API.md` |

## 5. Configuration du fournisseur

Le fichier [`opencode.json`](opencode.json) présent dans le dépôt définit le fournisseur `infomaniak`. opencode le lit
au démarrage depuis le dossier du dépôt. Voici l'essentiel :

```json
"options": {
"baseURL": "https://api.infomaniak.com/2/ai/{env:INFOMANIAK_PRODUCT_ID}/openai/v1",
"apiKey": "{env:INFOMANIAK_API_KEY}"
},
"model": "infomaniak/Qwen/Qwen3.5-122B-A10B-FP8",
"small_model": "infomaniak/mistralai/Ministral-3-14B-Instruct-2512"
```

`{env:…}` lit les variables définies à l'étape 3 ; le jeton (token) et l'identifiant ne sont jamais stockés dans le fichier. `small_model`
gère les tâches auxiliaires (comme les titres de session). Le bloc `permission` autorise les modifications au sein du dépôt,
demande une confirmation pour les commandes shell, et interdit `rm`, `sudo` ainsi que l'accès à des emplacements situés en dehors du dépôt.
Alternativement, vous pouvez fournir le jeton via `opencode` : `/connect` → **Other** → `infomaniak` ; l'identifiant `INFOMANIAK_PRODUCT_ID` reste toutefois requis.

## 6. Sélection d'un modèle

La capacité à **appeler des outils** (tool calling) de manière fiable est essentielle pour les agents. Les tarifs pour 1 million de jetons (entrée/sortie) sont basés sur
[models.dev](https://models.dev) en date d'octobre 2026.

| ID du modèle | Contexte | Prix (entrée/sortie) | Cas d'usage |
|---|---|---|---|
| `Qwen/Qwen3.5-122B-A10B-FP8` | 200k | 0,50 / 3,97 | **Standard** : rapide, performant en programmation, économique |
| `moonshotai/Kimi-K2.6` | 256k | 0,74 / 3,72 | L'agent le plus performant pour les tâches complexes |
| `Qwen/Qwen3.5-397B-A17B-FP8` | 200k | 0,99 / 4,46 | Solution de repli si le modèle 122B rencontre des difficultés |
| `mistralai/Mistral-Small-4-119B-2603` | 256k | 0,25 / 0,93 | | abordable, européen |
| `mistralai/Ministral-3-14B-Instruct-2512` | 100k | 0,37 / 0,50 | `small_model`, tâches auxiliaires |

Ajoutez d'autres modèles à la section `models` du fichier `opencode.json` (en utilisant l'identifiant exact tel qu'indiqué à
l'étape 3). Les modèles d'« embedding » (plongement lexical, ex. : `bge_…`, `mini_lm_…`) ne sont pas adaptés aux agents.

### Alternative : les modèles Claude d'Anthropic

Un fournisseur intégré à opencode ; le fichier `opencode.json` reste utilisé. Le traitement s'effectue chez Anthropic (États-Unis).
Un abonnement claude.ai (Pro/Max) ne s'applique **pas** à opencode ; une **clé API** est nécessaire.

1. <https://console.anthropic.com> : créez un compte, ajoutez du crédit dans la section **Billing** (Facturation) et
définissez une limite de dépenses.
2. **API Keys** (Clés API) → **Create Key** (Créer une clé) ; copiez-la immédiatement.
3. Dans opencode : `/connect` → **Anthropic** → **Manually enter API Key** (Saisir manuellement la clé API). Si vous utilisez Docker, cette clé est
stockée dans le volume `gplug-workshop-data`.
4. `/models` → par ex. `claude-sonnet-5-5` (standard) ou `claude-haiku-5-5` (abordable).

Si vous n'utilisez pas Docker, vous pouvez également employer la commande `export ANTHROPIC_API_KEY=…`. Pour définir cette variable de manière permanente,
ajoutez `"model": "anthropic/claude-sonnet-5-5"` dans `opencode.json`. Les mêmes règles de sécurité s'appliquent
que pour le jeton (token) Infomaniak.

## 7. Flux de travail (Workflow)

1. **Planifiez** en utilisant l'agent `plan` avec le modèle de prompt (prompt template) fourni dans `EXERCISES.md`.
2. **Fournissez le contexte** : `@TASMOTA_BERRY_API.md @app/spot.be` — sinon, les modèles risquent
d'halluciner (d'inventer information). API Tasmota.
3. **Procédez par étapes** en utilisant l'agent `build`.
4. **Testez** sur l'appareil ; rapportez le message d'erreur obtenu dans la console, **tel quel** (mot pour mot).
5. Enregistrez les versions fonctionnelles (créez une copie de `app/spot.be` ou utilisez `git commit`) ; si vous faites fausse route, utilisez la commande `/undo`.

## Dépannage

| Symptôme | Cause / Solution |
|---|---|
| `Invalid Authentication` (401) | Jeton (token) incorrect ou expiré, ID de produit erroné, ou carte bancaire manquante |
| Le fournisseur `infomaniak` est absent de `/models` | `opencode` n'a pas été lancé depuis le dossier du dépôt, ou le fichier `opencode.json` contient une erreur JSON |
| `method_not_found` | `INFOMANIAK_PRODUCT_ID` n'est pas défini dans la session de terminal actuelle (voir étape 3) |
| `model not found` | L'ID du modèle ne correspond pas ; vérifiez la liste fournie à l'étape 3 |
| L'agent « discute » mais n'effectue aucune modification | L'agent `plan` est actif (`Shift+Tab`), ou le modèle possède des capacités limitées en matière d'appel d'outils (essayez Qwen 3.5 ou Kimi K 2.6) |
| Réponses tronquées | Augmentez la valeur `limit.output` du modèle dans `opencode.json` |
| L'agent ne parvient pas à joindre gPlug dans le conteneur | Utilisez une adresse IP plutôt qu'un nom d'hôte en `.local` dans `.gplug` ; assurez-vous que les appareils sont sur le même réseau Wi-Fi |
| Un fichier dans le conteneur appartient à `root` (Linux) | Lancez le conteneur via `./docker-run.sh` plutôt qu'en exécutant directement `docker run` |
| Suivi des coûts | Infomaniak Manager → Outils IA → Utilisation |

## Ressources

- Outils IA Infomaniak : <https://www.infomaniak.com/fr/support/faq/2845> · API : <https://developer.infomaniak.com/docs/api>
- opencode : <https://opencode.ai/docs/> (fournisseurs, autorisations)
- Catalogue de modèles : <https://models.dev>
- Anthropic : <https://console.anthropic.com> · <https://docs.anthropic.com/en/docs/about-claude/models>