> This Plugin / Repo is being maintained by a community of developers.
There is no warranty given or bug fixing guarantee; especially not by
Programmfabrik GmbH. Please use the github issue tracking to report bugs
and self organize bug fixing. Feel free to directly contact the committing
developers.

# easydb-custom-data-type-georef

This is a plugin for [easyDB 5](http://5.easydb.de/) with Custom Data Type `CustomDataTypeGeoref` for referencing to geoJSON-Objects. See [http://geojson.org/](http://geojson.org/) and https://de.wikipedia.org/wiki/GeoJSON

The Plugins uses the [Mapbox-API](https://www.mapbox.com/api-documentation/) for the Map-Rendering and magic. You can set Polygons, Linestrings and Points on the worldmap. This is saved in geojson-Format.

## Installation

This plugin is activated by adding it to the plugins section of the extension block in your `easydb-server.yml`:
```yaml
extension:
  plugins:
    - name: custom-data-type-georef
      file: plugin/easydb-custom-data-type-georef/CustomDataTypeGeoref.config.yml
```

And then it ha to be enabled:
```yaml
plugins:
  enabled+:
    - base.easydb4migration
    - extension.custom-data-type-georef
  enabled-:
    - base.custom-data-type-georef
```
Note the entry below `enabled-`. 
This has to be present if the custom data type conflicts with the default georeference type. 
This is the case if your container exits with:

```bash
[b33358a7][2021-04-19T10:57:10.644677][   105][   ERROR][      pf.server.main] exception: {
    "realm": "server",
    "code": "error.server.generic",
    "parameters": {},
    "description": "Conflict loading plugins"
}
```

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

