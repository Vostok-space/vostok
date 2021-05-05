
ost:
	./init.sh > /dev/null
	result/bs-ost run make.Build -infr . -m source
	result/ost to-bin Translator.Go result/ost -infr . -m source -cc "cc -O1 -flto -s"
	result/ost run 'make.Test; make.Self' -infr . -m source

install:
	mkdir -p $(DESTDIR)/usr/bin/ $(DESTDIR)/usr/share/vostok
	cp result/ost $(DESTDIR)/usr/bin/
	cp -r library singularity $(DESTDIR)/usr/share/vostok/

.PHONY: install ost
