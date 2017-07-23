
all: man/man1/*.1.gz

man/man1/%.1.gz: bin/%
	$* --help | gzip -c >$>
