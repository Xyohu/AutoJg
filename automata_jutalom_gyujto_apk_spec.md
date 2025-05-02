# Automata Jutalom Gyűjtő Android Alkalmazás Specifikáció

## Áttekintés

Az Automata Jutalom Gyűjtő egy Android alkalmazás, amely automatikusan jutalmakat gyűjt a felhasználó által használt alkalmazásokból. Az alkalmazás képes figyelni a telepített appok használatát, és azt valós időben kommunikálni a backend rendszer felé WebSocket kapcsolaton keresztül.

## Technikai Részletek

### Architektúra
- **Frontend**: Natív Android (Kotlin)
- **Backend**: Node.js Express szerver (már implementálva)
- **Kommunikáció**: WebSocket (ws) kapcsolat
- **Adatbázis**: PostgreSQL (már implementálva)

### Alkalmazás komponensek

#### 1. Felhasználói felület
- **Bejelentkezési képernyő**: Felhasználónév/jelszó vagy token alapú autentikáció
- **Főképernyő**: 
  - Aktív alkalmazások listája
  - Gyűjtött jutalmak számlálója
  - Napi, heti, havi kereseti statisztikák
- **Beállítások képernyő**:
  - WebSocket kapcsolat konfigurálása
  - Háttérfolyamat engedélyezése/tiltása
  - Értesítések beállítása

#### 2. Háttérszolgáltatások
- **Alkalmazásfigyelő szolgáltatás**: Detektálja az aktív és használt alkalmazásokat
- **Használati idő figyelő**: Méri az egyes alkalmazásokban töltött időt
- **WebSocket kliens**: Kapcsolatot létesít és fenntart a szerverrel
- **Ütemezett feladatok**: Rendszeres ellenőrzéseket végez és adatokat küld

### WebSocket Kommunikációs Protokoll

#### Kliens -> Szerver üzenetek

```json
{
  "package="com.taskmasterauto.mypapp,
  "metric": "launch|duration|,completion",
  "timestamp": 1619432400000,
  "type": "app_usage",
  "usageDuration": 300,
  "valtimeoutDuration": 30
}
```

```json
{
  "type": "auth",
  "token": "user_auth_token"
}
```

```json
{
  "apps": [
    {
      "packageName": "com.android.chrome",
      "appName": "Google Chrome",
      "installDate": "2023-01-01T00:00:00.000Z",
      "lastUpdateTime": "2024-02-15T00:00:00.000Z",
      "versionName": "123.0.6312.80"
    }
  ],
  "type": "installed_apps"
}
```

#### Szerver -> Kliens üzenetek
```json
{
  "type": "connection",
  "message": "Sikeres kapcsolódás a jutalomgyűjtő szolgáltatáshoz"
}
```

```json
{
  "type": "app_usage_response",
  "packageName": "com.example.app",
  "status": "received|rewarded|rejected",
  "reward": 0.25
}
```

```json
{
  "type": "notification",
  "title": "Új jutalom!",
  "message": "0.50 USD jutalom a Chrome használatáért",
  "timestamp": 1619432400000
}
```

### Android Specifikus Implementációs Részletek

#### Alkalmazás jogosultságok
```xml
       <uses-permission android:name="android.permission.INTERNET"></uses-permission>
        <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"><uses-permissio>
        <uses-permission android:name="android.permission.FOREGROUND_SERVICE"><uses-permission>
        <uses-permission android:name="android.permission.PACKAGE_USAGE_STATS"><uses-permission>,
```

#### Alkalmazásfigyelés implementálása
- Használjuk az Android `UsageStatsManager` API-t az alkalmazások használati statisztikájának lekérdezéséhez
- Foreground Service alkalmazása a háttérben futáshoz
- Work Manager használata periodikus ellenőrzésekhez

```kotlin
class AppUsageTracker(private val context: Context) {
    private val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    
    fun getRecentlyUsedApps(timeIntervalMs: Long): List<UsageStats> {
        val endTime = System.currentTimeMillis()
        val startTime = endTime - timeIntervalMs
        
        return usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, 
            startTime, 
            endTime
        ).filter { it.totalTimeInForeground > 0 }
    }
}
```

#### WebSocket kliens implementálása

```kotlin
class WebSocketClient(private val serverUrl: String) {
    private var webSocket: WebSocket? = null
    private val client = OkHttpClient.Builder()
        .readTimeout(0, TimeUnit.MILLISECONDS) // WebSockethez végtelen timeout
        .build()
    
    fun connect() {
        val request = Request.Builder()
            .url(serverUrl)
            .build()
            
        webSocket = client.newWebSocket(request, WebSocketListener())
    }
    
    fun sendAppUsage(packageName: String, usageDuration: Long) {
        val message = JSONObject().apply {
            put("type", "app_usage")
            put("packageName", packageName)
            put("timestamp", System.currentTimeMillis())
            put("usageDuration", usageDuration)
            put("metric", "duration")
        }.toString()
        
        webSocket?.send(message)
    }
    
    // WebSocket listener implementációja
    inner class WebSocketListener : okhttp3.WebSocketListener() {
        override fun onMessage(webSocket: WebSocket, text: String) {
            // Üzenetek feldolgozása
        }
        
        override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
            // Újracsatlakozás hiba esetén
            reconnect()
        }
    }
    
    private fun reconnect() {
        // Exponenciális várakozással próbálkozzon újra
    }
}
```

#### Foreground Service implementálása

```kotlin
class AppTrackingService : Service() {
  private val binder = LocalBinder()
  private lateinit var appUsageTracker: AppUsageTracker
  private lateinit var webSocketClient: WebSocketClient

  override fun onCreate() {
    super.onCreate()
    appUsageTracker = AppUsageTracker(this)
    webSocketClient = WebSocketClient("ws://yourserver.com/ws")
    webSocketClient.connect()

    startForeground(NOTIFICATION_ID, createNotification())
  }

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    startTracking()
    return START_STICKY
  }

  private fun startTracking() {
    // Periodikus ellenőrzés indítása
    val workManager = WorkManager.getInstance(applicationContext)
    val constraints = Constraints.Builder()
      .setRequiredNetworkType(NetworkType.CONNECTED)
      .build()

    val trackingWork = PeriodicWorkRequestBuilder<AppUsageCheckWorker>(15, TimeUnit.MINUTES)
      .setConstraints(constraints)
      .build()

    workManager.enqueueUniquePeriodicWork(
      "app_tracking",
      ExistingPeriodicWorkPolicy.REPLACE,
      trackingWork
    )
  }

  inner class LocalBinder : Binder() {
    fun getService(): AppTrackingService = this@AppTrackingService
  }

  // További implementációs részletek...
}

// Worker a periodikus ellenőrzéshez
class AppUsageCheckWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
  override fun doWork(): Result {
    val tracker = AppUsageTracker(applicationContext)
    val webSocketClient = WebSocketClient("ws://yourserver.com/ws")

    val recentApps = tracker.getRecentlyUsedApps(TimeUnit.MINUTES.toMillis(15))

    val value = recentApps.forEach stats
            webSocketClient.sendAppUsage(stats.packageName, stats.totalTimeInForeground)
  }

  return Result.success
}
}
```

## Integrációs pontok a webes felülettel

### WebSocket API
A már implementált WebSocket API a `/ws` végponton:
- Kliens app csatlakozik a szerverhez
- Az app frissíti a felhasználói felületet a kereseti adatokkal
- A szerver automatikusan értesíti a klienst az új jutalmakról

### Bevitt adatok szinkronizálása
- Új alkalmazások hozzáadásakor a webes felületen az új beállítások azonnal elérhetők lesznek a mobilalkalmazásban is
- Az alkalmazás által gyűjtött használati adatok azonnal megjelennek a webes statisztikákban

## Telepítési követelmények
- Android 7.0 (API 24) vagy újabb
- Internetkapcsolat
- Megfelelő jogosultságok az alkalmazáshasználat figyeléséhez (a rendszerbeállításokban engedélyezni kell)