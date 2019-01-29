run = {
    'encoding': 'UTF8',
    'echo': True,
    'hide': False,
}

def _update_env():
    ## Can't import modules, only concrete objects/functions.
    ## All vars (including imported things) need to have an underscore prefix if you want them ignored by invoke.
    from os import environ as _environ
    from os.path import join as _join, expanduser as _expanduser, exists as _exists
    from getpass import getuser as _getuser

    _release_auth_file = _expanduser(_join("~", "etc", "release.auth"))
    if _exists(_release_auth_file):
        _auth = open(_release_auth_file).read().strip().split(':')
        _environ['WIKI_USER'] = _auth[0]
        _environ['WIKI_PASS'] = _auth[1]
        _environ['JIRA_USER'] = _auth[0]
        _environ['JIRA_PASS'] = _auth[1]

    _passwd_file = _expanduser(_join("~", "etc", "passwd"))
    if _exists(_passwd_file):
        _pass = open(_passwd_file).read().strip()
        _environ['SMB_USER'] = _getuser()
        _environ['SMB_PASS'] = _pass


_update_env()
