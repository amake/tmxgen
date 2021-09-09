export PATH := $(PWD)/bin:$(PATH)

SRC_LANG := en
TRG_LANG := ja
LANGUAGES := $(SRC_LANG) $(TRG_LANG)

APPLE_PLATFORMS_VEND := $(wildcard vendor/apple/*)
APPLE_DMG := $(wildcard vendor/apple/*/*)
APPLE_WORK := $(APPLE_DMG:vendor/%.dmg=work/%)
APPLE_LG := $(wildcard $(APPLE_WORK:%=%/*.lg))
APPLE_TMX_WORK := $(APPLE_LG:.lg=.tmx)
APPLE_TMX_DIST := $(APPLE_TMX_WORK:work/%=dist/%)

ANDROID_SDK_ZIP := vendor/android/android-%.zip
ANDROID_SDK_WORK := $(ANDROID_SDK_ZIP:vendor/%.zip=work/%)
ANDROID_SDK_VERSION := 28
ANDROID_SDK := work/android/android-$(ANDROID_SDK_VERSION)
ANDROID_PIPELINE := work/android/pipeline.pln
ANDROID_TMX_DIST := dist/android/android-$(ANDROID_SDK_VERSION)-$(SRC_LANG)-$(TRG_LANG).tmx

CLDR_BASE_URL := https://unicode.org/repos/cldr/trunk/common/main
CLDR_PIPELINE := work/unicode/pipeline.pln
CLDR_XML := $(LANGUAGES:%=vendor/unicode/%.xml)
CLDR_TMX_DIST := dist/unicode/cldr-$(SRC_LANG)-$(TRG_LANG).tmx

.PHONY: all
all: ## Generate Apple, Android, and CLDR TMX files
all: appleTmx androidTmx cldrTmx

.PHONY: clean
clean: ## Remove working files
clean:
	rm -rf work dist

dist/%: work/%
	mkdir -p $(@D)
	cp $^ $@

### Apple

.PHONY: lg
lg: $(APPLE_WORK)

.PHONY: appleTmx
appleTmx: ## Generate Apple TMX files
appleTmx: $(APPLE_TMX_DIST) | lg
	@if [ -z "$^" ] && [ ! -z "$(APPLE_DMG)" ]; then $(MAKE) appleTmx; fi

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

.INTERMEDIATE: $(ANDROID_PIPELINE)
$(ANDROID_PIPELINE): res/IdAlignUnquote.pln
	mkdir -p $(@D)
	cp $^ $@
	sed -e '/outputPath=.*/s|=.*$$|=$(ANDROID_TMX_DIST)|' \
		-i '' $@

.PHONY: androidSdk
androidSdk: $(ANDROID_SDK)

.PHONY: androidTmx
androidTmx: ## Generate Android TMX files
androidTmx: $(ANDROID_TMX_DIST)

# This handling of sr-Latn is a hack, but it's the only BCP 47 tag in the SDK as
# of SDK 28
androidLocale = $(if $(filter en,$1),, \
	$(if $(filter sr-Latn,$1),b+sr+Latn,$(subst -,-r,$1)))

valuedir = $(if $(call androidLocale,$1),values-$1,values)

$(ANDROID_TMX_DIST): $(ANDROID_SDK) $(ANDROID_PIPELINE)
	rainbow -sl $(SRC_LANG) -tl $(TRG_LANG) \
		-se utf-8 -te -utf-8 \
		-pln $(lastword $^) \
		-np \
		$</data/res/$(call valuedir,$(SRC_LANG))/strings.xml -fc okf_xml-AndroidStrings \
		$</data/res/$(call valuedir,$(TRG_LANG))/strings.xml -fc okf_xml-AndroidStrings

### CLDR

.INTERMEDIATE: $(CLDR_PIPELINE)
$(CLDR_PIPELINE): res/IdAlign.pln
	mkdir -p $(@D)
	cp $^ $@
	sed -e '/tmxOutputPath=.*/s|=.*$$|=$(CLDR_TMX_DIST)|' \
		-i '' $@

vendor/unicode/%:
	mkdir -p $(@D)
	curl -o $@ $(CLDR_BASE_URL)/$*

.PHONY: cldrXml
cldrXml: $(CLDR_XML)

.PHONY: cldrTmx
cldrTmx: ## Generate CLDR TMX files
cldrTmx: $(CLDR_TMX_DIST)

$(CLDR_TMX_DIST): $(CLDR_XML) $(CLDR_PIPELINE)
	rainbow -sl $(SRC_LANG) -tl $(TRG_LANG) \
		-se utf-8 -te -utf-8 \
		-pln $(lastword $^) \
		-pd $(PWD)/res \
		-np \
		$(word 1,$^) -fc okf_xml@cldr \
		$(word 2,$^) -fc okf_xml@cldr

.PHONY: help
help: ## Show this help text
	$(info usage: make [target])
	$(info )
	$(info Available targets:)
	@awk -F ':.*?## *' '/^[^\t].+?:.*?##/ \
         {printf "  %-24s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
