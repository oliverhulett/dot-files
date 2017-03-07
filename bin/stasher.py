#!/usr/bin/env python

import sys, os
import getpass
import stashy
import argparse

def parse_args(args):
    parser = argparse.ArgumentParser(
        description="Simple command line interface to the Stash REST API at git.aus.optiver.com",
        epilog="Because Stash access is via HTTPS, ensure you have one of REQUESTS_CA_BUNDLE or CURL_CA_BUNDLE environment variables set to the path of your ca-bundle.crt.  Usually this will be /etc/pki/tls/certs/ca-bundle.crt",
    )

    return parser.parse_args(args)

class Stashy(object):
    def __init__(self):
        self.stash = stashy.connect("https://git.aus.optiver.com/", getpass.getuser(), open(os.path.join(os.path.expanduser('~'), "etc", "passwd")).read().strip())
        self._projects = self.stash.projects.list()
        self._project_keys = [p['key'] for p in self._projects]
        self._repos = {}
        self._repo_slugs = {}
        self._branch_names = {}
        self._tag_names = {}

    def dump(self, project=None, repo=None):
        if project is None:
            for p in self._project_keys:
                print p
            return
        elif project not in self._project_keys:
            print "Project not found: {0}".format(project)
            return

        # project is not None and is a valid project key, get the repos.
        if project not in self._repo_slugs:
            self._repos[project] = self.stash.projects[project].repos.list()
            self._repo_slugs[project] = [r['slug'] for r in self._repos[project]]
            self._branch_names[project] = {}
            self._tag_names[project] = {}

        if repo is None:
            for r in self._repo_slugs[project]:
                print r
            return
        elif repo not in self._repo_slugs[project]:
            print "Repo not found in {0}: {1}".format(project, repo)
            return

        # repo is not None and is a valid repo slug, get the branches.
        if repo not in self._branch_names[project]:
            self._branch_names[project][repo] = [b['displayId'] for b in self.stash.projects[project].repos[repo].branches()]
            self._tag_names[project][repo] = [t['displayId'] for t in self.stash.projects[project].repos[repo].tags()['values']]

        for b in self._branch_names[project][repo]:
            print "branch:", b
        print
        for t in self._tag_names[project][repo]:
            print "tag:", t
        for l in self.stash.projects[project].repos[repo].browse():
            print l

if __name__ == '__main__':
    Stashy().dump(*sys.argv[1:])
