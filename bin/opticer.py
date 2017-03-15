#!/usr/bin/env python

import json
import pprint
import requests

optic_apps = 'http://optic.aus.optiver.com/api/v2/applications/'
args = {
    'app_name__re': r'(?:^ae_|_ae_)',
    'colo__eq': 'jpx',
}

resp = requests.get(optic_apps, args)
result_dict = resp.json()

print 'Got %s results in %.1f millis' %(len(result_dict['_items']), 1.0e+3*result_dict['_query_time_seconds'])
pprint.pprint(result_dict)
