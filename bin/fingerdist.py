#!/usr/bin/env python
import sys
import chromaprint


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


in_file = sys.argv[1] if len(sys.argv) > 1 else sys.stdin

fps = []
for line in open(in_file).readlines():
    if not line.startswith('FAILED:'):
        encoded, filename = line.split(' ', 1)
        fps.append((filename.strip(), chromaprint.decode_fingerprint(encoded.strip())[0]))

for i, fp1 in enumerate(fps):
    for j, fp2 in enumerate(fps):
        if i == j:
            continue
        file1, array1 = fp1
        file2, array2 = fp2
        if len(array1) == 0:
            print "FAILED: No fingerprint for {}".format(file1), file1, file2
            continue
        if len(array2) == 0:
            print "FAILED: No fingerprint for {}".format(file2), file1, file2
            continue
        error = 0
        for x, y in zip(array1, array2):
            error += popcnt(x ^ y)
        print error / 32.0 / min(len(array1), len(array2)), file1, file2
    print
