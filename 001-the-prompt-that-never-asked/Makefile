SHELL := /bin/bash

.PHONY: setup run verify teardown crash

setup:            ## build the disposable fixture repo the reaper is allowed to touch
	./scripts/make-fixture.sh fixture

run: 	          ## dry-run sweep of the fixture (the default, safe path)
	./reaper fixture

verify:           ## full test suite, including the headless regression tests
	./test/verify.sh

teardown:         ## remove everything the lab created (all of it lives in this directory)
	rm -rf fixture state .testtmp

crash:            ## reproduce the episode's bug: buggy probe, headless, strict mode on
	@echo "running the buggy probe headless — expect a raw 'unbound variable' crash:"
	-REAPER_BUGGY_TTY_PROBE=1 setsid --wait ./reaper fixture --apply </dev/null
	@echo "(nothing was deleted — run 'git -C fixture branch' to check)"
