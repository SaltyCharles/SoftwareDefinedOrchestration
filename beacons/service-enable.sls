service:
  beacon.present:
    - apache2:
        onchangeonly: true
        uncleanshutdown: /var/run/httpd.pid
    - interval: 20
    - enabled: True
    - disable_during_state_run: True