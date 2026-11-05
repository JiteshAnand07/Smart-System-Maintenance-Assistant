#!/bin/bash
# smart_system_assistant.sh (colored terminal UI) 

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_WORKER="$BASE_DIR/backup_worker.sh"
LOG_DIR="$BASE_DIR/logs"
BACKUP_DIR="$BASE_DIR/backups"
TMP_DIR="$BASE_DIR/temp"
PAUSE_FLAG="$TMP_DIR/ssma.pause"
CRON_TAG="SSMA_CRON_JOB"

mkdir -p "$LOG_DIR" "$BACKUP_DIR" "$TMP_DIR"

# Colors
RESET="\e[0m"; BOLD="\e[1m"
CYAN="\e[36m"; GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; MAGENTA="\e[35m"

clear_screen() { printf "\033c"; }

header(){
    clear_screen
    echo -e "${CYAN}=============================================${RESET}"
    echo -e "${MAGENTA}${BOLD}        SMART SYSTEM MAINTENANCE TOOL${RESET}"
    echo -e "${CYAN}=============================================${RESET}\n"
  }
  
pause(){ echo; read -p "Press Enter to continue..." _; }

# 1) System Information
show_system_info() {
  header
  echo -e "${CYAN}${BOLD}SYSTEM INFORMATION${RESET}"
  echo -e "${YELLOW}Date & Time:${RESET} $(date '+%Y-%m-%d %H:%M:%S')"
  echo -e "${YELLOW}OS:${RESET} $(uname -s) $(uname -r)"
  echo -e "${YELLOW}Uptime:${RESET} $(uptime -p)\n"
  echo -e "${YELLOW}CPU:${RESET}"
  awk -F: '/model name/ {print $2; exit}' /proc/cpuinfo | sed 's/^[ \t]*//'
  echo
  echo -e "${YELLOW}Memory:${RESET}"
  free -h
  echo
  echo -e "${YELLOW}Disk Summary:${RESET}"
  df -h --total | sed -n '1,3p'
  pause
 }
 
# 2) Monitor CPU & Memory
monitor_cpu_memory() {
  header
  echo -e "${CYAN}${BOLD}CPU / MEMORY SNAPSHOT${RESET}"
  echo -e "${YELLOW}Top by CPU:${RESET}"
  ps aux --sort=-%cpu | head -n 10
  echo
  echo -e "${YELLOW}Top by memory:${RESET}"
  ps aux --sort=-%mem | head -n 10
  pause
 }
 
# 3) Disk Usage
check_disk_usage() {
    header
    echo -e "${CYAN}${BOLD}DISK USAGE${RESET}\n"
    df -h
    pause
   }
   
# 4) Running processes
view_running_processes() {
   header
   echo -e "${CYAN}${BOLD}RUNNING PROCESSES (ps aux)${RESET}"
   ps aux | less -R
  }
  
# 5) View Logs
view_logs() {
   header
   echo -e "${CYAN}${BOLD}LOG FILES${RESET}\n"
   shopt -s nullglob
   files=( "$LOG_DIR"/* )
   if (( ${#files[@]} == 0 )); then
      echo -e "${YELLOW}No logs found.${RESET}"
      pause
      return
   fi
   i=1
   for f in "${files[@]}";
   do
     echo -e "(${MAGENTA}$i)${RESET} $(basename "$f")"
     ((i++))
   done
   echo
   read -p "Enter number to view (Enter cancels): " n
   [[ -z "$n" ]] && return
   ((n<1 || n>${#files[@]})) && { echo -e "${RED}Invalid.${RESET}"; pause; return; }
   less -R "${files[$n-1]}"
  }
  
# 6) Daily Report
generate_daily_report() {
    header
    report="$LOG_DIR/ssma_report_$(date +%F).txt"
     {
      echo "SSMA Report - $(date)"
      echo "================================="
      echo
      echo "System Info:"
      uname -a
      echo "Uptime: $(uptime -p)"
      echo
      echo "Disk:"
      df -h --total | sed -n '1,3p'
      echo
      echo "Todays Backup Log:"
      echo "---------------------"
      tail -n 100 "$LOG_DIR/backup_$(date +%F).log" 2>/dev/null || echo "No backup log today"
      echo
      echo "Backups:"
      #ls -lh "$BACKUP_DIR"
      ls -lh $BACKUP_DIR | head -n 6
     } > "$report"
      
      #echo "Recent Backups (Rotation: Last 5 files):"
      #echo "---------------------------------------------"
      #ls -lh $BACKUP_DIR | head -n 6
      
     echo -e "${GREEN}Report generated:${RESET} $report"
     pause
}
  
  
# Install Cron Job
install_cron_job12() {
  echo "Debug: install_cron_job called"
  sleep 2
  header
  echo -e "${CYAN}${BOLD}INSTALL CRON BACKUP${RESET}\n"
  read -p "Enter cron schedule [default: * * * * *]: " sched
  sched="${sched:-* * * * *}"
  read -p "Enter directory to backup [default: $HOME]: " src
  src="${src:-$HOME}"
  
  if [[ ! -e "$src" ]]; then
    echo -e "${RED}Invalid source path.${RESET}"
    pause
    return
  fi
  
  # Create temporary cron file
  TEMP_CRON="$TMP_DIR/temp_cron_install"
  crontab -l 2>/dev/null | grep -v "$CRON_TAG" > "$TEMP_CRON"
  
  echo "$sched $BACKUP_WORKER \"$src\" >> $LOG_DIR/cron_executor.log 2>&1 # $CRON_TAG" >> "$TEMP_CRON"




  rm -f "$TEMP_CRON"
  
  echo -e "${GREEN}Cron job installed successfully!${RESET}"
  echo -e "${YELLOW}Schedule:${RESET} $sched"
  echo -e "${YELLOW}Backup Source:${RESET} $src"
  pause  
}
 
# 8) Remove cron jobs
remove_cron_jobs() {
  header
  (crontab -l 2>/dev/null | grep -v "$CRON_TAG") | crontab -
  echo -e "${GREEN}Removed cron jobs.${RESET}"
  pause
 }
 
# 9) Pause
pause_scheduled() {
  touch "$PAUSE_FLAG"
  echo -e "${YELLOW}Backups paused.${RESET}"
  pause
 }
   
# 10) Resume
resume_scheduled() {
  rm -f "$PAUSE_FLAG" 2>/dev/null 
  echo -e "${GREEN}Backups resumed.${RESET}"
  pause
 }
 
# Main Menu
while true; 
do
 header
 echo -e "${BOLD}1)${RESET} Show System Information"
 echo -e "${BOLD}2)${RESET} Monitor CPU & Memory"
 echo -e "${BOLD}3)${RESET} Check Disk Usage"
 echo -e "${BOLD}4)${RESET} View Running Processes"
 echo -e "${BOLD}5)${RESET} View logs"
 echo -e "${BOLD}6)${RESET} Generate Daily Report"
 echo -e "${BOLD}7)${RESET} Install Cron Backup"
 echo -e "${BOLD}8)${RESET} Remove Cron Jobs"
 echo -e "${BOLD}9)${RESET} Pause Scheduled Backups"
 echo -e "${BOLD}10)${RESET} Resume Scheduled Backups"
 echo -e "${BOLD}11)${RESET} Exit"
 echo
 read -p "Choose [1-11]: " ch
   case $ch in
    1) show_system_info ;;
    2) monitor_cpu_memory ;;
    3) check_disk_usage ;;
    4) view_running_processes ;;
    5) view_logs ;;
    6) generate_daily_report ;;
    7) install_cron_job12 ;;
    8) remove_cron_jobs ;;
    9) pause_scheduled ;;
    10) resume_scheduled ;;
    11) exit 0 ;;
    *) echo -e "${RED}Invalid option${RESET}"; sleep 1 ;;
   esac
done
