{% set pools = pillar.get('zfs', {}).get('pools', {}) %}

{% for pool_name, config in pools.items() %}
{% set devices = config.get('data_devices', []) + config.get('special_devices', []) %}
validate_zpool_devices_{{ pool_name }}:
  cmd.run:
    - name: |
        set -eu
        devices=({% for device in devices %}'{{ device }}' {% endfor %})
        [ "${#devices[@]}" -gt 0 ] || { echo "No devices configured for pool {{ pool_name }}" >&2; exit 1; }
        declare -A seen=()
        for device in "${devices[@]}"; do
          case "$device" in
            /dev/disk/by-id/*) ;;
            *) echo "Refusing {{ pool_name }} device '$device': use /dev/disk/by-id/*" >&2; exit 1 ;;
          esac
          [ -e "$device" ] || { echo "Missing device: $device" >&2; exit 1; }
          real="$(readlink -f -- "$device")"
          [ -n "$real" ] || { echo "Unable to resolve device: $device" >&2; exit 1; }
          [ "$(lsblk -dnro TYPE -- "$real")" = "disk" ] || { echo "Not a whole disk: $device ($real)" >&2; exit 1; }
          if lsblk -nrpo MOUNTPOINT -- "$real" | awk 'NF { found=1 } END { exit !found }'; then
            echo "Device is mounted: $device ($real)" >&2
            exit 1
          fi
          [ -z "${seen[$real]+x}" ] || { echo "Duplicate device: $device ($real)" >&2; exit 1; }
          seen[$real]=1
        done
    - shell: /bin/bash
{% endfor %}
