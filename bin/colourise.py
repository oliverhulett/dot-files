#!/usr/bin/python26 -u
#
#   Colourize log files.
#

import sys, os
import re

class Colouriser(object):
    def __init__(self, pattern=None):
        ##  Bash colours.  From: http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/x329.html
        self.colours = {#'Black':       '0;30',
                        'Dark Gray':   '1;30',
                        'Blue':        '0;34',
                        'Light Blue':  '1;34',
                        'Green':       '0;32',
                        'Light Green': '1;32',
                        'Cyan':        '0;36',
                        'Light Cyan':  '1;36',
                        'Red':         '0;31',
                        'Light Red':   '1;31',
                        'Purple':      '0;35',
                        'Light Purple':'1;35',
                        'Brown':       '0;33',
                        #'Yellow':      '1;33',
                        #'Light Gray':  '0;37',
                        #'White':       '1;37',
                        'reset':       '0'
                        }

        ##  These are the sequences need to get colored ouput.
        self.reset_seq = "\033[0m"
        self.colour_seq_tmpl = "\033[%sm"
        self.bold_seq = "\033[1m"
        ##  Counters and maps
        self.next_colour = 0
        self.colour_map = {}
        self.regex = None

        self.fallback_regex = re.compile(r"[0-9-:,\. ]+ \[?([^\] ]+)\]?.+")
        self.default_regexes = [
                                re.compile(r"[0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{9} \[[^\]]+\] \[([^\]]+)\].+"),
                                re.compile(r"[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3} \[[^\]]+\] ([^:]+):.+")
                                ]
        if (pattern is not None):
            self.regex = re.compile(pattern)

        try:
            sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)
        except:
            pass

    def doColourise(self, fd):
        while True:
            try:
                sys.stdout.flush()
                line = fd.readline()
            except KeyboardInterrupt:
                break
            if not line:
                break

            if (self.regex is None):
                self.regex = self.fallback_regex
                for reg in self.default_regexes:
                    if (reg.match(line) is not None):
                        self.regex = reg
                        break

            match = self.regex.match(line)
            try:
                logmodule = match.group(1)
                if (logmodule not in self.colour_map):
                    self.colour_map[logmodule] = self.colours.keys()[self.next_colour % len(self.colours)]
                    self.next_colour += 1
                colour = self.colour_seq_tmpl % (self.colours[self.colour_map[logmodule]])
                print "%s%s%s" % (colour, line.strip(), self.reset_seq)
            except:
                print line.strip()

if __name__ == '__main__':
    consumed = 1
    try:
        pattern = sys.argv[1]
        if (os.path.isfile(pattern)):
            raise
        else:
            colouriser = Colouriser(pattern)
            consumed += 1
    except:
        colouriser = Colouriser()
    if (len(sys.argv) == consumed):
        print "Colourising stdin..."
        try:
            sys.stdin = os.fdopen(sys.stdin.fileno(), 'r', 0)
        except:
            pass
        colouriser.doColourise(sys.stdin)
    else:
        for filename in sys.argv[consumed:]:
            try:
                print "Colourising " + filename + "..."
                with open(filename, 'r') as f:
                    colouriser.doColourise(f)
            except:
                print sys.stderr, str(sys.exc)
