#!/bin/sh

DIST=`cat ~/bindist/current`

#~/bindist/cvsparse

if [ -f ~/bindist/$DIST-add.list ]; then
  for i in `cat ~/bindist/$DIST-add.list`; do
    ~/bindist/remove-nonbase.sh;
    echo building $i;
    fink build $i;
    echo adding $i;
    ~/bindist/bdadd $i;
  done
fi

~/bindist/bdmissing | xargs ~/bindist/bdadd
fink scanpackages;
cp /sw/fink/override ~/bindist/override;
~/bindist/bdsync;
~/bindist/bdscan;
~/bindist/bdsync;

if [ -f ~/bindist/$DIST-rebuild.list ]; then
  for i in `cat ~/bindist/$DIST-rebuild.list`; do
    ~/bindist/remove-nonbase.sh;
    echo building $i;
    ~/bindist/safefink build $i;
    echo rebuilding $i;
    fink rebuild $i;
    echo adding $i;
    ~/bindist/bdadd $i;
  done
fi

~/bindist/bdmissing | xargs ~/bindist/bdadd
fink scanpackages;
cp /sw/fink/override ~/bindist/override;
~/bindist/bdsync;
~/bindist/bdscan;
~/bindist/bdsync;

if [ -f ~/bindist/$DIST-remove.list ]; then
  for i in `cat ~/bindist/$DIST-remove.list`; do
    echo # FIX ME
  done
fi

~/bindist/bdmissing | xargs ~/bindist/bdadd
fink scanpackages
cp /sw/fink/override ~/bindist/override
~/bindist/bdsync
~/bindist/bdscan
~/bindist/bdsync
