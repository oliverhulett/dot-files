run = {
    'encoding': 'UTF8',
    'echo': True,
}

## Can't import modules, only concrete objects/functions.
## All vars (including imported things) need to have an underscore prefix if you want them ignored by invoke.
from os import environ as _environ
from os.path import join as _join, expanduser as _expanduser
_auth = open(_expanduser(_join("~", "etc", "release.auth"))).read().strip().split(':')

_environ['SMB_USER'] = 'olihul'
_environ['SMB_PASS'] = '4tyTw0!?'
_environ['WIKI_USER'] = _auth[0]
_environ['WIKI_PASS'] = _auth[1]

## Special case for my crazy bashrc-ness, doesn't play nicely with invoke's case normalisation
_environ.pop('http_proxy', None)
_environ.pop('https_proxy', None)
_environ.pop('no_proxy', None)
