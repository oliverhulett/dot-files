#!/usr/bin/env python
import sys
import chromaprint
import acoustid


popcnt_table_8bit = [
    0,1,1,2,1,2,2,3,1,2,2,3,2,3,3,4,1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5,
    1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5,2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,
    1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5,2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,
    2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,3,4,4,5,4,5,5,6,4,5,5,6,5,6,6,7,
    1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5,2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,
    2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,3,4,4,5,4,5,5,6,4,5,5,6,5,6,6,7,
    2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,3,4,4,5,4,5,5,6,4,5,5,6,5,6,6,7,
    3,4,4,5,4,5,5,6,4,5,5,6,5,6,6,7,4,5,5,6,5,6,6,7,5,6,6,7,6,7,7,8,
]

def popcnt(x):
    """
    Count the number of set bits in the given 32-bit integer.
    """
    return (popcnt_table_8bit[(x >>  0) & 0xFF] +
            popcnt_table_8bit[(x >>  8) & 0xFF] +
            popcnt_table_8bit[(x >> 16) & 0xFF] +
            popcnt_table_8bit[(x >> 24) & 0xFF])


if len(sys.argv) != 3:
    print "fingerdist.py <fingerprints.txt> <track.ogg>"
    print "  Requires exactly two arguments"
    sys.exit(1)

in_file = sys.argv[1]

fps = []
for line in open(in_file).readlines():
    if not line.startswith('FAILED:'):
        encoded, filename = line.split(' ', 1)
        fps.append((filename.strip(), chromaprint.decode_fingerprint(encoded.strip())[0]))

data = chromaprint.decode_fingerprint(acoustid.fingerprint_file(sys.argv[2])[1].decode("utf-8"))[0]
if len(data) == 0:
    print "FAILED to generate fingerprint:", sys.argv[2]

for j, fp in enumerate(fps):
    filename, array = fp
    if len(array) == 0:
        continue
    error = 0
    for x, y in zip(data, array):
        error += popcnt(x ^ y)
    print error / 32.0 / min(len(data), len(array)), filename
