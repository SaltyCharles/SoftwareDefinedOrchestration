# Example of including another file

include:
  - .init

"HA Proxy configuation file":
  file.managed:
    - name: /etc/haproxy/haproxy.cfg
    - source: salt://haproxy/haproxy.cfg
    - template: jinja
    - require:
      - file: /etc/default/haproxy
      - pkg: haproxy
    - watch_in:
      - service: haproxy
