export PATH := $(PWD)/bin:$(PATH)

APPLE_PLATFORMS_VEND := $(wildcard vendor/apple/*)
APPLE_DMG := $(wildcard vendor/apple/*/*)
APPLE_WORK := $(APPLE_DMG:vendor/%.dmg=work/%)
APPLE_LG := $(wildcard $(APPLE_WORK:%=%/*.lg))
APPLE_TMX_WORK := $(APPLE_LG:.lg=.tmx)
APPLE_TMX_DIST := $(APPLE_TMX_WORK:work/%=dist/%)

ANDROID_SDK_ZIP := vendor/android/android-%.zip
ANDROID_SDK_WORK := $(ANDROID_SDK_ZIP:vendor/%=work/%)
ANDROID_SDK_VERSION := 28
ANDROID_SDK := work/android/android-$(ANDROID_SDK_VERSION)
SRC_LANG := en
TRG_LANG := ja
PIPELINE := work/android/pipeline.pln
ANDROID_TMX_DIST := dist/android/android-$(ANDROID_SDK_VERSION)-$(SRC_LANG)-$(TRG_LANG).tmx

.PHONY: lg appleTmx androidSdk androidTmx clean

all: appleTmx androidTmx

clean:
	rm -rf work dist

dist/%: work/%
	mkdir -p $(@D)
	cp $^ $@

### Apple

lg: $(APPLE_WORK)

appleTmx: $(APPLE_TMX_DIST) | lg
	@if [ -z "$^" ]; then $(MAKE) appleTmx; fi

%.tmx: %.lg
	xsltproc -o $@ --stringparam srclang en res/lg2tmx.xsl $^

work/apple/%: vendor/apple/%.dmg
	mkdir -p $(@D)
	cd $(@D); undmg $(PWD)/$^ >/dev/null
	touch $@

### Android

$(ANDROID_SDK_WORK): $(ANDROID_SDK_ZIP)
	tmp=$$(mktemp -d); unzip $^ -d $$tmp; mkdir -p $(@D); mv $$tmp/* $@; rm -r $$tmp
	touch $@

.PRECIOUS: $(ANDROID_SDK_ZIP)
$(ANDROID_SDK_ZIP):
	mkdir -p $(@D)
	curl -o $@ $$(androidSdkUrl $*)

.INTERMEDIATE: $(PIPELINE)
$(PIPELINE): res/pipeline.pln
	cp $^ $@
	sed -e '/outputPath=.*/s|=.*$$|=$(ANDROID_TMX_DIST)|' \
		-i '' $@

androidSdk: $(ANDROID_SDK)

androidTmx: $(ANDROID_TMX_DIST)

# This handling of sr-Latn is a hack, but it's the only BCP 47 tag in the SDK as
# of SDK 28
androidLocale = $(if $(filter en,$1),, \
	$(if $(filter sr-Latn,$1),b+sr+Latn,$(subst -,-r,$1)))

valuedir = $(if $(call androidLocale,$1),values-$1,values)

$(ANDROID_TMX_DIST): $(ANDROID_SDK) $(PIPELINE)
	rainbow -sl $(SRC_LANG) -tl $(TRG_LANG) \
		-se utf-8 -te -utf-8 \
		-pln $(lastword $^) \
		-np \
		$</data/res/$(call valuedir,$(SRC_LANG))/strings.xml -fc okf_xml-AndroidStrings \
		$</data/res/$(call valuedir,$(TRG_LANG))/strings.xml -fc okf_xml-AndroidStrings
