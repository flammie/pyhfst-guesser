# pyhfst-guesser

A quick and dirty / hacky python port of my hfst-guessifyers (you can find
c++ originals in [HFST](https://github.com/hfst/hfst/) )

## Requirements

* python 3
* [HFST](https://github.com/hfst/hfst/) and its python bindings.

If you are not confident in installing software from source etc., there's some
[instructions in apertium
 wiki](https://wiki.apertium.org/wiki/Install_Apertium_core_using_packaging).

## Usage

Python script `pyhfst-guessify.py` reads a HFST binary and adds some guesser
loops to it and writes a very non-deterministic weightd guesser. It has some
options but at the moment mainly the longest common suffix guesses work the best
`--suffix`. E.g.:

```
pyhguessify.py -i qzb.autogen.hfst -o qzb.autoguess.inv.hfst
```

You should try to minimise the result and store it in hfst optimised format for
faster processing, however, minimising may take up to few hours (on a raspberry
pi 4) depending on the analyser. *Not all guessers minimise in reasonable time.*

```
hfst-minimize qzb.autoguess.hfst | hfst-fst2fst -f olw -o qzb.autoguess.hfstol
```

The automaton works like normal analyser:

```
echo xxx | hfst-lookup qzb.autoguess.hfstol
```

There are some convenience scripts for compiling unimorph lexicons (i.e.
SIGMORPHON shared task data) and apertium analysers in the repo:

```
make-ape-guesser.bash qzb
make-sigmorphon-guesser.bash uralic fin train
```

These will download dictionaries and compile them, and build some guessers.


