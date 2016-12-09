# Predictive Orchestration reactor call
# Based on an event (service crashed) the following orchestration steps are run

# Send a notification of the crash
# Remove old system from the web pool (including grains and beacons)
# Stop the minion
# Start a new minion and ensure it's up to parity with the other webservers
# Update haproxy config to replace old server with new


"Service Crashed":
  salt.state:
    - tgt: 'aws-masters-minion'
    - sls:
      - slack.blast
    - pillar:
        mymessage: "Excuse me, one of your web services have crashed. Spinning up another node."

# This is a convenience state run for future demonstrations
"Remove Apache2":
  salt.state:
    - tgt: 'web1'
    - sls:
      - apache.removed
      - beacons.service-disable
      - grains.roles-removed

"Stop SUSE Minion":
  salt.runner:
    - name: cloud.action
    - func: stop
    - instances:
      - web1
    - require:
      - salt: "Remove Apache2"

"Start web Minion":
  salt.runner:
    - name: cloud.action
    - func: start
    - instances:
      - web3

"New Server Spun Up":
  salt.state:
    - tgt: 'aws-masters-minion'
    - sls:
      - slack.blast
    - pillar:
        mymessage: "No worries, we've spun up a new webserver."

"Set New Webserver Grains":
  salt.function:
    - tgt: 'aws-masters-minion'
    - name: cmd.run
    - arg:
      - salt web3 grains.setval roles webserver
    - require:
      - salt: "New Server Spun Up"

"Send Mine Details to SaltMaster":
  salt.function:
    - tgt: 'web3'
    - name: cmd.run
    - arg:
      - salt-call mine.send network.ip_addrs

"Ensure new webserver has the latest code":
  salt.state:
    - tgt: 'web3'
    - sls:
      - apache.pretty

"Update haproxy":
  salt.state:
    - tgt: 'haproxy'
    - sls: haproxy.config
    - require:
      - salt: "Send Mine Details to SaltMaster"

"Send Completion Notification":
  salt.state:
    - tgt: 'aws-masters-minion'
    - sls:
      - slack.blast
    - pillar:
        mymessage: "Yikes, that was a close one! Everything is back to normal.  You may want to research the failure on web1."
    - require:
      - salt: "Update haproxy"