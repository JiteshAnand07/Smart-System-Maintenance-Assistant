#!/bin/bash
# back_worker.sh
# Automated cron backup + COUNT-BASED rotation (keep last 5 backups) 

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$BASE_DIR/backups"
LOG_DIR="$BASE_DIR/logs"
TMP_DIR="$BASE_DIR/temp"
PAUSE_FLAG="$TMP_DIR/ssma.pause"

SOURCE_TO_BACKUP="$HOME"  # default if none provided

if [[ -n "$1" ]]; then
   SOURCE_TO_BACKUP="$1"
fi

mkdir -p "$BACKUP_DIR""$LOG_DIR" "$TMP_DIR"

timestamp() { date "+%Y-%m-%d %H:%M:%S"; }
LOGFILE="$LOG_DIR/backup_$(date +%F).log"

# Pause flag check
if [[ -f "$PAUSE_FLAG" ]]; then
   echo "$(timestamp) | INFO | SKIP | paused" >> "$LOGFILE"
   exit 0
fi

#Validate source
if [[ ! -e "$SOURCE_TO_BACKUP" ]]; then
   echo "$(timestamp) | ERROR | NOSRC | $SOURCE_TO_BACKUP missing" >> "$LOGFILE"
   exit 1 
fi

# Backup filename
BNAME="backup_$(basename "SOURCE_TO_BACKUP")_$(date +%F_%H-%M-%S).tar.gz"
DEST="$BACKUP_DIR/$BNAME"

echo "---------------------------------------------------" >> "$LOGFILE"
echo "$(timestamp) | INFO | START | $SOURCE_TO_BACKUP -> $DEST" >> "$LOGFILE"

start=$(date +%s)
tar -czf "$DEST" -C "$(dirname "$SOURCE_TO_BACKUP")" "$(basename "$SOURCE_TO_BACKUP")" 2>>"$LOGFILE"
res=$?
end=$(date +%s)
dur=$((end-start))

if [[ $res -ne 0 ]]; then
   echo "$(timestamp) | ERROR | FAIL | tar exit $res (duration ${dur}s)" >> "$LOGFILE"
   rm -f "$DEST"
   exit 1
fi

echo "$(timestamp) | INFO | SUCCESS | Created $DEST (${dur}s)" >> "$LOGFILE"

# COUNT-BASED ROTATION -- keep only last 5 backups
cd "$BACKUP_DIR"
backups=( $(ls -1tr backup_*.tar.gz 2>/dev/null) ) 

keep=5
count=${#backups[@]}

if (( count > keep )); then
   remove_count=$((count - keep))
   remove_list=("${backups[@]:0:remove_count}")
   for f in "${remove_list[@]}"; 
   do
     rm -f "$f"
     echo "$(timestamp) | ROTATE | REMOVED | $f" >> "$LOGFILE"
   done
fi

echo "$(timestamp) | INFO | END | Done" >> "$LOGFILE"








