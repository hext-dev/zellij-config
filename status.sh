#!/usr/bin/env bash
# Zellij status bar script

export LANG=en_US.UTF-8

MACHINE_ID_CONF="$HOME/.config/zellij/machine-id.conf"

detect_connection() {
  if [ -f /tmp/zellij-conntype ]; then
    cat /tmp/zellij-conntype
  elif [ -n "$MOSH_CONNECTION" ]; then
    echo "mosh"
  elif [ -n "$SSH_CONNECTION" ]; then
    echo "ssh"
  else
    echo "local"
  fi
}

case "$1" in
  machine_icon)
    if [ -f "$MACHINE_ID_CONF" ]; then
      source "$MACHINE_ID_CONF"
      printf "#[fg=%s]%s" "$COLOR" "$ICON "
    fi
    ;;
  host)
    if [ -f "$MACHINE_ID_CONF" ]; then
      source "$MACHINE_ID_CONF"
      printf "#[fg=%s]%s" "$COLOR" "$NAME"
    elif [ -f /etc/bootstrap-hostname ]; then
      h=$(cat /etc/bootstrap-hostname)
      [ ${#h} -gt 14 ] && h="${h:0:14}…"
      echo "$h"
    else
      h=$(hostname)
      [ ${#h} -gt 14 ] && h="${h:0:14}…"
      echo "$h"
    fi
    ;;
  conn_mosh)
    conn=$(detect_connection)
    [ "$conn" = "mosh" ] && printf ' \uf0e7'
    ;;
  conn_ssh)
    conn=$(detect_connection)
    [[ "$conn" = "ssh" || "$conn" = "devpod" ]] && printf ' \uf023'
    ;;
  conn_local)
    conn=$(detect_connection)
    [ "$conn" = "local" ] && printf ' \uf108'
    ;;
  ip)
    ip -4 addr show 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1 | head -1
    ;;
  cpu)
    cpus=$(nproc)
    read u1 t1 <<< $(awk '/^cpu /{u=$2+$4; t=$2+$3+$4+$5+$6+$7+$8; print u, t}' /proc/stat)
    sleep 1
    read u2 t2 <<< $(awk '/^cpu /{u=$2+$4; t=$2+$3+$4+$5+$6+$7+$8; print u, t}' /proc/stat)
    if [ $((t2 - t1)) -gt 0 ]; then
      cpu_pct=$(( (u2 - u1) * 100 / (t2 - t1) ))
    else
      cpu_pct=0
    fi
    color="#6C7086"
    [ "$cpu_pct" -ge 50 ] && color="#F9E2AF"
    [ "$cpu_pct" -ge 80 ] && color="#F38BA8"
    printf "#[fg=%s]\uf2db %-2s %s%%" "$color" "${cpus}" "${cpu_pct}"
    ;;
  mem)
    mem_total=$(free -m | awk '/Mem:/{print int(($2 + 1023) / 1024)}')
    mem_pct=$(free | awk '/Mem:/{printf "%d", $3*100/$2}')
    color="#6C7086"
    [ "$mem_pct" -ge 80 ] && color="#F9E2AF"
    [ "$mem_pct" -ge 95 ] && color="#F38BA8"
    printf "#[fg=%s]\uefc5 %-2s %s%%" "$color" "${mem_total}" "${mem_pct}"
    ;;
  network)
    read rx1 tx1 <<< $(awk '!/lo:/ && /:/{rx+=$2; tx+=$10} END{printf "%d %d\n", rx, tx}' /proc/net/dev)
    sleep 1
    read rx2 tx2 <<< $(awk '!/lo:/ && /:/{rx+=$2; tx+=$10} END{printf "%d %d\n", rx, tx}' /proc/net/dev)
    rx_rate=$(( (rx2 - rx1) / 1024 ))
    tx_rate=$(( (tx2 - tx1) / 1024 ))
    if [ $rx_rate -gt 1024 ]; then
      rx_str="$(( rx_rate / 1024 ))M"
    else
      rx_str="${rx_rate}K"
    fi
    if [ $tx_rate -gt 1024 ]; then
      tx_str="$(( tx_rate / 1024 ))M"
    else
      tx_str="${tx_rate}K"
    fi
    rx_color="#6C7086"
    [ $rx_rate -ge 5120 ] && rx_color="#F9E2AF"
    tx_color="#6C7086"
    [ $tx_rate -ge 5120 ] && tx_color="#F9E2AF"
    printf "#[fg=%s]\uf019 %-4s #[fg=%s]\uf093 %-4s" "$rx_color" "${rx_str}" "$tx_color" "${tx_str}"
    ;;
esac
