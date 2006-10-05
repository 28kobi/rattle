# TARGETS
#
# check:	As R to check that the package looks okay
# html:		Build the HTML documents and view in a browser
# local:	Build and install in the local machine's R archive
# install:	Build and copy the package across to the public www
# access:	Have a look at who might be downloading rattle

PACKAGE=package/rattle
DESCRIPTION=$(PACKAGE)/DESCRIPTION
DESCRIPTIN=support/DESCRIPTION.in
NAMESPACE=$(PACKAGE)/NAMESPACE

REPOSITORY=repository

# Canonical version information from rattle.R
MAJOR:=$(shell egrep '^MAJOR' src/rattle.R | cut -d\" -f 2)
MINOR:=$(shell egrep '^MINOR' src/rattle.R | cut -d\" -f 2)
REVISION:=$(shell svn info | egrep 'Revision:' |  cut -d" " -f 2)
#REVISION:=$(shell egrep '^REVISION' src/rattle.R | cut -d" "  -f 4)
VERSION=$(MAJOR).$(MINOR).$(REVISION)
DATE:=$(shell date +%F)

install: build zip check
	cp src/rattle.R src/rattle.glade /var/www/access/
	chmod go+r /var/www/access/rattle*
	mv rattle_$(VERSION).tar.gz rattle_$(VERSION).zip $(REPOSITORY)
	R --no-save < support/repository.R
	chmod go+r $(REPOSITORY)/*
	lftp -f .lftp

check: build
	R CMD check $(PACKAGE)

# For development, temporarily remove the NAMESPACE so all is exposed.

devbuild:
	mv package/rattle/NAMESPACE .
	cp rattle.R package/rattle/R/
	cp rattle.glade package/rattle/inst/etc/
	R CMD build package/rattle
	mv NAMESPACE package/rattle/

build: data rattle_$(VERSION).tar.gz

rattle_$(VERSION).tar.gz: 
	cp src/rattle.R package/rattle/R/
	cp src/rattle.glade package/rattle/inst/etc/
	perl -p -e "s|^Version: .*$$|Version: $(VERSION)|" < $(DESCRIPTIN) |\
	perl -p -e "s|^Date: .*$$|Date: $(DATE)|" > $(DESCRIPTION)
	(cd /home/gjw/projects/togaware/www/;\
	 perl -pi -e "s|rattle_[0-9\.]*zip|rattle_$(VERSION).zip|g" \
			rattle.html.in;\
	 perl -pi -e "s|rattle_[0-9\.]*tar.gz|rattle_$(VERSION).tar.gz|g" \
			rattle.html.in;\
	 make local; lftp -f .lftp-rattle)
	(cd /home/gjw/projects/dmsurvivor/;\
	 perl -pi -e "s|rattle_.*zip|rattle_$(VERSION).zip|g" \
			dmsurvivor.tex;\
	 perl -pi -e "s|rattle_.*tar.gz|rattle_$(VERSION).tar.gz|g" \
			dmsurvivor.tex)
	R CMD build $(PACKAGE)
	chmod -R go+rX $(PACKAGE)

data: package/rattle/data/audit.RData

package/rattle/data/audit.RData: support/audit.R
	R --no-save --quiet < support/audit.R
	mv audit.RData package/rattle/data/
	mv audit.csv package/rattle/inst/csv/audit.csv
	mv survey.data survey.csv archive
	chmod go+r $@

zip: local
	(cd /usr/local/lib/R/site-library; zip -r9 - rattle) >| \
	rattle_$(VERSION).zip

txt:
	R CMD Rd2txt package/rattle/man/rattle.Rd

html:
	for m in rattle evaluateRisk genPlotTitleCmd plotRisk; do\
	  R CMD Rdconv -t=html -o=$$m.html package/rattle/man/$$m.Rd;\
	  epiphany -n $$m.html;\
	  rm -f $$m.html;\
	done

local: rattle_$(VERSION).tar.gz
	R CMD INSTALL rattle_$(VERSION).tar.gz

access:
	grep 'rattle' /home/gjw/projects/ilisys/log

python:
	python rattle.py

test:
	R --no-save --quiet < regression.R 

clean:
	rm -f rattle_*.tar.gz rattle_*.zip
	rm -f package/rattle/R/rattle.R package/rattle/inst/etc/rattle.glade
	rm -f package/rattle/DESCRIPTION

realclean:
	rm -f package/rattle/data/audit.RData package/rattle/inst/csv/audit.csv
	rm -rf rattle.Rcheck