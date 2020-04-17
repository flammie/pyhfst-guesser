#!/bin/bash
CLOBBER=false
if test $# -lt 2 -o $# -gt 3; then
    echo "Usage: $0 GUESSER TYPO LANGCODE [train|dev|test]"
    echo
    echo Uses exising GUESSER to guess test stuff...
    echo TYPO is the language family
    echo LANGCODE is the language code used in filename, i.e. ISO-639 code,
    echo e.g. fin
    echo dev is the default for testing
    exit 1
fi

GUESSER=$1
TYPO=$2
LANGCODE=$3
SET=dev
if test x$4 = xtst ; then
    SET=tst
fi
INFILE=task0-data/$TYPO/$LANGCODE.$SET
OUTFILE=hyps/$TYPO/$LANGCODE.$SET.$(basename $GUESSER | sed -e 's/.hfstol//')
if ! test -f $GUESSER ; then
    echo could not find $GUESSER
    exit 2
fi
if ! test -f $INFILE ; then
    echo could not find $INFILE
    exit 2
fi
if ! test -d hyps ; then
    mkdir -v hyps
fi
if ! test -d hyps/$TYPO ; then
    mkdir -v hyps/$TYPO
fi

if ! test -f $OUTFILE.x || $CLOBBER ; then
    cut -f 2 $INFILE | hfst-lookup $GUESSER -n 1 -v -o $OUTFILE.x
else
    echo $OUTFILE.x exists, rm or set CLOBBER to remake
fi
case $GUESSER in
    *suffix*) cut -f  1,2 < $OUTFILE.x |\
    tr -s '\n' |\
    rev |\
    sed -e 's/;/\t/' |\
    rev |\
    awk -F "\t" --assign=OFS="\t" 'NF==2 {$3=$2;$2="X"} {s=$1; $1=$3; $3=$2;
        $2=s; print;}' |\
    sed -e 's/^	\([^	]*\)/\1	\1/' > $OUTFILE;;

    *prefix*) cut -f 1,2 < $OUTFILE.x |\
    tr -s '\n' |\
    sed -e 's/;/\t/' -e 's/+?/\t;N/' |\
    awk -F "\t" --assign=OFS="\t" 'NF==2 {$3="X";} {s=$1; $1=$2; $2=s; print;}' |\
    sed -e 's/^	\([^	]*\)/\1	\1/' > $OUTFILE;;
    *) cut -f 1,2 < $OUTFILE.x |\
    tr -s '\n' |\
    sed -e 's/;/\t/' -e 's/+?/\t;N/' |\
    awk -F "\t" --assign=OFS="\t" 'NF==2 {$3="X";} {s=$1; $1=$2; $2=s; print;}' |\
    sed -e 's/^	\([^	]*\)/\1	\1/' > $OUTFILE;;
esac
python3 task0-data/evaluate.py --hyp $OUTFILE --ref $INFILE | tee $OUTFILE.evals
