# setup the pretty
{% set minion_location = salt['grains.get']('location', '') %}
{% set twilio_pic = salt['pillar.get']('suse_background', '../img/bg1.jpg') %}
{% set title = salt['pillar.get']('suse_title', 'Salted Apache') %}
{% set customer = salt['pillar.get']('suse_customer_1', 'Salty the Cube') %}
{% set customer_subtitle = salt['pillar.get']('suse_cust1sub', 'Get Salted') %}
{% set customer_image = salt['pillar.get']('suse_cust1img', 'img/team/1.jpg') %}

apache2:
  pkg:
    - installed
    - version:
    - source: salt://
  service:
    - running
    - require:
      - pkg: apache2

/srv/www/htdocs/:
  file.recurse:
    - source: salt://{{ slspath }}/pretty
    - template: jinja
    - include_empty: True
    - defaults:
        back_pic: {{ twilio_pic }}
        web_title: {{ title }}
        cust_name: {{ customer }}
        cust_subtitle: {{ customer_subtitle }}
        cust_image: {{ customer_image }}
    - require:
      - pkg: apache2
    - watch_in:
      - service: apache2

"Notification of Install":
  slack.post_message:
    - channel: 'general'
    - from_name: 'SaltStack Automation'
{% if minion_location == 'local' %}
    - message: 'Apache was just installed on {{ grains['id'] }}. Browse to <http://{{ salt['network.interface_ip']('eth1') }}> to see it.'
{% else %}
    - message: 'Apache was just installed on {{ grains['id'] }}. Browse to <http://{{ salt['network.interface_ip']('eth0') }}> to see it.'
{% endif %}
    - api_key: {{ pillar['slack_api'] }}
