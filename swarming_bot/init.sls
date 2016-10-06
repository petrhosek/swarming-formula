{% from "swarming_bot/map.jinja" import swarming_bot with context %}

swarming_group:
  group.present:
    - name: {{ swarming_bot.group }}
    - system: True

swarming_user:
  file.directory:
    - name: {{ swarming_bot.home }}
    - user: {{ swarming_bot.user }}
    - group: {{ swarming_bot.group }}
    - mode: 0755
    - require:
      - user: swarming_user
      - group: swarming_group
  user.present:
    - name: {{ swarming_bot.user }}
    - groups:
      - {{ swarming_bot.group }}
    - system: True
    - home: {{ swarming_bot.home }}
    - shell: /bin/bash
    - require:
      - group: swarming_group

swarming_sudoers
  file.append:
    - name: /etc/sudoers
    - text:
      - swarming ALL=NOPASSWD: /sbin/shutdown -r now
    - require:
      - user: swarming_user

swarming_packages:
  pkg.installed:
    - pkgs:
{% if grains['os'] == 'Ubuntu' %}
      - git
      - make
{% endif %}

swarm_slave:
  file.directory:
    - name: /b/swarm_slave
    - user: {{ swarming_bot.user }}
    - group: {{ swarming_bot.group }}
    - makedirs: True
    - require:
      - user: swarming_user
      - group: swarming_group

{% set name = {
    'Ubuntu': '/etc/init/swarming_bot.conf',
    'MacOS': '/Library/LaunchDaemons/org.chromium.swarming_bot.plist',
}.get(grains.os_family) %}
{% set source = {
    'Ubuntu': 'salt://swarming_bot/files/swarming_bot.conf',
    'MacOS': 'salt://swarming_bot/files/org.chromium.swarming_bot.plist',
}.get(grains.os_family) %}

swarming_service:
  cmd.script:
    - source: salt://swarming_bot/bot_code.py
    - creates: {{ swarming_bot.bot_path }}
    - require:
      - file: swarm_slave
  file.managed:
    - name: {{ name }}
    - source: {{ source }}
    - template: jinja
    - require:
      - cmd: swarming_service
  service.running:
    - name: {{ swarming_bot.service }}
    - enable: True
    - restart: True
    - require:
      - file: swarming_service
