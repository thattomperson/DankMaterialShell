#!/usr/bin/env bash
# Outputs dynamic system stats as JSON.
# Args:
#  $1 sort_key (cpu|memory|name|pid)
#  $2 max_procs
#  $3 collect_gpu_temps (0/1)
#  $4 collect_nvidia_only (0/1)
#  $5 collect_non_nvidia (0/1)

set -o pipefail

sort_key=${1:-cpu}
max_procs=${2:-20}
collect_gpu_temps=${3:-0}
collect_nvidia_only=${4:-0}
collect_non_nvidia=${5:-1}

json_escape() { sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e ':a;N;$!ba;s/\n/\\n/g'; }

printf "{"

# ---- Memory block (exact fields/keys) ----
mem_line="$(awk '
  /^MemTotal:/      {t=$2}
  /^MemFree:/       {f=$2}
  /^MemAvailable:/  {a=$2}
  /^Buffers:/       {b=$2}
  /^Cached:/        {c=$2}
  /^Shmem:/         {s=$2}
  /^SwapTotal:/     {st=$2}
  /^SwapFree:/      {sf=$2}
  END{printf "%d %d %d %d %d %d %d %d", t,f,a,b,c,s,st,sf}
' /proc/meminfo)"
read -r MT MF MA BU CA SH ST SF <<< "$mem_line"

printf '"memory":{"total":%d,"free":%d,"available":%d,"buffers":%d,"cached":%d,"shared":%d,"swaptotal":%d,"swapfree":%d},' \
  "$MT" "$MF" "$MA" "$BU" "$CA" "$SH" "$ST" "$SF"

# ---- Helper: PSS in KiB ----
get_pss_kb() {
  local pid="$1" k v rest total=0 f
  f="/proc/$pid/smaps_rollup"
  if [ -r "$f" ]; then
    while read -r k v rest; do
      if [ "$k" = "Pss:" ]; then
        printf '%s\n' "${v:-0}"
        return
      fi
    done < "$f"
    printf '0\n'; return
  fi
  f="/proc/$pid/smaps"
  if [ -r "$f" ]; then
    while read -r k v rest; do
      if [ "$k" = "Pss:" ]; then
        : "${v:=0}"
        total=$(( total + v ))
      fi
    done < "$f"
    printf '%s\n' "$total"; return
  fi
  printf '0\n'
}

# ---- CPU (meta + temp) ----
cpu_count=$(nproc)
cpu_model=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^ *//' | json_escape || echo 'Unknown')
cpu_freq=$(awk -F: '/cpu MHz/{gsub(/ /,"",$2);print $2;exit}' /proc/cpuinfo || echo 0)

cpu_temp=0
for hwmon_dir in /sys/class/hwmon/hwmon*/; do
  [ -d "$hwmon_dir" ] || continue
  name_file="${hwmon_dir}name"
  [ -r "$name_file" ] || continue
  if grep -qE 'coretemp|k10temp|k8temp|cpu_thermal|soc_thermal' "$name_file" 2>/dev/null; then
    for temp_file in "${hwmon_dir}"temp*_input; do
      [ -r "$temp_file" ] || continue
      cpu_temp=$(awk '{printf "%.1f", $1/1000}' "$temp_file" 2>/dev/null || echo 0)
      break 2
    done
  fi
done

printf '"cpu":{"count":%d,"model":"%s","frequency":%s,"temperature":%s,' \
  "$cpu_count" "$cpu_model" "$cpu_freq" "$cpu_temp"

# cpu.total (first line of /proc/stat, fields 2..)
printf '"total":'
awk 'NR==1 {
  printf "[";
  for(i=2; i<=NF; i++) { if(i>2) printf ","; printf "%d", $i; }
  printf "]";
  exit
}' /proc/stat

# cpu.cores (each cpuN line, 8 columns)
printf ',"cores":['
cpu_cores=$(nproc)
awk -v n="$cpu_cores" 'BEGIN{c=0}
  /^cpu[0-9]+/ {
    if(c>0) printf ",";
    printf "[%d,%d,%d,%d,%d,%d,%d,%d]", $2,$3,$4,$5,$6,$7,$8,$9;
    c++;
    if(c==n) exit
  }' /proc/stat
printf ']},'

# ---- Network (rx/tx bytes per iface) ----
printf '"network":['
tmp_net=$(mktemp)
grep -E '(wlan|eth|enp|wlp|ens|eno)' /proc/net/dev > "$tmp_net" || true
nfirst=1
while IFS= read -r line; do
  [ -z "$line" ] && continue
  iface=$(echo "$line" | awk '{print $1}' | sed 's/://')
  rx_bytes=$(echo "$line" | awk '{print $2}')
  tx_bytes=$(echo "$line" | awk '{print $10}')
  [ $nfirst -eq 1 ] || printf ","
  printf '{"name":"%s","rx":%d,"tx":%d}' "$iface" "$rx_bytes" "$tx_bytes"
  nfirst=0
done < "$tmp_net"
rm -f "$tmp_net"
printf '],'

# ---- Disk (/proc/diskstats sectors; read/write) ----
printf '"disk":['
tmp_disk=$(mktemp)
grep -E ' (sd[a-z]+|nvme[0-9]+n[0-9]+|vd[a-z]+|dm-[0-9]+|mmcblk[0-9]+) ' /proc/diskstats > "$tmp_disk" || true
dfirst=1
while IFS= read -r line; do
  [ -z "$line" ] && continue
  name=$(echo "$line" | awk '{print $3}')
  read_sectors=$(echo "$line" | awk '{print $6}')
  write_sectors=$(echo "$line" | awk '{print $10}')
  [ $dfirst -eq 1 ] || printf ","
  printf '{"name":"%s","read":%d,"write":%d}' "$name" "$read_sectors" "$write_sectors"
  dfirst=0
done < "$tmp_disk"
rm -f "$tmp_disk"
printf '],'

# ---- Processes (shape & fields match your QML) ----
case "$sort_key" in
  cpu)    SORT_OPT="--sort=-pcpu" ;;
  memory) SORT_OPT="--sort=-pmem" ;;
  name)   SORT_OPT="--sort=+comm" ;;
  pid)    SORT_OPT="--sort=+pid" ;;
  *)      SORT_OPT="--sort=-pcpu" ;;
esac

printf '"processes":['
tmp_ps=$(mktemp)
ps -eo pid,ppid,pcpu,pmem,rss,comm,cmd --no-headers $SORT_OPT | head -n "$max_procs" > "$tmp_ps" || true
pfirst=1
while IFS= read -r line; do
  [ -z "$line" ] && continue
  # split the first 6 columns, rest is full command tail
  pid=$(  awk '{print $1}' <<<"$line")
  ppid=$( awk '{print $2}' <<<"$line")
  cpu=$(  awk '{print $3}' <<<"$line")
  pmem=$( awk '{print $4}' <<<"$line")
  rss_kib=$(awk '{print $5}' <<<"$line")
  comm=$( awk '{print $6}' <<<"$line")
  rest=$( printf '%s\n' "$line" | cut -d' ' -f7- )

  # CPU ticks (utime+stime)
  pticks=$(awk '{print $14+$15}' "/proc/$pid/stat" 2>/dev/null || echo 0)

  # PSS in KiB and % of MemTotal
  if [ "${rss_kib:-0}" -eq 0 ]; then pss_kib=0; else pss_kib=$(get_pss_kb "$pid"); fi
  case "$pss_kib" in (''|*[!0-9]*) pss_kib=0 ;; esac
  pss_pct=$(LC_ALL=C awk -v p="$pss_kib" -v t="$MT" 'BEGIN{if(t>0) printf "%.2f", (100*p)/t; else printf "0.00"}')

  cmd=$(printf "%s %s" "$comm" "${rest:-}" | json_escape)
  comm_esc=$(printf "%s" "$comm" | json_escape)

  [ $pfirst -eq 1 ] || printf ","
  printf '{"pid":%s,"ppid":%s,"cpu":%s,"pticks":%s,"memoryPercent":%s,"memoryKB":%s,"pssKB":%s,"pssPercent":%s,"command":"%s","fullCommand":"%s"}' \
    "$pid" "$ppid" "$cpu" "$pticks" "$pss_pct" "$rss_kib" "$pss_kib" "$pss_pct" "$comm_esc" "$cmd"
  pfirst=0
done < "$tmp_ps"
rm -f "$tmp_ps"
printf '],'

# ---- System (dynamic bits) ----
load_avg=$(cut -d' ' -f1-3 /proc/loadavg)
proc_count=$(ls -Ud /proc/[0-9]* 2>/dev/null | wc -l)
thread_count=$(ls -Ud /proc/[0-9]*/task/[0-9]* 2>/dev/null | wc -l)
boot_time=$(who -b 2>/dev/null | awk '{print $3, $4}' | json_escape || echo 'Unknown')

printf '"system":{"loadavg":"%s","processes":%d,"threads":%d,"boottime":"%s"},' \
  "$load_avg" "$proc_count" "$thread_count" "$boot_time"

# ---- Mounts (same df -h shape/strings) ----
printf '"diskmounts":['
tmp_mounts=$(mktemp)
df -h --output=source,target,fstype,size,used,avail,pcent | tail -n +2 | grep -vE '^(tmpfs|devtmpfs)' > "$tmp_mounts" || true
mfirst=1
while IFS= read -r line; do
  [ -z "$line" ] && continue
  device=$(echo "$line" | awk '{print $1}' | json_escape)
  mount=$( echo "$line" | awk '{print $2}' | json_escape)
  fstype=$(echo "$line" | awk '{print $3}')
  size=$(  echo "$line" | awk '{print $4}')
  used=$(  echo "$line" | awk '{print $5}')
  avail=$( echo "$line" | awk '{print $6}')
  percent=$(echo "$line" | awk '{print $7}')
  [ $mfirst -eq 1 ] || printf ","
  printf '{"device":"%s","mount":"%s","fstype":"%s","size":"%s","used":"%s","avail":"%s","percent":"%s"}' \
    "$device" "$mount" "$fstype" "$size" "$used" "$avail" "$percent"
  mfirst=0
done < "$tmp_mounts"
rm -f "$tmp_mounts"
printf '],'

# ---- GPU temps (optional) ----
printf '"gputemps":['
if [ "$collect_gpu_temps" = "1" ]; then
  gfirst=1
  for card in /sys/class/drm/card*; do
    [ -e "$card/device/driver" ] || continue
    drv=$(basename "$(readlink -f "$card/device/driver")"); drv=${drv##*/}
    hw=""; temp="0"

    if [ "$collect_non_nvidia" = "1" ]; then
      for h in "$card/device"/hwmon/hwmon*; do
        [ -e "$h/temp1_input" ] || continue
        hw=$(basename "$h")
        temp=$(awk '{printf "%.1f",$1/1000}' "$h/temp1_input" 2>/dev/null || echo "0")
        break
      done
    fi

    if [ "$drv" = "nvidia" ] && [ "$temp" = "0" ] && [ "$collect_nvidia_only" = "1" ] && command -v nvidia-smi >/dev/null 2>&1; then
      t=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)
      [ -n "$t" ] && { temp="$t"; hw="${hw:-nvidia}"; }
    fi

    if [ "$temp" != "0" ]; then
      [ $gfirst -eq 1 ] || printf ","
      printf '{"driver":"%s","hwmon":"%s","temperature":%s}' "$drv" "${hw:-unknown}" "${temp:-0}"
      gfirst=0
    fi
  done

  # Fallback: nvidia-smi only
  if [ ${gfirst:-1} -eq 1 ] && [ "$collect_nvidia_only" = "1" ] && command -v nvidia-smi >/dev/null 2>&1; then
    temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)
    [ -n "$temp" ] && printf '{"driver":"nvidia","hwmon":"nvidia","temperature":%s}' "$temp"
  fi
fi
printf ']'

printf "}\n"
