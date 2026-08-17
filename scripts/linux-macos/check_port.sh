#!/usr/bin/env bash
#
# check_port.sh
# Cross‑platform (Linux/macOS) DevOps‑friendly port checker.
#
# Features:
#  - Shows: COMMAND, PID, USER, BIND_ADDRESS, STATE, FULL_COMMAND
#  - Highlights: localhost only vs all interfaces
#  - Distinguishes: LISTEN vs other states
#  - Optional: Docker container name if docker is available
#
# Make script executable: chmod +x check_port.sh
# Usage: ./check_port.sh <port>
# Example: ./check_port.sh 8080
#

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <port>"
  echo "Example: $0 8080"
  exit 1
fi

PORT="$1"

if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
  echo "Error: port must be a number."
  exit 1
fi

OS="$(uname -s)"

# Helper: try to get container name from docker if PID looks like a Docker/VM process
try_resolve_container() {
  local pid="$1"
  # If docker is available, try to find a container publishing this port
  if command -v docker >/dev/null 2>&1; then
    # Fast path: search by port directly
    local container
    container="$(docker ps --format 'table {{.Names}}\t{{.Ports}}' 2>/dev/null | grep ":${PORT}" | awk '{print $1}' | head -n1 || true)"
    if [ -n "$container" ]; then
      echo "$container"
      return 0
    fi
  fi
  echo "-"
}

# Helper: get full command line for a PID
get_full_command() {
  local pid="$1"
  if command -v ps >/dev/null 2>&1; then
    # Try to get full command; fallback to just PID if it fails
    ps -o command= -p "$pid" 2>/dev/null || echo "unknown"
  else
    echo "unknown"
  fi
}

# Helper: classify bind address
classify_bind() {
  local name="$1"
  # Examples:
  # *:8080 (LISTEN)
  # 0.0.0.0:8080 (LISTEN)
  # 127.0.0.1:8080 (LISTEN)
  # ::1:8080 (LISTEN)
  # [::]:8080 (LISTEN)
  if echo "$name" | grep -qE '^\*:'; then
    echo "all_interfaces"
  elif echo "$name" | grep -qE '^0\.0\.0\.0:'; then
    echo "all_interfaces"
  elif echo "$name" | grep -qE '^\[::\]:'; then
    echo "all_interfaces_ipv6"
  elif echo "$name" | grep -qE '^127\.0\.0\.1:'; then
    echo "localhost_ipv4"
  elif echo "$name" | grep -qE '^\[::1\]:'; then
    echo "localhost_ipv6"
  elif echo "$name" | grep -qE '^::1:'; then
    echo "localhost_ipv6"
  else
    echo "other"
  fi
}

# Helper: extract state from lsof NAME field
extract_state() {
  local name="$1"
  if echo "$name" | grep -qi '(LISTEN)'; then
    echo "LISTEN"
  elif echo "$name" | grep -qi '(ESTABLISHED)'; then
    echo "ESTABLISHED"
  elif echo "$name" | grep -qi '(TIME_WAIT)'; then
    echo "TIME_WAIT"
  elif echo "$name" | grep -qi '(CLOSE_WAIT)'; then
    echo "CLOSE_WAIT"
  else
    echo "OTHER"
  fi
}

# Helper: extract bind address string from lsof NAME field
extract_bind_address() {
  local name="$1"
  # Strip state part like " (LISTEN)"
  local addr
  addr="$(echo "$name" | sed 's/ *(.*)//')"
  echo "$addr"
}

case "$OS" in
  Linux|Darwin)
    # Prefer lsof if available
    if command -v lsof >/dev/null 2>&1; then
      OUTPUT=$(sudo lsof -n -P -i "TCP:$PORT" 2>/dev/null || true)
      if [ -z "$OUTPUT" ]; then
        echo "Port $PORT is NOT in use (no TCP entries found)."
        exit 0
      fi

      # Print header for our DevOps‑friendly table
      printf "%-15s %-8s %-12s %-25s %-12s %-25s %-20s\n" \
        "COMMAND" "PID" "USER" "BIND_ADDRESS" "STATE" "CONTAINER/SVC" "FULL_COMMAND"
      printf "%s\n" "---------------------------------------------------------------------------------------------------------------"

      # Skip header line of lsof
      echo "$OUTPUT" | tail -n +2 | while read -r line; do
        # Parse lsof fields; be careful with spaces in NAME
        # Fields: COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME...
        # We'll use awk to split first 8 fields, rest is NAME
        cmd="$(echo "$line" | awk '{print $1}')"
        pid="$(echo "$line" | awk '{print $2}')"
        user="$(echo "$line" | awk '{print $3}')"
        # NAME is from field 9 to end
        name="$(echo "$line" | awk '{for(i=9;i<=NF;i++) printf "%s ", $i; print ""}' | sed 's/ *$//')"

        bind_raw="$(extract_bind_address "$name")"
        state="$(extract_state "$name")"
        bind_class="$(classify_bind "$bind_raw")"

        case "$bind_class" in
          all_interfaces|all_interfaces_ipv6)
            bind_display="all_interfaces ($bind_raw)"
            ;;
          localhost_ipv4|localhost_ipv6)
            bind_display="localhost_only ($bind_raw)"
            ;;
          *)
            bind_display="other ($bind_raw)"
            ;;
        esac

        full_cmd="$(get_full_command "$pid")"
        container="$(try_resolve_container "$pid")"

        # Truncate long fields for readability
        cmd_disp="${cmd:0:15}"
        user_disp="${user:0:12}"
        bind_disp="${bind_display:0:25}"
        state_disp="${state:0:12}"
        container_disp="${container:0:20}"
        full_disp="${full_cmd:0:40}"

        printf "%-15s %-8s %-12s %-25s %-12s %-20s %-40s\n" \
          "$cmd_disp" "$pid" "$user_disp" "$bind_disp" "$state_disp" "$container_disp" "$full_disp"
      done

      # Summary
      echo
      echo "Summary by command:"
      echo "$OUTPUT" | tail -n +2 | awk '{print $1}' | sort | uniq -c | sort -rn | while read -r count cmd; do
        echo "  - $cmd : $count entry/entries"
      done

    elif command -v ss >/dev/null 2>&1; then
      # Fallback to ss on Linux
      OUTPUT=$(sudo ss -tlnp 2>/dev/null | grep ":$PORT " || true)
      if [ -z "$OUTPUT" ]; then
        echo "Port $PORT is NOT in use (no TCP listeners found)."
        exit 0
      fi

      printf "%-15s %-8s %-12s %-25s %-12s %-20s %-40s\n" \
        "COMMAND" "PID" "USER" "BIND_ADDRESS" "STATE" "CONTAINER/SVC" "FULL_COMMAND"
      printf "%s\n" "---------------------------------------------------------------------------------------------------------------"

      echo "$OUTPUT" | while read -r line; do
        # Example ss line:
        # LISTEN 0 128 0.0.0.0:8080 0.0.0.0:* users:(("java",pid=1234,fd=90))
        bind_raw="$(echo "$line" | awk '{print $4}')"
        # Extract users part
        users_part="$(echo "$line" | grep -oP 'users:\(\("[^"]+",pid=\d+[^)]*\)' || true)"
        if [ -z "$users_part" ]; then
          continue
        fi
        cmd="$(echo "$users_part" | grep -oP '^users:\(\("[^"]+"' | sed 's/users:(("//')"
        pid="$(echo "$users_part" | grep -oP 'pid=\d+' | head -n1 | sed 's/pid=//')"
        user="$(id -un 2>/dev/null || echo "unknown")"

        bind_class="$(classify_bind "$bind_raw")"
        case "$bind_class" in
          all_interfaces|all_interfaces_ipv6)
            bind_display="all_interfaces ($bind_raw)"
            ;;
          localhost_ipv4|localhost_ipv6)
            bind_display="localhost_only ($bind_raw)"
            ;;
          *)
            bind_display="other ($bind_raw)"
            ;;
        esac

        state="LISTEN"
        full_cmd="$(get_full_command "$pid")"
        container="$(try_resolve_container "$pid")"

        cmd_disp="${cmd:0:15}"
        user_disp="${user:0:12}"
        bind_disp="${bind_display:0:25}"
        state_disp="${state:0:12}"
        container_disp="${container:0:20}"
        full_disp="${full_cmd:0:40}"

        printf "%-15s %-8s %-12s %-25s %-12s %-20s %-40s\n" \
          "$cmd_disp" "$pid" "$user_disp" "$bind_disp" "$state_disp" "$container_disp" "$full_disp"
      done

      echo
      echo "Summary by command:"
      echo "$OUTPUT" | grep -oP 'users:\(\("[^"]+"' | sed 's/users:(("//' | sort | uniq -c | sort -rn | while read -r count cmd; do
        echo "  - $cmd : $count entry/entries"
      done

    elif command -v netstat >/dev/null 2>&1; then
      # Fallback to netstat (older systems)
      OUTPUT=$(sudo netstat -tlnp 2>/dev/null | grep ":$PORT " || true)
      if [ -z "$OUTPUT" ]; then
        echo "Port $PORT is NOT in use (no TCP listeners found)."
        exit 0
      fi

      printf "%-15s %-8s %-12s %-25s %-12s %-20s %-40s\n" \
        "COMMAND" "PID" "USER" "BIND_ADDRESS" "STATE" "CONTAINER/SVC" "FULL_COMMAND"
      printf "%s\n" "---------------------------------------------------------------------------------------------------------------"

      echo "$OUTPUT" | while read -r line; do
        # Typical netstat -tlnp:
        # tcp        0      0 0.0.0.0:8080          0.0.0.0:*               LISTEN      1234/java
        bind_raw="$(echo "$line" | awk '{print $4}')"
        prog="$(echo "$line" | awk '{print $NF}')" # e.g. 1234/java
        pid="$(echo "$prog" | cut -d'/' -f1)"
        cmd="$(echo "$prog" | cut -d'/' -f2-)"
        user="$(id -un 2>/dev/null || echo "unknown")"
        state="LISTEN"

        bind_class="$(classify_bind "$bind_raw")"
        case "$bind_class" in
          all_interfaces|all_interfaces_ipv6)
            bind_display="all_interfaces ($bind_raw)"
            ;;
          localhost_ipv4|localhost_ipv6)
            bind_display="localhost_only ($bind_raw)"
            ;;
          *)
            bind_display="other ($bind_raw)"
            ;;
        esac

        full_cmd="$(get_full_command "$pid")"
        container="$(try_resolve_container "$pid")"

        cmd_disp="${cmd:0:15}"
        user_disp="${user:0:12}"
        bind_disp="${bind_display:0:25}"
        state_disp="${state:0:12}"
        container_disp="${container:0:20}"
        full_disp="${full_cmd:0:40}"

        printf "%-15s %-8s %-12s %-25s %-12s %-20s %-40s\n" \
          "$cmd_disp" "$pid" "$user_disp" "$bind_disp" "$state_disp" "$container_disp" "$full_disp"
      done

      echo
      echo "Summary by command:"
      echo "$OUTPUT" | awk '{print $NF}' | sed 's/^[0-9]*\///' | sort | uniq -c | sort -rn | while read -r count cmd; do
        echo "  - $cmd : $count entry/entries"
      done

    else
      echo "Error: no suitable tool found (need lsof, ss, or netstat)."
      exit 1
    fi
    ;;

  *)
    echo "Unsupported OS for this script: $OS"
    echo "On Windows, use the PowerShell version: check_port.ps1"
    exit 1
    ;;
esac