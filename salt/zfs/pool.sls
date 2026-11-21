{% set zfs = pillar.get('zfs', {}) %}
{% set pools = zfs.get('pools', {}) %}
{% set safety = zfs.get('safety', {}) %}
{% set allow_pool_creation = safety.get('allow_pool_creation', False) %}
{% set confirmation = safety.get('confirmation', '') %}

{% for pool_name, config in pools.items() %}
{% set data_devices = config.get('data_devices', []) %}
{% set special_devices = config.get('special_devices', []) %}
{% set layout = config.get('layout', 'mirror') %}
{% set vdev = (layout ~ ' ' ~ (data_devices | join(' '))) if layout != 'single' else (data_devices | join(' ')) %}
{% set special_vdev = (' special ' ~ config.get('special_layout', 'mirror') ~ ' ' ~ (special_devices | join(' '))) if special_devices else '' %}

{% if allow_pool_creation and confirmation == 'CREATE_ZFS_POOLS' %}
create_zpool_{{ pool_name }}:
  cmd.run:
    - name: >
        zpool create {{ pool_name }}
        {{ vdev }}{{ special_vdev }}
    - unless: zpool list -H -o name | grep -Fxq -- '{{ pool_name }}'
    - require:
      - cmd: validate_zpool_devices_{{ pool_name }}
{% else %}
zpool_creation_disabled_{{ pool_name }}:
  test.nop:
    - name: "Pool creation for {{ pool_name }} is disabled; set zfs.safety.allow_pool_creation=true and confirmation=CREATE_ZFS_POOLS to enable it."
{% endif %}

{% endfor %}
