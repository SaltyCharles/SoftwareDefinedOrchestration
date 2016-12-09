# Predictive Orchestration

# Starts three Servers (in aws)
# Installs apache
# Ensure mine data is cleared (from previous demo)
# Update mine with new device details
# Execute highstate on web servers
# Send notifications
# Update haproxy config to add web servers

"Start SUSE Minions":
  salt.runner:
    - name: cloud.action
    - func: start
    - instances:
      - web1
      - web2
      - haproxy

"Put short pause in for web system to catch up":
  salt.function:
    - tgt: 'aws-masters-minion'
    - name: test.sleep
    - kwarg:
        length: 60

"Setup Minion Custom Grains":
  salt.function:
    - tgt: 'aws-masters-minion'
    - name: cmd.run
    - arg:
      - salt -C 'L@web1,web2' grains.setval roles webserver

"Setup haproxy Custom Grains":
  salt.function:
    - tgt: 'aws-masters-minion'
    - name: cmd.run
    - arg:
      - salt 'haproxy' grains.setval roles webserver-ha

"Clear old Mine Data":
  salt.runner:
    - name: cache.clear_all
    - tgt: web3

"Set up the Salt Mine":
  salt.function:
    - tgt: 'web1,web2,haproxy'
    - tgt_type: list
    - name: cmd.run
    - arg:
      - salt-call mine.send network.ip_addrs interface=eth0

"Send SUSE message to slack":
  salt.state:
    - tgt: 'aws-masters-minion'
    - sls:
      - slack.blast
    - pillar:
        mymessage: "New SUSE Servers have been deployed"

"Execute Highstate on web boxes":
  salt.state:
    - tgt: 'web1,web2,haproxy'
    - tgt_type: list
    - highstate: True

"Send web server highstate message to slack":
  salt.state:
    - tgt: 'aws-masters-minion'
    - sls:
      - slack.blast
    - pillar:
        mymessage: "Highstate for new web servers has been executed"

"Update haproxy":
  salt.state:
    - tgt: 'haproxy'
    - sls: haproxy.config
    - require:
      - salt: "Send web server highstate message to slack"

{% set minion_ips = salt.saltutil.runner('mine.get',
    tgt='haproxy',
    fun='network.ip_addrs',
    tgt_type='glob') %}

{% for serv, addr in minion_ips.iteritems() %}

"Send HAProxy message to slack":
  salt.state:
    - tgt: 'aws-masters-minion'
    - sls:
      - slack.blast
    - pillar:
        mymessage: "HAProxy has been updated. Browse to <http://{{ addr[0] }}/haproxy?stats> to see it."
{% endfor %}