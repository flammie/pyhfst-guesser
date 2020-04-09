#!/usr/bin/env python
# -*- coding: utf-8 -*-


"""
Turn unimorph strings into neatly aligned hfst strings.
"""


from argparse import ArgumentParser
from sys import stdin, stdout
from math import log

def hamming(s,t):
    return sum(1 for x,y in zip(s,t) if x != y)

def halign(s,t):
    """Align two strings by Hamming distance."""
    slen = len(s)
    tlen = len(t)
    minscore = len(s) + len(t) + 1
    for upad in range(0, len(t)+1):
        upper = '_' * upad + s + (len(t) - upad) * '_'
        lower = len(s) * '_' + t
        score = hamming(upper, lower)
        if score < minscore:
            bu = upper
            bl = lower
            minscore = score

    for lpad in range(0, len(s)+1):
        upper = len(t) * '_' + s
        lower = (len(s) - lpad) * '_' + t + '_' * lpad
        score = hamming(upper, lower)
        if score < minscore:
            bu = upper
            bl = lower
            minscore = score

    zipped = zip(bu,bl)
    newin  = ''.join(i for i,o in zipped if i != '_' or o != '_')
    newout = ''.join(o for i,o in zipped if i != '_' or o != '_')
    return newin, newout

def main():
    """Invoke a simple CLI analyser."""
    argp = ArgumentParser()
    argp.add_argument('-v', '--verbose', default=False,
                      action="store_true", help="print verbosely")
    argp.add_argument('-i', '--input', metavar='INFILE',
                      dest='infile', help="read strings from INFILE")
    argp.add_argument('-o', '--output', metavar="OUTFILE",
                      dest="outfile", help="write strings to OUTFILE")
    argp.add_argument('-a', '--alignment', metavar="ALGO", default="hamming",
                      help="use ALGO to align")
    options = argp.parse_args()
    if options.verbose:
        if options.infile:
            print("Reading from", options.infile)
        else:
            print("Reading from <stdin>")
    if options.verbose:
        if options.outfile:
            print("Writing to", options.outfile)
        else:
            pass
    if options.infile:
        inf = open(options.infile)
    else:
        inf = stdin
    if options.outfile:
        outf = open(options.outfile, "w")
    else:
        outf = stdout
    lines = 0
    for inline in inf:
        fields = inline.strip().split("\t")
        lemma = fields[0]
        surf = fields[1]
        msd = fields[2]
        padlemma, padsurf = halign(lemma, surf)
        if len(padlemma) < len(padsurf):
            padlemma += '_' * (len(padsurf) - len(padlemma))
        for needle, repl in [('_', '@0@'), (':', '\\:')]:
            padlemma = padlemma.replace(needle, repl)
            padsurf = padsurf.replace(needle, repl)
        print(padlemma, ";", msd, ':', surf, sep='', file=outf)
        lines += 1
        if lines % 1000 == 0 and options.verbose:
            print(lines, "...")
    if options.verbose:
        print("done!")
    exit(0)


if __name__ == "__main__":
    main()
