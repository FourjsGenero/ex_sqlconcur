FORMS=\
 sqlconcur.42f

PROGMOD=\
 sqlconcur.42m

all: $(PROGMOD) $(FORMS)

%.42f: %.per
	fglform -M $<

%.42m: %.4gl
	fglcomp -M $<

run:: all
	fglrun sqlconcur.42m

clean::
	rm -f *.42?
