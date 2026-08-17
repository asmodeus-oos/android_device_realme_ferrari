#!/usr/bin/env bash
# Push rebuilt CameraUnit SDK jar and disable stale Flex clock plugin.
set -euo pipefail
ADB="${ADB:-/mnt/c/ProgramData/chocolatey/bin/adb.exe}"
JAR="${1:-$(cd "$(dirname "$0")/../../../.." && pwd)/vendor/realme/ferrari/proprietary/system_ext/framework/com.oplus.camera.unit.sdk.jar}"

echo "Using ADB=$ADB"
echo "Using JAR=$JAR"
"$ADB" devices -l
"$ADB" root
sleep 1
"$ADB" remount
"$ADB" push "$JAR" /system_ext/framework/com.oplus.camera.unit.sdk.jar
echo "host:   $(md5sum "$JAR")"
echo "device: $($ADB shell md5sum /system_ext/framework/com.oplus.camera.unit.sdk.jar | tr -d '\r')"
"$ADB" shell 'pm disable-user --user 0 com.android.systemui.clocks.flex' || true
echo "Rebooting so framework jar is reloaded..."
"$ADB" reboot
"$ADB" wait-for-device
for i in $(seq 1 90); do
  bc=$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
  if [ "$bc" = "1" ]; then
    echo "boot_completed"
    break
  fi
  sleep 2
done
"$ADB" shell getprop sys.boot_completed
