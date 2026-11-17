# API Berry pour Tasmota — Aide-mémoire

Référence concise de l'API Berry spécifique à Tasmota (ESP32). Ce document complète la référence du *langage* Berry
(<https://tasmota.github.io/docs/_media/BERRY_LANGUAGE_REFERENCE.txt>), qui couvre la syntaxe, les listes, les tables (maps), les octets,
les chaînes de caractères, `json` et `file` — mais **aucun** des éléments présentés ci-dessous. Source : <https://tasmota.github.io/docs/Berry/>,
synthétisée pour les besoins d'une application de gestion de données/télémétrie. Vérifié par rapport à la documentation au 18/10/2026.

## 1. Cycle de vie et bonnes pratiques

- Le fichier `autoexec.be` présent dans le système de fichiers est exécuté au démarrage. Il est conseillé de s'en tenir à `load("spot.be")`.
- `load("file.be")` charge et exécute un script ; la commande console `BrRestart` redémarre la machine virtuelle (VM) Berry et réexécute `autoexec.be` — utilisez cette méthode pour itérer sans redémarrer tout le système.
- Berry **bloque Tasmota pendant son exécution**. Évitez tout blocage supérieur à 50 ms. Pour les tâches longues, divisez-les en utilisant `tasmota.set_timer`. Ne jamais utiliser d'attente active (*busy-wait*).
- Les appels réseau effectués avant que le Wi-Fi ne soit opérationnel provoquent un plantage. Encadrez toute première utilisation du réseau par `tasmota.when_network_up(f)`.
- L'horloge système n'est pas valide tant que la synchronisation NTP n'a pas eu lieu. Conditionnez toute logique temporelle par `tasmota.rtc("utc") > 1700000000`. Ne vous fiez pas à l'événement `Time#Initialized` après le démarrage : il est déclenché dès la synchronisation NTP, souvent **avant** que votre rappel (*callback*) `when_network_up` ne soit enregistré (l'application ne récupérera alors aucune donnée jusqu'à la prochaine exécution planifiée). Utilisez plutôt `tasmota.set_timer(2000, …)` pour vérifier périodiquement si l'horloge est valide.
- Les exceptions non interceptées interrompent le rappel (*callback*) en cours, mais ne font pas planter Tasmota. Enveloppez toujours le corps de chaque fonction de rappel (callback) dans une structure `try ... except .. as e, m  log("X: " + e + " " + m, 2) end`.
- Console : `print(x)` → console Berry ; `log(msg, level)` → journal (log) Tasmota (niveau 2 = info, 3 = débogage, par défaut 3). Utilisez `log` pour tout ce qui doit être visible par l'utilisateur.
- Mémoire (Heap) : Un ESP32 sans PSRAM dispose d'environ 100 à 200 ko d'espace libre. `tasmota.memory("heap_free")` → renvoie la valeur en ko. `tasmota.gc()` force le ramasse-miettes (garbage collection) et renvoie le nombre d'octets alloués par Berry.

## 2. Objet `tasmota`

### Temps

| Appel | Retourne |
|---|---|
| `tasmota.rtc()` | `{'local': epoch, 'utc': epoch, 'timezone': minutes, 'restart': epoch}` ; `tasmota.rtc("utc")` = valeur unique, sans allocation de dictionnaire (map) |
| `tasmota.time_dump(epoch)` | `{'year','month','day','hour','min','sec','weekday','epoch'}` |
| `tasmota.time_str(epoch)` | `"2021-04-27T21:53:27"` |
| `tasmota.strftime(fmt, epoch)` | `strftime` du langage C, par ex. `"%Y-%m-%d"` |
| `tasmota.strptime(str, fmt)` | Un dictionnaire (map) similaire à celui de `time_dump`, accompagné de `unparsed` (partie non analysée), ou `nil`. L'entrée est traitée comme une heure « naïve » (sans fuseau horaire) ; vérifiez sur l'appareil si `epoch` correspond à l'heure UTC ou à l'heure locale avant de l'utiliser pour générer des chaînes de caractères au format UTC. |
| `tasmota.millis()` | Nombre de millisecondes écoulées depuis le démarrage ; utilisez `tasmota.time_reached(t)` pour effectuer des comparaisons en toute sécurité. |

### Minuteries (timers) et tâches planifiées (cron)

```berry
tasmota.set_timer(5000, f, "id")        # une seule fois, après 5000 ms ;
``` id (facultatif)
tasmota.remove_timer("id")
tasmota.defer(f)                        # exécution après la boucle d'événements actuelle
tasmota.add_cron("0 */15 * * * *", f, "q15")   # 6 champs, le PREMIER correspond aux SECONDES ; heure locale
tasmota.add_cron("0 0 14,16,18 * * *", f, "fetch")
tasmota.remove_cron("q15")
tasmota.next_cron("q15")                # prochaine occurrence (heure locale)

Pour appeler une méthode d'une instance, utilisez une fermeture (closure) : `tasmota.add_cron("...", /-> self.tick(), "id")`.

### Règles (hooks d'événements)

```berry
tasmota.add_rule("Time#Initialized", /-> on_time_ok(), "t_init")   # synchronisation NTP effectuée
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
- Accessible depuis la console, via `http://<ip>/cm?cmnd=SpotPrices`, ou via MQTT : `cmnd/<topic>/SpotPrices`.
- Impossible de remplacer les commandes natives. Les noms ne sont pas sensibles à la casse.
- `tasmota.cmd("Status 10", true)` permet d'exécuter n'importe quelle commande depuis Berry et renvoie une table (map) analysée (`true` permet de masquer les logs).

### Capteurs et télémétrie

- `tasmota.read_sensors()` → renvoie une **chaîne** JSON contenant tous les capteurs (similaire à `teleperiod`). À analyser avec `json.load` ; peut renvoyer `nil`.
- Dans un pilote (driver) : `json_append()` + `tasmota.response_append(',"Spot":{"Price":0.194}')` permet d'ajouter des données au message `tele/SENSOR`.

### Divers

- `tasmota.version()` → entier, par ex. `0x0F050002` (15.5.0.2). `tasmota.arch()` → `"esp32"`.
- `tasmota.wifi("ip")`, `tasmota.is_network_up()`.
- `tasmota.scale_int(v, fromMin, fromMax, toMin, toMax)` — mise à l'échelle linéaire d'entiers, utile pour des coordonnées SVG.
- `tasmota.urlfetch(url, filename)` — téléchargement ponctuel vers le système de fichiers ; renvoie la taille en octets ou -1.

## 3. Pilotes (callbacks d'événements + interface web)

Toute instance de classe enregistrée via `tasmota.add_driver(obj)` ; les méthodes sont identifiées **par leur nom** :

| Méthode | Moment d'exécution |
|---|---|
| `every_second()` | une fois par seconde |
| `every_250ms()`, `every_100ms()`, `every_50ms()` | boucles rapides — à éviter, sauf nécessité |