{% set datasets = pillar.get('zfs', {}).get('datasets', {}) %}

{% for pool, dataset_list in datasets.items() %}
{% for dataset in dataset_list %}

{{ pool }}_{{ dataset }}_ownership:
  file.directory:
    - name: /{{ pool }}/{{ dataset }}
    - user: root
    - group: root
    - recurse:
      - user
      - group

{% endfor %}
{% endfor %}
