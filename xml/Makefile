# $Id: Makefile,v 1.12 2004/03/30 03:09:24 babayoshihiko Exp $

# process XML files with stylesheet to produce HTML

basedir = ..

SOURCE = test.xml
TARGET = test.php test-test.php
WANT_TEXT = 1
WANT_HTML = 1
DESTDIR = doc/test

include $(basedir)/Makefile.common


%.txt.tmp: %.xml $(STYLESHEET_TEXT) $(basedir)/finkdoc.dtd
	xmllint --noout --valid $(SOURCE) && \
	xsltproc -o $(patsubst %.xml,%.txt.tmp,$(SOURCE)) $(STYLESHEET_TEXT) $(SOURCE)

%.txt: %.txt.tmp $(PROCESS_TEXT)
	$(PROCESS_TEXT) <$< >$@

# eof
