PLUGIN_NAME = custom-data-type-georef

L10N_FILES = easydb-library/src/commons.l10n.csv \
    l10n/$(PLUGIN_NAME).csv
L10N_GOOGLE_KEY = 1ux8r_kpskdAwTaTjqrk92up5eyyILkpsv4k96QltmI0
L10N_GOOGLE_GID = 1569075372

INSTALL_FILES = \
	$(WEB)/l10n/cultures.json \
	$(WEB)/l10n/de-DE.json \
	$(WEB)/l10n/en-US.json \
	$(JS) \
	$(CSS) \
	CustomDataTypeGeoref.config.yml

COFFEE_FILES = easydb-library/src/commons.coffee \
	src/webfrontend/CustomDataTypeGeoref.coffee

MAPBOX1 = src/external/mapbox-gl.js
MAPBOX2 = src/external/mapbox-gl-draw.js
MAPBOX3 = src/external/geojson-extent.js
MAPBOX4 = src/external/geo-viewport.js

CSSGLDRAW = src/external/mapbox_gl_draw.css
CSSADDITIONAL = src/external/mapbox.css
CSS_FILE = src/webfrontend/css/main.css

all: build

include easydb-library/tools/base-plugins.make

build: code morecss

code: $(subst .coffee,.coffee.js,${COFFEE_FILES}) $(L10N)
	mkdir -p build
	mkdir -p build/webfrontend
	cat $^ > build/webfrontend/custom-data-type-georef.js
	cat $(MAPBOX1) $(MAPBOX2) $(MAPBOX3) $(MAPBOX4) >> build/webfrontend/custom-data-type-georef.js

morecss:
	cat $(CSS_FILE) >> build/webfrontend/custom-data-type-georef.css
	cat $(CSSGLDRAW) >> build/webfrontend/custom-data-type-georef.css
	cat $(CSSADDITIONAL) >> build/webfrontend/custom-data-type-georef.css

clean: clean-base
