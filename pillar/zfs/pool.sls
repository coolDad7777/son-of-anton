zfs:
  pools:
    # Example:
    # media:
    #   layout: mirror
    #   data_devices:
    #     - /dev/disk/by-id/ata-disk-a
    #     - /dev/disk/by-id/ata-disk-b
    #   special_layout: mirror
    #   special_devices: []
    {}
  safety:
    allow_pool_creation: false
    confirmation: ""
