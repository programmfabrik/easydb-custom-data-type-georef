> This Plugin / Repo is being maintained by a community of developers.
There is no warranty given or bug fixing guarantee; especially not by
Programmfabrik GmbH. Please use the github issue tracking to report bugs
and self organize bug fixing. Feel free to directly contact the committing
developers.

# easydb-custom-data-type-georef

This is a plugin for [easyDB 5](http://5.easydb.de/) with Custom Data Type `CustomDataTypeGeoref` for referencing to geoJSON-Objects. See [http://geojson.org/](http://geojson.org/) and https://de.wikipedia.org/wiki/GeoJSON

The Plugins uses the [Mapbox-API](https://www.mapbox.com/api-documentation/) for the Map-Rendering and magic. You can set Polygons, Linestrings and Points on the worldmap. This is saved in geojson-Format.

## configuration

As defined in `CustomDataTypeGeoref.config.yml` this datatype can be configured:

### Schema options

* which "mapbpox-API-key" to use
* if "geocoder" is activated for adresssearch
* allow to add POINT via text?
* allow to add LINESTRING via text?
* allow to add POLYGON via text?

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
