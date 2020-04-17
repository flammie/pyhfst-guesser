#!/bin/bash
CLOBBER=false
if test $# -lt 2 -o $# -gt 3; then
    echo "Usage: $0 TYPO LANGCODE [train|dev|test]"
    echo
    echo Downloads sigmorphon 2020 0 training data if not available, and
    echo compiles an FSA
    echo TYPO is the language family
    echo LANGCODE is the language code used in filename, i.e. ISO-639 code,
    echo e.g. fi
    echo train is default data to compile, you could also use dev or test?
    exit 1
fi

if ! test -d task0-data ; then
    git clone git@github.com:sigmorphon2020/task0-data.git
fi
TYPO=$1
LANGCODE=$2
SET=trn
if test x$3 = xdev ; then
    SET=dev
fi
INFILE=task0-data/$TYPO/$LANGCODE.$SET
OUTFILE=models/$TYPO/$LANGCODE.$SET
if ! test -f $INFILE ; then
    echo could not fetch or find $INFILE
    exit 2
fi
if ! test -d models ; then
    mkdir -v models
fi
if ! test -d models/$TYPO ; then
    mkdir -v models/$TYPO
fi
dos2unix $INFILE # SERIOUSLY?=!"#@
if test -f $OUTFILE.strings && ! $CLOBBER  ; then
    echo $OUTFILE.strings exists, rm or set CLOBBER to remake
else
    python3 unimorph2hfst.py -i $INFILE -o $OUTFILE.strings -v
    python3 unimorph2hfst.py --prefixing -i $INFILE -o $OUTFILE.pfx.strings -v
fi
if test -f $OUTFILE.hfst && ! $CLOBBER  ; then
    echo $OUTFILE.hfst exists, rm or set CLOBBER to remake
else
    hfst-strings2fst -m unimorph.sym -j -i $OUTFILE.strings -v |\
        hfst-minimize -o $OUTFILE.hfst -v
    hfst-invert -v -i $OUTFILE.hfst |\
        hfst-minimize -v -o $OUTFILE.inv.hfst
    hfst-fst2fst -f olw -v -i $OUTFILE.hfst -o ${OUTFILE}.hfstol
    hfst-fst2fst -f olw -v -i $OUTFILE.inv.hfst -o ${OUTFILE}.inv.hfstol
    hfst-strings2fst -m unimorph.pfx.sym -j -i $OUTFILE.pfx.strings -v |\
        hfst-minimize -o $OUTFILE.pfx.hfst -v
    hfst-invert -v -i $OUTFILE.pfx.hfst |\
        hfst-minimize -v -o $OUTFILE.pfx.inv.hfst
    hfst-fst2fst -f olw -v -i $OUTFILE.pfx.hfst -o ${OUTFILE}.pfx.hfstol
    hfst-fst2fst -f olw -v -i $OUTFILE.pfx.inv.hfst -o ${OUTFILE}.pfx.inv.hfstol
fi
if test -f $OUTFILE+prefix.hfst && ! $CLOBBER  ; then
    echo $OUTFILE+prefix.hfst exists, rm or set CLOBBER to remake
else
    python3 pyhguessify.py -v -i $OUTFILE.hfst -o $OUTFILE+prefix.hfst --suffix
    hfst-reverse -v -i $OUTFILE+prefix.hfst | hfst-minimize -v | hfst-reverse -o $OUTFILE+prefix.min.hfst
    hfst-fst2fst -f olw -v -i $OUTFILE+prefix.min.hfst -o $OUTFILE+prefix.hfstol
    hfst-invert -v -i $OUTFILE+prefix.min.hfst -o  $OUTFILE+prefix.inv.hfst
    hfst-fst2fst -f olw -i $OUTFILE+prefix.inv.hfst -o $OUTFILE+prefix.inv.hfstol
    python3 pyhguessify.py -v -i $OUTFILE.pfx.hfst -o $OUTFILE+suffix.hfst --prefix
    hfst-minimize -v -i $OUTFILE+suffix.hfst -o $OUTFILE+suffix.min.hfst
    hfst-fst2fst -f olw -v -i $OUTFILE+suffix.min.hfst -o $OUTFILE+suffix.hfstol
    hfst-invert -v -i $OUTFILE+suffix.min.hfst -o  $OUTFILE+suffix.inv.hfst
    hfst-fst2fst -f olw -i $OUTFILE+suffix.inv.hfst -o $OUTFILE+suffix.inv.hfstol
fi
