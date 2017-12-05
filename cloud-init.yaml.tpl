#cloud-config

hostname: ${hostname}
manage_etc_hosts: false

runcmd:
  - ethtool -K eth0 tx off
  - systemctl restart rsyslog
  - date "+%Y-%m-%d %H:%M:%S" > /tmp/boottime
