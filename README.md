# easydb-custom-data-type-georef

This is a plugin for [easyDB 5](http://5.easydb.de/) with Custom Data Type `CustomDataTypeGeoref` for referencing to geoJSON-Objects. See [http://geojson.org/](http://geojson.org/) and https://de.wikipedia.org/wiki/GeoJSON

The Plugins uses the [Mapbox-API](https://www.mapbox.com/api-documentation/) for the Map-Rendering and magic. You can set Polygons, Linestrings and Points on the worldmap. This is saved in geojson-Format.

## configuration

As defined in `CustomDataTypeGeoref.config.yml` this datatype can be configured:

### Schema options

* which "mapquest-API-key" to use

### Mask options

* none

## saved data

* conceptName
    * type of geoFeature (polygon, point, line)
* conceptURI
    * information in geoJSON-standard-format
* _fulltext
    * easydb-fulltext
* _standard
    * easydb-standard

## sources

The source code of this plugin is managed in a git repository at <https://github.com/programmfabrik/easydb-custom-data-type-georef>. Please use [the issue tracker](https://github.com/programmfabrik/easydb-custom-data-type-georef/issues) for bug reports and feature requests!

