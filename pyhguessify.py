#!/usr/bin/env python
# -*- coding: utf-8 -*-


"""
Turn unimorph automaton into naive guesser.
"""


from argparse import ArgumentParser
from sys import stdin

import hfst
import libhfst


#: magic number for penalty weights
PENALTY_ = 28021984


def load_analyser(filename):
    """Load an automaton from file.

    Args:
        filename:  containing single hfst automaton binary.

    Throws:
        FileNotFoundError if file is not found
    """
    try:
        his = hfst.HfstInputStream(filename)
        return his.read()
    except libhfst.NotTransducerStreamException:
        raise IOError(2, filename) from None


def make_guesser(fsa, prefix: bool, suffix: bool, substring: bool):
    """Make guesser from automaton."""
    guesser = hfst.BasicTransducer(fsa)
    if suffix:
        prefixloopstate = guesser.add_state()
        guesser.add_transition(prefixloopstate, prefixloopstate,
                               "@_IDENTITY_SYMBOL_@", "@_IDENTITY_SYMBOL_@",
                               PENALTY_)
        for state, arcs in enumerate(guesser):
            guesser.add_transition(prefixloopstate, state,
                                   "@_EPSILON_SYMBOL_@", "@_EPSILON_SYMBOL_@",
                                   PENALTY_)
    fsa = hfst.HfstTransducer(guesser)
    return fsa

def main():
    """Invoke a simple CLI analyser."""
    argp = ArgumentParser()
    argp.add_argument('-i', '--input', metavar='INFILE', required=True,
                      dest='infile', help="read analyser from INFILE")
    argp.add_argument('-o', '--output', metavar="OUTFILE", required=True,
                      dest="outfile", help="write guesser to OUTFILE")
    argp.add_argument('-p', '--prefix', default=False,
                      action="store_true", help="add PREFIX guesser loop")
    argp.add_argument('-s', '--suffix', default=False,
                      action="store_true", help="add SUFFIX guesser loop")
    argp.add_argument('-x', '--substring', default=False,
                      action="store_true", help="add SUBSTRING guesser loops")
    options = argp.parse_args()
    analyser = load_analyser(options.infile)
    guesser = make_guesser(analyser, options.prefix, options.suffix,
            options.substring)
    exit(0)


if __name__ == "__main__":
    main()
