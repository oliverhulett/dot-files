#!/usr/bin/env python3
import os
import sys
import acoustid

for i in sys.argv[1:]:
    try:
        print("{} {}".format(acoustid.fingerprint_file(i)[1].decode("utf-8"), os.path.abspath(i)))
    except KeyboardInterrupt:
        break
    except:
        print("FAILED: {}".format(i))
