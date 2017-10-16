Session::getCustomDataTypes = ->
  @getDefaults().server.custom_data_types or {}

class CustomDataTypeGeoref extends CustomDataTypeWithCommons

  #######################################################################
  # return name of plugin
  getCustomDataTypeName: ->
    "custom:base.custom-data-type-georef.georef"

  #######################################################################
  # return name (l10n) of plugin
  getCustomDataTypeNameLocalized: ->
    $$("custom.data.type.georef.name")


  #######################################################################
  # show popover and fill it with the form-elements
  showEditPopover: (btn, cdata, layout) ->

    cdata_form = new CUI.Form
      data: cdata
      fields: @__getEditorFields(cdata)
      onDataChanged: =>
        @__updateResult(cdata, layout)
        @__setEditorFieldStatus(cdata, layout)
    .start()

    xmapboxpane = new CUI.SimplePane
        class: "georef_mapbox_container"
        header_left:
            new CUI.Label
                text: "Satellit und Straßen"
        content:
            new CUI.Label
                text: ""

    @popover = new CUI.Popover
      element: btn
      fill_space: "both"
      placement: "c"
      pane:
        # titel of popovers
        header_left: new CUI.Label(text: "Freie Georeferenzierung auf Karte setzen (Georef)")
        # "save"-button
        footer_right: []
        footer_left: cdata_form

        # "reset"-button
        content: xmapboxpane
    .show()
    @__initMap(cdata, cdata_form)


  ##########################################################################
  # initialisiere Karte
  __initMap: (cdata, cdata_form) ->
    mapbox_access_token = ''
    if @getCustomSchemaSettings().mapbox_access_token?.value
      mapbox_access_token = @getCustomSchemaSettings().mapbox_access_token?.value
    else
      console.log "Kein Mapbox-Api-Key gegeben!"

    mapboxgl.accessToken = mapbox_access_token
    container = document.getElementsByClassName('georef_mapbox_container')[0]

    # remove all style + classes + content from container
    container.removeAttribute('class')
    container.removeAttribute('style')
    container.removeAttribute('id')
    container.className = 'georef_mapbox_container'
    container.innerHTML = ''

    map = new mapboxgl.Map({
        container: container
        style: 'mapbox://styles/mapbox/satellite-streets-v10'
        center: [9.935,51.5338]
        zoom: 5
    });

    # disable map rotation using right click + drag
    map.dragRotate.disable()

    # disable map rotation using touch rotation gesture
    map.touchZoomRotate.disableRotation()

    nav = new mapboxgl.NavigationControl()
    map.addControl(nav, 'top-left')

    draw = new MapboxDraw(
      displayControlsDefault: false
      controls:
        polygon: true
        point: true
        line_string: true
        trash: false)

    map.addControl(draw)

    map.dragPan.enable()

    data = draw.getAll()

    # if geojson-data exists yet
    if cdata.conceptURI != '' && cdata.conceptName != ''
      geoJSON = JSON.parse(cdata.conceptURI)
      map.on 'load', ->
        map.addSource 'Georeferenzierung',
          'type': 'geojson'
          'data': geoJSON
        # für Polygone
        if geoJSON.geometry.type == 'Polygon'
          map.addLayer
            'id': 'Georeferenzierung'
            'type': 'fill'
            'source': 'Georeferenzierung'
            'interactive': true
            'layout': {}
            'paint':
              'fill-color': '#C20000'
              'fill-opacity': 0.5
        # für Linien
        if geoJSON.geometry.type == 'LineString'
          map.addLayer
            'id': 'Georeferenzierung'
            'type': 'line'
            'source': 'Georeferenzierung'
            'interactive': true
            'layout':
              'line-join': 'round'
              'line-cap': 'round'
            'paint':
              'line-color': '#C20000'
              'line-width': 4
        # für Punkte
        if geoJSON.geometry.type == 'Point'
          map.addLayer
            'id': 'Georeferenzierung'
            'type': 'symbol'
            'source': 'Georeferenzierung'
            'interactive': true
            'layout':
              'icon-image': 'embassy-15'
              'text-field': ''
              'text-font': [
                'Open Sans Semibold'
                'Arial Unicode MS Bold'
              ]
              'text-offset': [
                0
                0.6
              ]
              'text-anchor': 'top'
        # get bounds of formlayer
        map.fitBounds geojsonExtent(geoJSON), padding: 20
        return

    # click on map
    map.on 'click', (e) ->
      data = draw.getAll()
      if data.features.length == 1
        geoJSON = data.features[0]
        delete geoJSON.id
        #delete geoJSON.properties
        #geoJSON.properties.stroke = '#C20000'
        #geoJSON.properties['stroke-opacity'] = 1.0
        #geoJSON.properties['stroke-width'] = 2
        type = data.features[0].geometry.type
        console.log "type:" + type
        if type == 'Point'
          if data.features[0].geometry.coordinates.length == 2
            geoJSON = JSON.stringify(geoJSON)
            coords = data.features[0].geometry.coordinates
            coords = coords.join(' ')
            # lock in save data
            cdata.conceptURI = geoJSON
            cdata.conceptName = 'Point'
            # lock in form
            cdata_form.getFieldsByName("conceptName")[0].storeValue(cdata.conceptName).displayValue()
            cdata_form.getFieldsByName("conceptURI")[0].storeValue(cdata.conceptURI).displayValue()

        if type == 'LineString'
          if data.features[0].geometry.coordinates.length >= 2
            geoJSON = JSON.stringify(geoJSON)
            line = data.features[0].geometry.coordinates
            linePoints = new Array
            for value in line
              linePoints.push value.join(' ')
            linePoints = linePoints.join(',')
            # lock in save data
            cdata.conceptURI = geoJSON
            cdata.conceptName = 'LineString'
            # lock in form
            cdata_form.getFieldsByName("conceptName")[0].storeValue(cdata.conceptName).displayValue()
            cdata_form.getFieldsByName("conceptURI")[0].storeValue(cdata.conceptURI).displayValue()

        if type == 'Polygon'
          if data.features[0].geometry.coordinates[0].length >= 3
            geoJSON = JSON.stringify(geoJSON)
            polygon = data.features[0].geometry.coordinates[0]
            polygonPoints = new Array
            for value in polygon
              polygonPoints.push value.join(' ')
            polygonPoints = polygonPoints.join(',')
            # lock in save data
            cdata.conceptURI = geoJSON
            cdata.conceptName = 'Polygon'
            # lock in form
            cdata_form.getFieldsByName("conceptName")[0].storeValue(cdata.conceptName).displayValue()
            cdata_form.getFieldsByName("conceptURI")[0].storeValue(cdata.conceptURI).displayValue()
      return

    # add click listener on type-buttons
    typebuttons = document.getElementsByClassName('mapbox-gl-draw_ctrl-draw-btn')

    # click on "type" button (polygon, line, point)
    checkFormCount = ->

      # reset form
      cdata.conceptURI = ''
      cdata.conceptName = ''
      # lock in form
      cdata_form.getFieldsByName("conceptName")[0].storeValue(cdata.conceptName).displayValue()
      cdata_form.getFieldsByName("conceptURI")[0].storeValue(cdata.conceptURI).displayValue()

      # check if only one form, else delete others
      data = draw.getAll();
      if data.features
        if data.features.length > 1
          if data.features[0].geometry.coordinates.length > 0
            # disable "save"button

            # delete all current features
            draw.deleteAll()
            # trigger click on button to return to ready-status    ###
            xselectorArr = document.querySelector('.mapbox-gl-draw_ctrl-draw-btn.active').className.split(' ')
            xselector = '.' + xselectorArr[0] + '.' + xselectorArr[1]
            document.querySelector(xselector).click();
            document.querySelector(xselector).click();
      return

    i = 0
    while i < typebuttons.length
      typebuttons[i].addEventListener 'click', checkFormCount, false
      i++



  #########################################################################
  # create form
  __getEditorFields: (cdata) ->
    fields = [
      {
        form:
          label: "Gewählter Typ"
        type: CUI.Output
        name: "conceptName"
        data: {conceptName: cdata.conceptName}
      }
      {
        form:
          label: "Verknüpfte Georeferenzierung"
        type: CUI.Output
        name: "conceptURI"
        data: {conceptURI: cdata.conceptURI}
      }]

    fields


  #######################################################################
  # checks the form and returns status
  getDataStatus: (cdata) ->
    if (cdata)
        if cdata.conceptURI and cdata.conceptName

          # check geojson
          geoJSONCheck = 0
          try
            json = JSON.parse(cdata.conceptURI)
          catch exception
            json = null
          if json
            geoJSONCheck = 1

          # check type
          typeCheck = if cdata.conceptName then cdata.conceptName.trim() else undefined

          if geoJSONCheck and typeCheck
            return "ok"

          if cdata.conceptURI.trim() == '' and cdata.conceptName.trim() == ''
            return "empty"

          return "invalid"
        else
          cdata = {
                conceptName : ''
                conceptURI : ''
            }
          return "empty"
    else
      cdata = {
            conceptName : ''
            conceptURI : ''
        }
      return "empty"


  #######################################################################
  # generates static mapbox-map via geojson

  __getStaticMapboxMap: (cdata) ->
    that = @
    mapContent = new CUI.Label
                  text: "Kartenansicht"
    htmlContent = 'no map available'
    # read mapbox_access_token from schema
    if that.getCustomSchemaSettings().mapbox_access_token?.value
        mapbox_access_token = that.getCustomSchemaSettings().mapbox_access_token?.value
    if mapbox_access_token
        # compare to https://www.mapbox.com/mapbox.js/example/v1.0.0/static-map-from-geojson-with-geo-viewport/
        jsonStr = '{"type": "FeatureCollection","features": []}'
        json = JSON.parse(jsonStr)
        json.features.push JSON.parse(cdata.conceptURI)
        bounds = geojsonExtent(json)
        if bounds
          size = [
            500
            300
          ]
          vp = geoViewport.viewport(bounds, size)
          encodedGeoJSON = JSON.parse(cdata.conceptURI)
          console.log encodedGeoJSON
          #onlyGeometry = onlyGeometry.geometry
          #console.log(onlyGeometry)
          encodedGeoJSON.properties['stroke-width'] = 4
          encodedGeoJSON.properties['stroke'] = '#C20000'
          encodedGeoJSON = JSON.stringify(encodedGeoJSON)
          encodedGeoJSON = encodeURIComponent(encodedGeoJSON)
          if vp.zoom > 16
            vp.zoom = 15;
          imageSrc = location.protocol + '//api.mapbox.com/v4/mapbox.streets-satellite/geojson(' + encodedGeoJSON + ')/' +  vp.center.join(',') + ',' + vp.zoom + '/' + size.join('x') + '@2x.png?access_token=' + mapbox_access_token
          htmlContent = "<div style=\"width:500px; height: 300px; background-color: gray; background-image: url('" + imageSrc  + "'); background-repeat: no-repeat; background-position: center center; background-size: contain;\"></div>"
      else
        htmlContent = "no mapbox-access-token for georef"
    mapContent.DOM.innerHTML = htmlContent
    mapContent

  #######################################################################
  # generates static mapbox-map via geojson

  __getUsuableMapboxMap: (cdata) ->
    that = @
    mapContent = new CUI.Label
                  text: "Kartenansicht"
    "__getUsuableMapboxMap"


  #######################################################################
  # renders the "result" in original form (outside popover)

  __renderButtonByData: (cdata) ->
    that = @
    # when status is empty or invalid --> message
    switch @getDataStatus(cdata)
      when "empty"
        return new CUI.EmptyLabel(text: $$("custom.data.type.georef.edit.no_georef")).DOM
      when "invalid"
        return new CUI.EmptyLabel(text: $$("custom.data.type.georef.edit.no_valid_georef")).DOM

    mapContent = @__getStaticMapboxMap(cdata)

    copyrightLabel = new CUI.Label
                    text: "Copyright"
                    size: "mini"
    copyrightLabel.DOM.innerHTML = "©&nbsp;<a href='https://www.mapbox.com/about/maps/'>Mapbox</a>&nbsp;&nbsp;©&nbsp;<a href='http://www.openstreetmap.org/copyright'>OpenStreetMap</a>&nbsp;&nbsp;<strong><a href='https://www.mapbox.com/map-feedback/' target='_blank'>Improve this map</a></strong>";

    mapPane = new CUI.Pane
      class: "cui-mapbox-georef-pane"
      top:
        content: [
          new CUI.PaneHeader
            left:
              content:
                new CUI.Label
                  text: "Kartenansicht (" + cdata.conceptName + ")"
            right:
              content: [
                #CUI.Pane.getToggleFillScreenButton()
              ]
        ]
      center:
        content: mapContent
      bottom:
        content: [
          new CUI.PaneFooter
            left:
              content: copyrightLabel
            right:
              content: ""
        ]

    CUI.Events.listen
       type: ["start-fill-screen", "end-fill-screen"]
       node: mapPane
       call: (ev) =>
          console.log "Event:", ev
          eventType = ev._type
          # if fullsize show usable map
          if (eventType == 'start-fill-screen')
            console.log "start-fill-screen"
            mapPane.replace(@__getUsuableMapboxMap(cdata), "center")
          # if normal view show small static map
          if (eventType == 'end-fill-screen')
            console.log "end-fill-screen"
            mapPane.replace(@__getStaticMapboxMap(cdata), "center")
          console.log "fertig eventiert"


    mapPane.DOM


  #######################################################################
  # zeige die gewählten Optionen im Datenmodell unter dem Button an
  getCustomDataOptionsInDatamodelInfo: (custom_settings) ->
    tags = []

    if custom_settings.mapbox_access_token?.value
      tags.push "✓ Mapbox-Access-Token"
    else
      tags.push "✘ Mapbox-Access-Token"

    tags

CustomDataType.register(CustomDataTypeGeoref)