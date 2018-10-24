export PATH := $(PWD)/bin:$(PATH)

APPLE_PLATFORMS_VEND := $(wildcard vendor/apple/*)
APPLE_DMG := $(wildcard vendor/apple/*/*)
APPLE_WORK := $(APPLE_DMG:vendor/%.dmg=work/%)
APPLE_LG := $(wildcard $(APPLE_WORK:%=%/*.lg))
APPLE_TMX_WORK := $(APPLE_LG:.lg=.tmx)
APPLE_TMX_DIST := $(APPLE_TMX_WORK:work/%=dist/%)


.PHONY: lg appleTmx clean

clean:
	rm -rf work dist

dist/%: work/%
	mkdir -p $(@D)
	cp $^ $@

lg: $(APPLE_WORK)

appleTmx: $(APPLE_TMX_DIST) | lg
	@if [ -z "$^" ]; then $(MAKE) appleTmx; fi

%.tmx: %.lg
	xsltproc -o $@ --stringparam srclang en res/lg2tmx.xsl $^

work/apple/%: vendor/apple/%.dmg
	mkdir -p $(@D)
	cd $(@D); undmg $(PWD)/$^ >/dev/null
	touch $@
