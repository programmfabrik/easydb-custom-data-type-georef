turf = require('@turf/turf');

class GeorefUpdate

  __start_update: ({server_config, plugin_config}) ->
      ez5.respondSuccess({
        state: {
            "start_update": new Date().toUTCString()
        }
      })

  __updateData: ({objects, plugin_config}) ->
      that = @
      objectsToUpdate = []

      for georefJSON in objects
        georefFeature = JSON.parse georefJSON.data.conceptURI
        # rewind the polygon to right hand rule (geojson-spec 1.0)
        polygonCoords = georefFeature.geometry.coordinates
        if polygonCoords[0].length >= 5
          turfPolygon = turf.polygon(polygonCoords)
          rewind = turf.rewind(turfPolygon);
          georefFeature.geometry.coordinates = rewind.geometry.coordinates
          georefJSON.data.conceptURI = JSON.stringify(georefFeature)
          objectsToUpdate.push georefJSON
      ez5.respondSuccess({payload: objectsToUpdate})

  __hasChanges: (objectOne, objectTwo) ->
      for key in ["conceptName", "conceptURI", "_standard", "_fulltext"]
        if not CUI.util.isEqual(objectOne[key], objectTwo[key])
          return true
      return false

  main: (data) ->
      if not data
        ez5.respondError("custom.data.type.georef.update.error.payload-missing")
        return

      for key in ["action", "server_config", "plugin_config"]
        if (!data[key])
          ez5.respondError("custom.data.type.georef.update.error.payload-key-missing", {key: key})
          return

      if (data.action == "start_update")
        @__start_update(data)
        return

      else if (data.action == "update")
        if (!data.objects)
          ez5.respondError("custom.data.type.georef.update.error.objects-missing")
          return

        if (!(data.objects instanceof Array))
          ez5.respondError("custom.data.type.georef.update.error.objects-not-array")
          return

        # NOTE: state for all batches
        # this contains any arbitrary data the update script might need between batches
        # it should be sent to the server during 'start_update' and is included in each batch
        if (!data.state)
          ez5.respondError("custom.data.type.georef.update.error.state-missing")
          return

        # NOTE: information for this batch
        # this contains information about the current batch, espacially:
        #   - offset: start offset of this batch in the list of all collected values for this custom type
        #   - total: total number of all collected custom values for this custom type
        # it is included in each batch
        if (!data.batch_info)
          ez5.respondError("custom.data.type.georef.update.error.batch_info-missing")
          return

        # TODO: check validity of config, plugin (timeout), objects...
        @__updateData(data)
        return
      else
        ez5.respondError("custom.data.type.georef.update.error.invalid-action", {action: data.action})

module.exports = new GeorefUpdate()
