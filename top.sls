base:
  'G@roles:webserver':
    - apache.pretty
  'G@roles:webserver-ha':
    - haproxy.config