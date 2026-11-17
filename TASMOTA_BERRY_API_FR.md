# API Berry pour Tasmota — Aide-mémoire

Référence concise de l'API Berry spécifique à Tasmota (ESP32). Ce document complète la référence du *langage* Berry
(<https://tasmota.github.io/docs/_media/BERRY_LANGUAGE_REFERENCE.txt>), qui couvre la syntaxe, les listes, les tables (maps), les octets,
les chaînes de caractères, le format `json` et la gestion des fichiers (`file`), mais **ne traite pas** les fonctions présentées ci-dessous. Source : <https://tasmota.github.io/docs/Berry/>,
synthétisée pour répondre aux besoins d'une application de traitement de données ou de télémétrie. Vérifié par rapport à la documentation au 18/10/2026.

## 1. Cycle de vie et bonnes pratiques

- Le fichier `autoexec.be` présent dans le système de fichiers est exécuté au démarrage. Il est conseillé de s'en tenir à `load("spot.be")`.
- `load("file.be")` charge et exécute un script ; la commande console `BrRestart` permet de redémarrer la machine virtuelle (VM) Berry et de réexécuter `autoexec.be` — utilisez cette méthode pour itérer sur votre code sans redémarrer l'appareil.
- Berry **bloque Tasmota pendant son exécution**. Évitez toute opération bloquante dépassant 50 ms. Pour les tâches longues, divisez-les en plusieurs étapes à l'aide de `tasmota.set_timer`. Ne jamais utiliser d'attente active (*busy waiting*).
- Les appels réseau effectués avant que le Wi-Fi ne soit opérationnel provoqueront un plantage. Encadrez toute première utilisation du réseau par `tasmota.when_network_up(f)`.
- L'horloge système n'est pas valide tant que la synchronisation NTP n'a pas eu lieu. Conditionnez toute logique temporelle par `tasmota.rtc("utc") > 1700000000`. Ne vous fiez pas à l'événement `Time#Initialized` après le démarrage : il est déclenché dès la synchronisation NTP, souvent **avant** que votre rappel (*callback*) `when_network_up` ne soit enregistré (ce qui empêcherait l'application de récupérer des données jusqu'au prochain cycle planifié). Utilisez plutôt `tasmota.set_timer(2000, …)` pour vérifier périodiquement si l'horloge est valide.
- Les exceptions non interceptées interrompent le rappel (*callback*) en cours, mais n'entraînent pas l'arrêt de Tasmota. Enveloppez systématiquement le corps de chaque fonction de rappel (callback) dans un bloc `try ... except .. as e, m log("X: " + e + " " + m, 2) end`.
- Console : `print(x)` → console Berry ; `log(msg, level)` → journal (log) Tasmota (niveau 2 = info, 3 = débogage, par défaut 3). Utilisez `log` pour tout ce qui doit être visible par l'utilisateur.
- Mémoire (Heap) : Un ESP32 sans PSRAM dispose d'environ 100 à 200 ko d'espace libre. `tasmota.memory("heap_free")` renvoie la valeur en ko. `tasmota.gc()` force le ramasse-miettes (garbage collection) et renvoie le nombre d'octets alloués par Berry.

## 2. Objet `tasmota`

### Temps

| Appel | Retourne |
|---|---|
| `tasmota.rtc()` | `{'local': epoch, 'utc': epoch, 'timezone': minutes, 'restart': epoch}` ; `tasmota.rtc("utc")` renvoie une valeur unique, sans allocation de dictionnaire (map). |
| `tasmota.time_dump(epoch)` | `{'year','month','day','hour','min','sec','weekday','epoch'}` |
| `tasmota.time_str(epoch)` | `"2021-04-27T21:53:27"` |
| `tasmota.strftime(fmt, epoch)` | `strftime` en langage C, par ex. `"%Y-%m-%d"` |
| `tasmota.strptime(str, fmt)` | Un dictionnaire (map) similaire à celui de `time_dump`, accompagné de `unparsed` (partie non analysée), ou `nil`. L'entrée est traitée comme une heure « naïve » (sans fuseau horaire explicite) ; vérifiez sur l'appareil si `epoch` correspond à l'heure UTC ou à l'heure locale avant de l'utiliser pour des chaînes de caractères au format UTC. |
| `tasmota.millis()` | Nombre de millisecondes écoulées depuis le démarrage ; utilisez `tasmota.time_reached(t)` pour effectuer des comparaisons en toute sécurité. |

### Minuteries et tâches planifiées (cron)

```berry
tasmota.set_timer(5000, f, "id")        # once, after 5000 ms; id optional
tasmota.remove_timer("id")
tasmota.defer(f)                        # run after current event loop
tasmota.add_cron("0 */15 * * * *", f, "q15")   # 6 fields, FIRST IS SECONDS; local time
tasmota.add_cron("0 0 14,16,18 * * *", f, "fetch")
tasmota.remove_cron("q15")
tasmota.next_cron("q15")                # next epoch (local)
```

Pour appeler une méthode d'une instance, utilisez une fermeture (closure) : `tasmota.add_cron("...", //-> self.tick(), "id")`.

### Règles (hooks d'événements)

```berry
tasmota.add_rule("Time#Initialized", /-> on_time_ok(), "t_init")   # NTP synced
tasmota.add_rule("Mqtt#Connected", f)
tasmota.add_rule("System#Boot", f)
tasmota.remove_rule("Time#Initialized", "t_init")
```

Signature de la fonction de règle : `def f(value, trigger, msg)`, tous les paramètres sont facultatifs.

### Commandes personnalisées

```berry
def spot_prices(cmd, idx, payload, payload_json)
  import string
  tasmota.resp_cmnd(string.format('{"SpotPrices":{"Start":"%s","Prices":[%s]}}', start, csv))
end
tasmota.add_cmd("SpotPrices", spot_prices)
```

- `cmd` : nom tel qu'enregistré ; `idx` : suffixe numérique (par défaut 1) ; `payload` : chaîne brute ; `payload_json` : map ou `nil`. - Réponses : `tasmota.resp_cmnd(json_string)` (JSON entièrement personnalisé), `resp_cmnd_done()`, `resp_cmnd_error()`, `resp_cmnd_failed()`, `resp_cmnd_str(s)`.
- Accessibles depuis la console, via `http://<ip>/cm?cmnd=SpotPrices`, ou via MQTT : `cmnd/<topic>/SpotPrices`.
- Impossible de remplacer les commandes natives. Les noms ne sont pas sensibles à la casse.
- `tasmota.cmd("Status 10", true)` permet d'exécuter n'importe quelle commande depuis Berry et renvoie une structure (map) analysée (`true` = désactive la journalisation).

### Capteurs et télémétrie

- `tasmota.read_sensors()` → renvoie une **chaîne** JSON contenant les données de tous les capteurs (similaire à `teleperiod`). À analyser avec `json.load` ; peut renvoyer `nil`.
- Dans un pilote (driver) : `json_append()` + `tasmota.response_append(',"Spot":{"Price":0.194}')` permet d'ajouter des données au message `tele/SENSOR`.

### Divers

- `tasmota.version()` → entier, par exemple `0x0F050002` (15.5.0.2). `tasmota.arch()` → `"esp32"`.
- `tasmota.wifi("ip")`, `tasmota.is_network_up`()`.
- `tasmota.scale_int(v, fromMin, fromMax, toMin, toMax)` — mise à l'échelle linéaire d'entiers ; utile pour les coordonnées SVG.
- `tasmota.urlfetch(url, filename)` — téléchargement ponctuel vers le système de fichiers ; renvoie le nombre d'octets ou -1.

## 3. Pilotes (callbacks d'événements + interface web)

Toute instance de classe enregistrée via `tasmota.add_driver(obj)` ; les méthodes sont identifiées **par leur nom** :

| Méthode | Moment d'exécution |
|---|---|
| `every_second()` | une fois par seconde |
| `every_250ms()`, `every_100ms()`, `every_50ms()` | boucles rapides — à éviter sauf nécessité absolue |
| `web_sensor()` | rendu de la page principale ; utilisez `tasmota.web_send(html)` ici (aucun autre élément ne peut y générer de sortie) |
| `json_append()` | ajout au JSON de télémétrie (`teleperiod`) ; utilisez `tasmota.response_append(...)` |
| `web_add_handler()` | serveur web opérationnel ; seul endroit sûr pour appeler `webserver.on(...)` |
| `web_add_main_button()`, `web_add_config_button()` | ajout d'un bouton via `webserver.content_send(...)` |
| `save_before_restart()` | sauvegarde de l'état avant un redémarrage |
| `mqtt_data(topic, idx, data, databytes)` | après un `mqtt.subscribe(topic)` | 

```berry
import webserver
class SpotUI
  def web_sensor()
    tasmota.web_send("{s}Spot price{m}0.194 CHF/kWh{e}")      # {s} {m} {e} = Tasmota table markup
    tasmota.web_send("<svg width='300' height='80'>...</svg>") # inline SVG works, send in chunks
  end
  def web_add_main_button()
    webserver.content_send("<p></p><form action='/spot' method='get'><button>Spot chart</button></form>")
  end
  def web_add_handler()
    webserver.on("/spot", /-> self.page(), webserver.HTTP_GET)
  end
  def page()
    webserver.content_start("Spot")       # title
    webserver.content_send_style()
    webserver.content_send("<svg ...>")   # chunked; call repeatedly, no big string needed
    webserver.content_send("</svg>")
    webserver.content_button(webserver.BUTTON_MAIN)
    webserver.content_stop()
  end
end
tasmota.add_driver(SpotUI())
```

`webserver.has_arg("x")` et `webserver.arg("x")` permettent de lire les paramètres de requête (query params). Utilisez `webserver.content_open(200, "application/json")` suivi de `content_send` et `content_close` pour des réponses brutes (raw responses).

## 4. `webclient` (HTTP/HTTPS)

```berry
var wc = webclient()
wc.begin("https://api.bkw.ch/api/dyntariffs/v1/Tariffs/energyreturn")
wc.add_header("accept", "application/json")
wc.set_timeouts(10000, 5000)
var rc = wc.GET()                   # 200 ok; negative = connection error
if rc == 200
  var s = wc.get_string()           # closes connection, frees buffers
  # ... parse s ...
  s = nil
end
wc.close()                          # harmless if already closed
wc = nil
tasmota.gc()
```

- **`get_string()` rejette les réponses > 32 Ko et les tronque silencieusement lorsque le tas (heap) est fragmenté** (réponse segmentée/chunked, aucune erreur ; observé avec 65 Ko d'espace libre : 8,7 Ko sur 21 Ko disponibles). Pour toute donnée dépassant quelques Ko, utilisez `wc.write_file("/fichier.json")` (renvoie le nombre d'octets écrits ou -1), puis analysez le contenu depuis la mémoire flash par blocs avec `f.read(2048)` (voir `parse_file` dans `app/spot.be`).
- Le mode HTTPS est non sécurisé (aucune vérification de certificat) — acceptable pour des API publiques en lecture seule. Seul le chiffrement ECDHE_RSA_AES128_GCM_SHA256 est pris en charge.
- Les redirections sont désactivées par défaut : utilisez `wc.set_follow_redirects(true)`.
- `GET()` bloque Tasmota pendant toute la durée de la requête (plusieurs centaines de millisecondes). Acceptable quelques fois par jour ; à proscrire dans une boucle rapide.
- `wc.set_auth(user, pw)`, `wc.set_useragent(s)`, `wc.POST(payload)`.

## 5. Fichiers, `path`, `persist`

```berry
import path
path.exists("/spot_2026-10.csv")    # leading "/" optional
path.listdir("/")                   # list of names
path.remove("/old.csv")             # true on success
path.rename(a, b); path.last_modified(f)

var f = open("/spot_2026-10.csv", "a")   # modes "r", "w", "a"; raises on error
f.write("2026-10-18;3.4;0.66\n")
f.close()

f = open("/bkw.json", "r")
var line = f.readline()              # "" at EOF
f.close()
```

- Le système de fichiers est LittleFS sur la mémoire flash interne, avec généralement 300 ko à 1 Mo d'espace libre. Limitez les écritures (pour éviter l'usure).
- `persist` = un petit espace de stockage clé/valeur situé dans `_persist.json` : `import persist; persist.last_start = 1760000000; persist.save()`. Sauvegarde automatique avant redémarrage. Ne convient pas aux écritures fréquentes ; ne pas utiliser pour des listes ou des dictionnaires (maps) sans appeler `persist.dirty()`.

## 6. Aide-mémoire : `string`, `json`, `bytes` (cœur de Berry, utilisés en permanence)

```berry
import string
string.find(s, "needle", from)        # index or -1
string.split(s, ";")                  # list
string.format("%.3f;%d", x, n)        # C printf subset (%d %i %s %f %.3f %x %05d)
string.tr(s, "\r", "")                # char translate/remove
s[a..b]                               # slice, inclusive; s[a..] to end
real("0.194"); int(3.7); number("12") # conversions; real() of garbage → 0
str(x)                                # to string

import json
var m = json.load(s)                  # nil on error — always check
json.dump(m)

var b = bytes(-600)                   # fixed 600 B, zero-filled
b.seti(i*2, v, 2)                     # signed 16-bit little-endian at byte offset
b.geti(i*2, 2)
b.set(0, 0x1234, 2); b.get(0, 2)      # unsigned
```

Arrondi : pas de fonction `math.round` — utilisez `int(x + 0.5)` pour x ≥ 0, et `int(x - 0.5)` pour x < 0. `import math` donne accès à `floor`, `ceil`, `abs` et `rand()`.

## 7. Points de vigilance

- **Fuites mémoire avec `f.read(n)`** (Tasmota 15.3.0) : chaque lecture d'un fichier via `f.read(2048)` entraîne une perte définitive d'environ 3 ko dans le tas (heap) Berry ; `gc()` ne permet pas de récupérer cet espace. Privilégiez la lecture par blocs avec `f.readbytes(n).asstring()` ou ligne par ligne avec `f.readline()` ; ces méthodes ne présentent pas de fuite mémoire. `f.read()` sans argument de taille fonctionne, mais nécessite de charger l'intégralité du fichier en mémoire vive (RAM).
- **`BrRestart` n'est pas sans coût** : chaque redémarrage de la machine virtuelle (VM) consomme environ 1 ko de mémoire en dehors de l'espace Berry ; seul un véritable `Restart 1` permet de récupérer cette mémoire. 20 cycles de téléversement (upload) équivalent à environ 20 ko perdus. Le script `upload.sh` redémarre automatiquement l'appareil lorsque la mémoire disponible tombe en dessous de 100 ko.
- Seuil mémoire : le protocole HTTPS nécessite environ 40 ko d'espace libre pour la négociation TLS (handshake). En dessous d'environ 50 ko, un appel à `get_string()` (pour une donnée de 21 ko) provoque le redémarrage de l'appareil (« MEMORY ALLOCATION FAILED ») ; entre 50 et 70 ko environ, la chaîne de caractères est tronquée sans avertissement. Vérifiez `tasmota.memory("heap_free")` après un appel à `tasmota.gc()` ; essayez de maintenir une valeur supérieure à 90 ko.
- Le format Cron comporte **6 champs** (les secondes en premier) et s'exécute selon l'heure **locale**, en tenant compte du changement d'heure (DST).
- L'utilisation de `tasmota.add_rule`, `add_cron` ou `add_cmd` avec un identifiant (ID) déjà existant remplace l'enregistrement précédent ; utilisez des identifiants pour éviter, par exemple, qu'une règle comme `BrRestart` ne soit enregistrée en double.
- `tasmota.web_send` ne peut être utilisé qu'au sein de `web_sensor()`, et `webserver.on` uniquement dans `web_add_handler()`. Un appel en dehors de ces contextes provoquera un plantage ou restera sans effet.
- La fonction `real()` appliquée à `"0.194"` renvoie `0.194` ; appliquée à `"abc"`, elle renvoie `0` sans générer d'exception.
- En Berry, la concaténation de chaînes de caractères (`string`) avec l'opérateur `+` nécessite que les deux opérandes soient des chaînes : `"x" + str(n)`.
- Division entière : `7 / 2` donne `3` si les opérandes sont des entiers, mais `3.5` si l'un des deux est un nombre réel.
- Les variables membres d'une classe doivent être déclarées (ex. : `var a, b`) ; tenter d'assigner une valeur à un membre non déclaré provoquera une erreur.
- Tasmota compile le code Berry en **mode strict** : la lecture d'une variable globale non déclarée entraîne une `syntax_error` lors du chargement. Pour vérifier si votre application est déjà chargée, utilisez `import global` suivi de `global.contains("spot")` ou `global.spot` ; n'utilisez jamais le nom de la variable seule.
- Pour permettre un rechargement sans problème, ajoutez ceci à la fin de votre script : `if global.contains("spot") && global.spot != nil tasmota.remove_driver(global.spot) tasmota.remove_cron(id)… end` avant de créer une nouvelle instance. Sinon, chaque appel à `load()` ajoutera un pilote supplémentaire (ce qui entraînera, par exemple, un doublon dans l'interface utilisateur ou dans les tâches Cron).
- L'heure locale de l'appareil est calculée à partir de l'heure NTP (UTC) et des règles de fuseau horaire. Par défaut, les appareils gPlug sont configurés sur `Timezone +01:00` (sans changement d'heure, soit un décalage d'une heure en été) ; il est nécessaire de définir `Timezone 99`. Vérification en Berry : `tasmota.cmd("Timezone", true)["Timezone"] == 99`.
- `self` est obligatoire au sein des méthodes. Pour les rappels (callbacks), utilisez des fermetures (closures) : `/-> self.m()` ou `def () self.m() end`.
- Listes : `l.push(x)`, `l.size()`, `l[-1]`, `l.resize(n)` ; tables associatives (maps) : `m.find(k, default)`, `m.contains(k)`, `m.remove(k)`.
- Construction de chaînes volumineuses : ajoutez les éléments dans une liste puis utilisez `concat` — ou mieux, procédez par flux (streaming) via `web_send` / `content_send` par segments (chunks).