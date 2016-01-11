#!/usr/bin/env python
 
import os
 
CACHE_FILE = os.getenv('HOME') + "/.application_cache"
URL = 'http://optic.aus.optiver.com/api/v2/applications/'
AGE_BEFORE_UPDATE = 60 * 60 * 3 # Update the cache file if it's more than 3 hours old
 
def update_cache_file():
    import json
    import requests
    import urllib2
 
    f = open(CACHE_FILE, 'w')
    data = '\n'.join( [i['app_name']['title'] for i in requests.get(URL).json['_items']] )
    f.write(data)
    f.close()
    return data
 
def get_cache_file():
    f = open(CACHE_FILE, 'r')
    data = f.read()
    f.close()
    return data
 
def test_or_update_cache_file():
    if not os.path.exists(CACHE_FILE):
        return update_cache_file()
 
    else:
        import time
        if time.time() - os.stat(CACHE_FILE).st_mtime > AGE_BEFORE_UPDATE:
            return update_cache_file()
        else:
            return get_cache_file()
 
data = test_or_update_cache_file()
print data
