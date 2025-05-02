# bin / bash

# Build szkript az Android alkalmazás összeállításához

# Változók
APP_DIR=$(dirname "$0")
APP_NAME="AutomataJutalomGyujto"

echo "Android alkalmazás építése: $APP_NAME"
echo "Könyvtár: $APP_DIR"

# Gradle wrapper létrehozása, ha még nem létezik
if [ ! -f "$APP_DIR/gradlew" ]; then
  echo "Gradle wrapper létrehozása..."
  
  # Ellenőrizze, hogy van-e Gradle telepítve
  if command -v gradle &> /dev/null; then
    cd "$APP_DIR" && gradle wrapper
  else
    echo "HIBA: Gradle nincs telepítve, a wrapper létrehozása nem sikerült."
    echo "Telepítse a Gradle-t, vagy használjon egy Android Studio IDE-t a projekt megnyitásához."
    exit 1
  fi
fi

# APK-t Debug módban
echo "APK építése debug módban..."
cd "$APP_DIR" && ./gradlew :app:assembleDebug

# Ellenőrizze, hogy sikerült-e az építés
if [ $? -eq 0 ]; then
  APK_PATH="$APP_DIR/app/build/outputs/apk/debug/app-debug.apk"
  if [ -f "$APK_PATH" ]; then
    echo "APK sikeresen létrehozva: $APK_PATH"
    echo "Átnevezés: $APP_NAME.apk"
    cp "$APK_PATH" "$APP_DIR/$APP_NAME.apk"
    echo "Kész!"
  else
    echo "HIBA: Az APK fájl nem található: $APK_PATH"
    exit 1
  fi
else
  echo "HIBA: Az APK építése sikertelen volt."
  exit 1
fi