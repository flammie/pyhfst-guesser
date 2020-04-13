#!/bin/bash
if ! test -d task0-data; then
    git clone git@github.com:sigmorphon2020/task0-data.git
fi
echo building all
t=austronesian
for l in ceb mao mlg tgl hil ; do
    bash make-sigmorphon0-fsa.bash $t $l
done
t=germanic
for l in ang      dan  deu  frr    gmh	 isl  nob   swe eng nld ; do
    bash make-sigmorphon0-fsa.bash $t $l
done
t=oto-manguean
for l in azg cly cpa ctp czn ote otm pei xty zpv ; do
    bash make-sigmorphon0-fsa.bash $t $l
done
t=niger-congo
for l in aka gaa  kon lin lug nya sot swa zul ; do
    bash make-sigmorphon0-fsa.bash $t $l
done
t=uralic
for l in est fin izh krl liv mdf mhr myv sme vep vot ; do
    bash make-sigmorphon0-fsa.bash $t $l
done
echo testing all
t=austronesian
for l in ceb mao mlg tgl hil ; do
    bash evaluate-guesser.bash models/$t/$l.trn+prefix.inv.hfstol $t $l
done
t=germanic
for l in ang      dan  deu  frr    gmh	 isl  nob   swe eng nld ; do
    bash evaluate-guesser.bash models/$t/$l.trn+prefix.inv.hfstol $t $l
done
t=oto-manguean
for l in azg cly cpa ctp czn ote otm pei xty zpv ; do
    bash evaluate-guesser.bash models/$t/$l.trn+prefix.inv.hfstol $t $l
done
t=niger-congo
for l in aka gaa  kon lin lug nya sot swa zul ; do
    bash evaluate-guesser.bash models/$t/$l.trn+prefix.inv.hfstol $t $l
done
t=uralic
for l in est fin izh krl liv mdf mhr myv sme vep vot ; do
    bash evaluate-guesser.bash models/$t/$l.trn+prefix.inv.hfstol $t $l
done

