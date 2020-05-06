#!/usr/bin/env python
# -*- coding: utf-8 -*-


"""
Turn unimorph automaton into naive guesser.
"""


from argparse import ArgumentParser
from sys import stdin
from math import log

import hfst
import libhfst


#: magic number for penalty weights
PENALTY_ = 28021984

def load_analyser(filename: str):
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

def save_analyser(fsa: hfst.HfstTransducer, filename: str):
    """Save an automaton into a file.

    Args:
        filename:  containing single hfst automaton binary.

    Throws:
        FileNotFoundError if file is not found
    """
    try:
        hos = hfst.HfstOutputStream(filename=filename)
        hos.write(fsa)
        hos.close()
    except libhfst.NotTransducerStreamException:
        raise IOError(2, filename) from None


def count_sigma_weight_map(fsa: hfst.HfstBasicTransducer):
    sigmacounts = dict()
    total = 0
    for state, arcs in enumerate(fsa):
        for arc in arcs:
            s = arc.get_output_symbol()
            if s not in sigmacounts:
                sigmacounts[s] = 0
            sigmacounts[s] += 1
            total += 1
    sigmaw = dict()
    for sigma, count in sigmacounts.items():
        # sigmaw[sigma] = -log(count / total)
        sigmaw[sigma] = 1
    return sigmaw


def make_suffix_guesser(fsa: hfst.HfstBasicTransducer, verbose: bool):
    # no way to make new start state so hackhack...
    sigmaw = count_sigma_weight_map(fsa)
    if verbose:
        print("making prefix sigma star...", end=" ")
    prefixloop = hfst.HfstBasicTransducer()
    prefixloopstate = 0
    prefixloop.add_transition(prefixloopstate, prefixloopstate,
                           "@_IDENTITY_SYMBOL_@", "@_IDENTITY_SYMBOL_@",
                           PENALTY_)
    for symbol, weight in sigmaw.items():
        prefixloop.add_transition(prefixloopstate, prefixloopstate,
                                  symbol, symbol, weight)
    if verbose:
        print("replicating...", end=" ")
    for state, arcs in enumerate(fsa):
        prefixloop.add_state(state + 1)
        if fsa.is_final_state(state):
            prefixloop.set_final_weight(state + 1,
                                        fsa.get_final_weight(state))
    for state, arcs in enumerate(fsa):
        prefixloop.add_transition(prefixloopstate, state + 1,
                               "@_EPSILON_SYMBOL_@", "@_EPSILON_SYMBOL_@",
                               0)
        for arc in arcs:
            prefixloop.add_transition(state + 1, arc.get_target_state() + 1,
                                      arc.get_input_symbol(),
                                      arc.get_output_symbol(),
                                      arc.get_weight())
    return prefixloop


def make_prefix_guesser(fsa: hfst.HfstBasicTransducer, verbose: bool):
    sigmaw = count_sigma_weight_map(fsa)
    suffixloop = hfst.HfstBasicTransducer(fsa)
    suffixloopstate = suffixloop.add_state()
    suffixloop.set_final_weight(suffixloopstate, 0)
    suffixloop.add_transition(suffixloopstate, suffixloopstate,
                           "@_IDENTITY_SYMBOL_@", "@_IDENTITY_SYMBOL_@",
                           PENALTY_)
    for symbol, weight in sigmaw.items():
        suffixloop.add_transition(suffixloopstate, suffixloopstate,
                                  symbol, symbol, weight)
    if verbose:
        print("connecting...", end=" ")
    for state, arcs in enumerate(suffixloop):
        suffixloop.add_transition(state, suffixloopstate,
                               "@_EPSILON_SYMBOL_@", "@_EPSILON_SYMBOL_@",
                               0)
    return suffixloop


def make_substring_guesser(fsa: hfst.HfstTransducer, verbose: bool):
    # an infix guesser in a way
    sigmaw = count_sigma_weight_map(fsa)
    substringer = hfst.HfstBasicTransducer(fsa)
    if verbose:
        print("adding loops...", end=" ")
    for state, arcs in enumerate(substringer):
        substringer.add_transition(state, state,
                               "@_IDENTITY_SYMBOL_@", "@_IDENTITY_SYMBOL_@",
                               PENALTY_)
        for symbol, weight in sigmaw.items():
            substringer.add_transition(state, state,
                                       symbol, symbol, weight)
    return substringer


def make_guesser(fsa: hfst.HfstTransducer, prefix: bool, suffix: bool,
        substring: bool, verbose: bool):
    """Make guesser from automaton."""
    if verbose:
        print("Converting...", end=" ")
    guesser = hfst.HfstBasicTransducer(fsa)
    if suffix:
        prefixloop = make_suffix_guesser(guesser, verbose)
        guesser = prefixloop
    elif prefix:
        suffixloop = make_prefix_guesser(guesser, verbose)
        guesser = suffixloop
    # substring guesser can combine with affix guesser
    if substring:
        substringer = make_substring_guesser(guesser, verbose)
        guesser = substringer
    if verbose:
        print("Converting...", end=" ")
    fsa = hfst.HfstTransducer(guesser)
    if verbose:
        print("done!")
    return fsa

def main():
    """Invoke a simple CLI analyser."""
    argp = ArgumentParser()
    argp.add_argument('-v', '--verbose', default=False,
                      action="store_true", help="print verbosely")
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
    if options.verbose:
        print("Loading analyser", options.infile, "...", end=" ")
    analyser = load_analyser(options.infile)
    if options.verbose:
        print("done!")
        print("Building guesser...")
    if not options.prefix and not options.suffix and not options.substring:
        print("at least one of --prefix, --suffix  or --substring must be")
        exit(1)
    guesser = make_guesser(analyser, options.prefix, options.suffix,
            options.substring, options.verbose)
    if options.verbose:
        print("done!")
        print("Writing guesser", options.outfile, "...", end=" ")
    save_analyser(guesser, options.outfile)
    if options.verbose:
        print("done!")
    exit(0)


if __name__ == "__main__":
    main()
