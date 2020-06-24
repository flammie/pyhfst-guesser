#!/bin/bash
CLOBBER=false
if test $# -ne 1 ; then
    echo "Usage: $0 LANGCODE(s)"
    echo
    echo Downloads apertium language data and
    echo compiles an FSA
    echo LANGCODE is the language code used in apertium github,
    echo e.g. fin
    exit 1
fi

LANGCODE=$1
if ! test -d ape-data ; then
    mkdir -v ape-data
fi
if ! test -d ape-data/apertium-$LANGCODE ; then
    pushd ape-data
    git clone git@github.com:apertium/apertium-$LANGCODE.git
    popd
fi
if ! test -d models ; then
    mkdir -v models
fi
if ! test -d models/apertium-$LANGCODE ; then
    mkdir -v models/apertium-$LANGCODE
fi
if ! test -f ape-data/apertium-$LANGCODE/$LANGCODE.hfst ; then
    echo remaking ape-data/apertium-$LANGCODE/$LANGCODE.hfst
    pushd ape-data/apertium-$LANGCODE
    autoreconf -fi
    ./configure
    if ! make $LANGCODE.autogen.hfst ; then
        if ! make $LANGCODE.autogen.att.gz ; then
            echo cannot make $LANGCODE.autogen...
            exit 2
        else
            zcat $LANGCODE.autogen.att.gz |\
                sed -e 's/	 /	@_SPACE_@/g' |\
                hfst-txt2fst -v -f openfst -o $LANGCODE.autogen.hfst --epsilon ε
            hfst-split -v $LANGCODE.autogen.hfst
            cp -v 1.hfst $LANGCODE.joined.hfst
            for i in $(seq 2 100); do
                if test -f $i.hfst ; then
                    hfst-union -v $LANGCODE.joined.hfst $i.hfst |\
                        hfst-minimize -v -o $LANGCODE.joined.hfst.tmp
                    mv -v $LANGCODE.joined.hfst.tmp $LANGCODE.joined.hfst
                else
                    break
                fi
            done
            cp -v $LANGCODE.joined.hfst $LANGCODE.autogen.hfst
        fi
    fi
    popd
fi
OUTFILE=models/apertium-$LANGCODE/$LANGCODE
if test -f $OUTFILE.automorf.hfst && ! $CLOBBER ; then
    echo $OUTFILE.automorf.hfst exists, rm or set CLOBBER to remake
else
    hfst-fst2fst -f openfst -v \
        -i ape-data/apertium-$LANGCODE/$LANGCODE.autogen.hfst \
        -o $OUTFILE.autogen.hfst
    hfst-fst2fst -f olw -v -i $OUTFILE.autogen.hfst -o ${OUTFILE}.autogen.hfstol
    hfst-invert -v -i $OUTFILE.autogen.hfst -o ${OUTFILE}.automorf.hfst
    hfst-fst2fst -f olw -v -i $OUTFILE.automorf.hfst \
        -o ${OUTFILE}.automorf.hfstol
fi
if test -f $OUTFILE.autoguess.hfst && ! $CLOBBER  ; then
    echo $OUTFILE+prefix.hfst exists, rm or set CLOBBER to remake
else
    python3 pyhguessify.py -v -i $OUTFILE.autogen.hfst \
        -o $OUTFILE.autoguess.inv.hfst --suffix
    hfst-reverse -v -i $OUTFILE.autoguess.inv.hfst | hfst-minimize -v |\
        hfst-reverse -o $OUTFILE.autoguess.inv.min.hfst
    hfst-fst2fst -f olw -v -i $OUTFILE.autoguess.inv.min.hfst \
        -o $OUTFILE.autoguess.inv.min.hfstol
    hfst-invert -v -i $OUTFILE.autoguess.inv.min.hfst -o  $OUTFILE.autoguess.hfst
    hfst-fst2fst -f olw -i $OUTFILE.autoguess.hfst -o $OUTFILE.autoguess.hfstol
fi
