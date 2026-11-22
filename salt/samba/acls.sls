{% set datasets = pillar.get('zfs', {}).get('datasets', {}) %}
{% set shares = pillar.get('samba', {}).get('shares', []) %}

{% for pool, dataset_list in datasets.items() %}
{% for dataset in dataset_list %}
{% set share_path = '/' ~ pool ~ '/' ~ dataset %}
{# Own only the dataset root, as the Samba user forced onto this path.
   Recursing would chown every existing file on the next apply. #}
{% set ns = namespace(owner='root') %}
{% for share in shares %}
{% set share_path_raw = share.get('path', '') if share is mapping else '' %}
{% set candidate = share.get('valid_users', '') if share is mapping else '' %}
{% if share_path_raw is string and share_path_raw.rstrip('/') == share_path and candidate is string and candidate %}
{% set ns.owner = candidate %}
{% endif %}
{% endfor %}

{{ pool }}_{{ dataset }}_ownership:
  file.directory:
    - name: {{ share_path }}
    - user: '{{ ns.owner }}'
    - group: '{{ ns.owner }}'
    - mode: '0755'
    - require:
      - cmd: ensure_{{ pool }}_{{ dataset }}
{% if ns.owner != 'root' %}
      - user: samba_user_{{ ns.owner }}
{% endif %}

{% endfor %}
{% endfor %}
