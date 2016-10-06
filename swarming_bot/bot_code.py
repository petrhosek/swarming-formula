#!/usr/bin/env python

import requests

r = requests.get('http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token', headers={'Metadata-Flavor': 'Google'})
r = requests.get('https://chromium-swarm-dev.appspot.com/bot_code', headers={'Authorization': 'Bearer %(access_token)s' % r.json()}, stream=True)
with open('/b/swarm_slave/swarming_bot.zip', 'wb') as fd:
  for chunk in r.iter_content(chunk_size=4096):
    fd.write(chunk)
