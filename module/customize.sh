SKIPUNZIP=0
DEBUG=false
if [ "$MAGISK_VER_CODE" ]; then
    BM="Magisk:$MAGISK_VER│$MAGISK_VER_CODE"
elif [ "$KSU" ]; then
    BM="KSU:$KSU_KERNEL_VER_CODE│$KSU_VER_CODE"
elif [ "$APATCH" ]; then
    BM="APatch:$APATCH_VER│$APATCH_VER_CODE"
else
    ui_print " "; 
    ui_print "! recovery is not supported"; 
    abort " "; 
fi

print_modname() {
  ui_print "*******************************************************"
  ui_print "Installing Tricky Addon: Update Target List"
  ui_print "Author: KOWX712"
  ui_print "*******************************************************"
}

if [ -d /data/adb/modules/tricky_store ]; then
    echo "- Tricky store module installed"
else
    echo "! Tricky store module is not installed"
    abort " " 
fi

key_check() {
  while true; do
    key_check=$(/system/bin/getevent -qlc 1)
    key_event=$(echo "$key_check" | awk '{ print $3 }' | grep 'KEY_')
    key_status=$(echo "$key_check" | awk '{ print $4 }')
    if [[ "$key_event" == *"KEY_"* && "$key_status" == "DOWN" ]]; then
      keycheck="$key_event"
      break
    fi
  done
  while true; do
    key_check=$(/system/bin/getevent -qlc 1)
    key_event=$(echo "$key_check" | awk '{ print $3 }' | grep 'KEY_')
    key_status=$(echo "$key_check" | awk '{ print $4 }')
    if [[ "$key_event" == *"KEY_"* && "$key_status" == "UP" ]]; then
      break
    fi
  done
}

ui_print "- Installing..."
COMPATH="$MODPATH/common"
CONFIG_DIR="/data/adb/tricky_store/target_list_config"
SCRIPT_DIR="/data/adb/tricky_store"
MODNAME=$(grep '^id=' "$MODPATH/module.prop" | awk -F= '{print $2}' | xargs)

add_exclude() {
  EXCLUDE=$(grep -vE '^#|^$' "$CONFIG_DIR/EXCLUDE")
  for app in $EXCLUDE; do
      if ! grep -qx "$app" $COMPATH/EXCLUDE; then
          echo "$app" >> $COMPATH/EXCLUDE
      fi
  done
  mv "$COMPATH/EXCLUDE" "$CONFIG_DIR/EXCLUDE"
}

add_addition() {
  ADDITION=$(grep -vE '^#|^$' "$CONFIG_DIR/ADDITION")
  for app in $ADDITION; do
      if ! grep -qx "$app" $COMPATH/ADDITION; then
          echo "$app" >> $COMPATH/ADDITION
      fi
  done
  mv "$COMPATH/ADDITION" "$CONFIG_DIR/ADDITION"
}

for status in normal ninstalled disabled; do
    cp "$MODPATH/module.prop" "$COMPATH/$status"
done
sed -i 's/^description=.*/description=Tricky store is not installed/' "$COMPATH/ninstalled"
sed -i 's/^description=.*/description=Tricky store is disabled/' "$COMPATH/disabled"
rm -f "$SCRIPT_DIR/UpdateTargetList.sh"
cp "$COMPATH/UpdateTargetList.sh" "$SCRIPT_DIR/UpdateTargetList.sh"

if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR"
    mv "$COMPATH/EXCLUDE" "$CONFIG_DIR/EXCLUDE"
    mv "$COMPATH/ADDITION" "$CONFIG_DIR/ADDITION"
elif [ -d "$CONFIG_DIR" ]; then
    if [ ! -f "$CONFIG_DIR/EXCLUDE" ] && [ ! -f "$CONFIG_DIR/ADDITION" ]; then
        mv "$COMPATH/EXCLUDE" "$CONFIG_DIR/EXCLUDE"
        mv "$COMPATH/ADDITION" "$CONFIG_DIR/ADDITION"
    elif [ ! -f "$CONFIG_DIR/ADDITION" ]; then
        mv "$COMPATH/ADDITION" "$CONFIG_DIR/ADDITION"
        add_exclude
    elif [ ! -f "$CONFIG_DIR/EXCLUDE" ]; then
        mv "$COMPATH/EXCLUDE" "$CONFIG_DIR/EXCLUDE"
        add_addition
    else
        add_exclude
        add_addition
    fi
fi

if [ ! -f "/data/adb/modules/$MODNAME/system.prop" ]; then
    mv "$COMPATH/system.prop" "$MODPATH/system.prop"
else
    rm -f "$COMPATH/system.prop"
    mv "/data/adb/modules/$MODNAME/system.prop" "$MODPATH/system.prop"
fi

kb="$COMPATH/.keybox"
ui_print "*********************************************"
ui_print "- Do you want to replace tricky store keybox?"
ui_print "  VOL [+]: YES"
ui_print "  VOL [-]: NO"
ui_print "*********************************************"
key_check
if [[ "$keycheck" == "KEY_VOLUMEUP" ]]; then
  ui_print "*********************************************"
  ui_print "- Replacing keybox..."
  ui_print "*********************************************"
  if [ ! -f "/data/adb/modules/$MODNAME/common/origkeybox" ]; then
    mv "$SCRIPT_DIR/keybox.xml" "$COMPATH/origkeybox"
  fi
  mv "$kb" "$SCRIPT_DIR/keybox.xml"
else
  rm -f "$kb"
fi

ui_print " "
ui_print "- Installation completed successfully! "
ui_print " "
