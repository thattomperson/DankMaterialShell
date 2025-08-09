#!/usr/bin/env bash
# Outputs static system info + detected GPUs as JSON (no temps)

set -o pipefail
exec 2>/dev/null

json_escape() { sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e ':a;N;$!ba;s/\n/\\n/g'; }

printf "{"

cpu_count=$(nproc)
cpu_model=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^ *//' | json_escape || echo 'Unknown')
printf '"cpu":{"count":%d,"model":"%s"},' "$cpu_count" "$cpu_model"

dmip="/sys/class/dmi/id"
[ -d "$dmip" ] || dmip="/sys/devices/virtual/dmi/id"
mb_vendor=$([ -r "$dmip/board_vendor" ] && cat "$dmip/board_vendor" | json_escape || echo "Unknown")
mb_name=$([ -r "$dmip/board_name" ] && cat "$dmip/board_name" | json_escape || echo "")
bios_ver=$([ -r "$dmip/bios_version" ] && cat "$dmip/bios_version" | json_escape || echo "Unknown")
bios_date=$([ -r "$dmip/bios_date" ] && cat "$dmip/bios_date" | json_escape || echo "")

kern_ver=$(uname -r | json_escape)
distro=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d '"' | json_escape || echo 'Unknown')
host_name=$(hostname | json_escape)
arch_name=$(uname -m)

printf '"system":{"kernel":"%s","distro":"%s","hostname":"%s","arch":"%s","motherboard":"%s %s","bios":"%s %s"},' \
  "$kern_ver" "$distro" "$host_name" "$arch_name" "$mb_vendor" "$mb_name" "$bios_ver" "$bios_date"

printf '"gpus":['
gfirst=1
tmp_gpu=$(mktemp)

infer_vendor() {
  case "$1" in
    nvidia|nouveau) echo NVIDIA ;;
    amdgpu|radeon)  echo AMD ;;
    i915|xe)        echo Intel ;;
    *) case "$2" in
         *NVIDIA*|*Nvidia*|*nvidia*) echo NVIDIA ;;
         *AMD*|*ATI*|*amd*|*ati*)    echo AMD ;;
         *Intel*|*intel*)            echo Intel ;;
         *)                          echo Unknown ;;
       esac ;;
  esac
}

prio_of() {
  local drv="$1" bdf="$2"
  case "$drv" in
    nvidia) echo 3 ;;
    amdgpu|radeon)
      local dd="${bdf##*:}"; dd="${dd%%.*}"
      [ "$dd" = "00" ] && echo 1 || echo 2
      ;;
    i915|xe) echo 0 ;;
    *) echo 0 ;;
  esac
}

LC_ALL=C lspci -nnD 2>/dev/null | grep -iE ' VGA| 3D| 2D| Display' | while IFS= read -r line; do
  bdf="${line%% *}"
  drv=""
  [ -e "/sys/bus/pci/devices/$bdf/driver" ] && drv="$(basename "$(readlink -f "/sys/bus/pci/devices/$bdf/driver")")"
  vendor="$(infer_vendor "$drv" "$line")"
  raw_line="$(printf '%s' "$line" | json_escape)"
  prio="$(prio_of "$drv" "$bdf")"
  printf '%s|%s|%s|%s\n' "$prio" "$drv" "$vendor" "$raw_line" >> "$tmp_gpu"
done

if [ -s "$tmp_gpu" ]; then
  while IFS='|' read -r pr drv vendor raw_line; do
    [ $gfirst -eq 1 ] || printf ","
    printf '{"driver":"%s","vendor":"%s","rawLine":"%s"}' "$drv" "$vendor" "$raw_line"
    gfirst=0
  done < <(sort -t'|' -k1,1nr -k2,2 "$tmp_gpu")
fi

rm -f "$tmp_gpu"
printf ']'
printf "}\n"
