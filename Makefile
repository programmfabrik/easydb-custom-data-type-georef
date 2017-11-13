PLUGIN_NAME = custom-data-type-georef

L10N_FILES = l10n/$(PLUGIN_NAME).csv
L10N_GOOGLE_KEY = 1ux8r_kpskdAwTaTjqrk92up5eyyILkpsv4k96QltmI0
L10N_GOOGLE_GID = 1569075372
L10N2JSON = python easydb-library/tools/l10n2json.py

INSTALL_FILES = \
	$(WEB)/l10n/cultures.json \
	$(WEB)/l10n/de-DE.json \
	$(WEB)/l10n/en-US.json \
	$(WEB)/l10n/es-ES.json \
	$(WEB)/l10n/it-IT.json \
	$(JS) \
	CustomDataTypeGeoref.config.yml

COFFEE_FILES = easydb-library/src/commons.coffee \
	src/webfrontend/CustomDataTypeGeoref.coffee

MAPBOX1 = src/external/mapbox-gl.min.js
MAPBOX2 = src/external/mapbox-gl-draw.js
MAPBOX3 = src/external/geojson-extent.js
MAPBOX4 = src/external/geo-viewport.js

CSS = src/external/mapbox.css
CSSTARGET = build/webfrontend/mapbox.css

all: build

include easydb-library/tools/base-plugins.make

build: code $(L10N)

code: $(subst .coffee,.coffee.js,${COFFEE_FILES})
	mkdir -p build
	mkdir -p build/webfrontend
	touch build/webfrontend/mapbox.css
	cp -f $(CSS) $(CSSTARGET)
	cat $^ > build/webfrontend/custom-data-type-georef.js
	cat $(MAPBOX1) $(MAPBOX2) $(MAPBOX3) $(MAPBOX4) >> build/webfrontend/custom-data-type-georef.js

clean: clean-base

wipe: wipe-base

.PHONY: clean wipe


#
