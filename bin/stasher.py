#!/usr/bin/env python
"""
    Simplified command line interface to the stash REST API.
"""

import sys, os
import time
import getpass
import argparse
import stashy
import logging


class Stashy(object):
    @classmethod
    def parse_args(cls, args):
        """
        Define arguments and return the parsed args.
        """
        parser = argparse.ArgumentParser(
            description="Simple command line interface to the Stash REST API at git.aus.optiver.com",
            epilog="Because Stash access is via HTTPS, ensure you have one of REQUESTS_CA_BUNDLE or CURL_CA_BUNDLE " +
                   "environment variables set to the path of your ca-bundle.crt.  " +
                   "Usually this will be /etc/pki/tls/certs/ca-bundle.crt",
        )

        parser.add_argument('--username', default=None, nargs=1, help="Username for git.aus.optiver.com")
        parser.add_argument('--password', default=None, nargs=1, help="Password for git.aus.optiver.com")
        parser.add_argument('-v', '--verbose', action='count', help="Verbosity level, use again for more verbosity.")
        parser.add_argument('-q', '--quiet', action='store_true', help="Quiet running.  Overrides verbosity level.")

        parser.add_argument('-b', '--branches', action='store_true',
                            help="Print branches (if project and repo are found.)")
        parser.add_argument('-t', '--tags', action='store_true',
                            help="Print tags (if project and repo are found.)")

        parser.add_argument('args', nargs=argparse.REMAINDER, help="[[project] repo")

        return parser.parse_args(args)

    def __init__(self, args):
        self.logger = logging.getLogger("STASHER")
        verbosity = min(2, args.verbose if args.verbose is not None else 0)
        self.logger.setLevel(
            logging.CRITICAL if args.quiet else (logging.WARNING, logging.INFO, logging.DEBUG)[verbosity]
        )

        self.branches = args.branches
        self.tags = args.tags

        username = args.username if args.username is not None else getpass.getuser()
        password = args.password
        if args.password is None:
            password = open(os.path.join(os.path.expanduser('~'), "etc", "passwd")).read().strip()
            if len(password) == 0:
                raise "Could not determine git password for {0}".format(username)
        url = "https://git.aus.optiver.com/"
        if args.verbose > 2:
            self.logger.debug("Info=\"Connecting to git\" Url=\"%s\" Username=\"%s\" Password=\"%s\"",
                              url, username, password)
        else:
            self.logger.info("Info=\"Connecting to git\" Url=\"%s\" Username=\"%s\"", url, username)
        self.stash = stashy.connect(url, username, password)
        self._projects = None
        self._project_keys = []
        self._repo_slugs = {}

        self._cache_file = os.path.join(
            os.environ['TMPDIR'] if 'TMPDIR' in os.environ else '/tmp',
            '.stasher-cache-{0}'.format(username)
        )

    def _pp_from_stash(self):
        self.logger.info("Info=\"Pre-populating project list from stash\"")
        self._projects = self.stash.projects.list()
        self._project_keys = [p['key'] for p in self._projects]
        self.logger.info("Info=\"Pre-populating repository list from stash\"")
        for project in self._project_keys:
            self.logger.debug("Info=\"Pre-populating repository list from stash\" Project=%s", project)
            repo_list = self.stash.projects[project].repos.list()
            self._repo_slugs[project] = [r['slug'] for r in repo_list]
        self.logger.debug("Info=\"Finished pre-populating data from stash\"")

    def _pp_from_file(self):
        if not os.path.exists(self._cache_file) or ((time.time() - os.path.getmtime(self._cache_file)) > (60 * 60)):
            return
        with open(self._cache_file, 'r') as f:
            self.logger.info("Info=\"Pre-populating project list from file\"")
            for l in f:
                proj, repo = l.split()
                proj = proj.strip()
                repo = repo.strip()
                self._project_keys.append(proj)
                if proj not in self._repo_slugs:
                    self._repo_slugs[proj] = []
                self._repo_slugs[proj].append(repo)
        self._project_keys = list(set(self._project_keys))
        for proj in self._project_keys:
            self._repo_slugs[proj] = list(set(self._repo_slugs[proj]))
        self.logger.debug("Info=\"Finished pre-populating data from file\"")

    def _write_stash_file(self):
        self.logger.info("Info=\"Writing project list to cache file\"")
        with open(self._cache_file, 'w') as f:
            for proj in self._project_keys:
                for repo in self._repo_slugs[proj]:
                    f.write("{0} {1}\n".format(proj, repo))
        self.logger.debug("Info=\"Finished writing data to cache file\"")

    def pre_populate(self):
        if len(self._project_keys) == 0:
            self._pp_from_file()
        if len(self._project_keys) == 0:
            self.logger.warn("Info=\"Could not read from cache, populating project list from stash\"")
            self._pp_from_stash()
            self._write_stash_file()

    def dump(self, args):
        self.pre_populate()
        if len(args) == 0:
            self.logger.debug("Info=\"Printing projects\"")
            self._print_projects()
            return
        proj = args[0].upper()
        repo = None
        if proj not in self._project_keys:
            proj = None
            repo = args[0]
            for p in self._project_keys:
                if repo in self._repo_slugs[p]:
                    proj = p
                    break
        if proj not in self._project_keys:
            self.logger.error("Error=\"Argument not found as project or repository\" Arg=%s", args[0])
            return
        if repo is None:
            if len(args) > 1:
                repo = args[1]
        if repo is None:
            self.logger.debug("Info=\"Printing repositories\" ProjectKey=%s", proj)
            self._print_repos(proj)
            return
        if repo not in self._repo_slugs[proj]:
            self.logger.error("Error=\"Repo not found\" ProjectKey=%s RepoSlug=%s", proj, repo)
            return
        if not self.branches and not self.tags:
            print proj, repo
        if self.branches:
            self.logger.debug("Info=\"Printing branches\" ProjectKey=%s RepoSlug=%s", proj, repo)
            self._print_branches(proj, repo)
        if self.tags:
            self.logger.debug("Info=\"Printing tags\" ProjectKey=%s RepoSlug=%s", proj, repo)
            self._print_tags(proj, repo)

    def _print_projects(self):
        for p in self._project_keys:
            print p

    def _print_repos(self, proj):
        for r in self._repo_slugs[proj]:
            print proj, r

    def _print_branches(self, proj, repo):
        r = self.stash.projects[proj].repos[repo]
        for b in [branch['displayId'] for branch in r.branches()]:
            print proj, repo, b

    def _print_tags(self, proj, repo):
        r = self.stash.projects[proj].repos[repo]
        for t in [tag['displayId'] for tag in r.tags()['values']]:
            print proj, repo, t


if __name__ == '__main__':
    logging.basicConfig(format='%(asctime)s [%(levelname)s] [%(name)s] %(message)s')
    args = Stashy.parse_args(sys.argv[1:])
    s = Stashy(args)
    s.pre_populate()
    s.dump(args.args)
