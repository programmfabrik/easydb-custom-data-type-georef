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
  showEditPopover: (btn, data, cdata, layout, opts) ->
    cdata_form = new CUI.Form
      data: cdata
      fields: @__getEditorFields(cdata)
      onDataChanged: =>
        @__updateResult(cdata, layout, opts)
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
        header_left: new CUI.Label(text: $$('custom.data.type.georef.name'))
        # "save"-button
        footer_right: []
        footer_left: cdata_form

        # "reset"-button
        content: xmapboxpane
      onHide: =>
        @__updateResult(cdata, layout, opts)
    .show()

    @__initMap(cdata, cdata_form, layout, opts)


  getMapboxAccessToken: () ->
    mapbox_access_token = ''
    if @getCustomSchemaSettings().mapbox_access_token?.value
      mapbox_access_token = @getCustomSchemaSettings().mapbox_access_token?.value
    else
      console.log "Kein Mapbox-Api-Key gegeben!"
      mapbox_access_token = false
    mapbox_access_token


  ##########################################################################
  # initialisiere Karte
  __initMap: (cdata, cdata_form, layout, opts) ->

    that = @

    mapboxgl.accessToken = that.getMapboxAccessToken()
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
        maxZoom: 20
    });

    # disable map rotation using right click + drag
    map.dragRotate.disable()

    # disable map rotation using touch rotation gesture
    map.touchZoomRotate.disableRotation()

    # add geocoder?
    if @getCustomSchemaSettings().use_geocoder?.value == true
      frontendLanguage = frontendLanguages = ez5.loca.getLanguage()
      geocoder = new MapboxGeocoder(
        accessToken: mapboxgl.accessToken
        language: frontendLanguage
        marker: false
        mapboxgl: mapboxgl)
      map.addControl(geocoder, 'top-left');

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
    if cdata.conceptURI != '' && cdata.conceptName != '' && cdata.conceptURI != undefined && cdata.conceptName != undefined
      geoJSON = JSON.parse(cdata.conceptURI)

      map.on 'load', ->
        map.addSource 'Georeferenzierung',
          'type': 'geojson'
          'data': geoJSON

        that.addMapLayers(map, 'Georeferenzierung', 'Georeferenzierung', true)

        # get bounds of formlayer
        map.fitBounds geojsonExtent(geoJSON), padding: 20
        return

    # click on map
    map.on 'click', (e) ->
      data = draw.getAll()
      if data.features.length == 1
        geoJSON = data.features[0]
        delete geoJSON.id
        type = data.features[0].geometry.type
        if type == 'Point'
          if data.features[0].geometry.coordinates.length == 2
            geoJSON = JSON.stringify(geoJSON)
            coords = data.features[0].geometry.coordinates
            coords = coords.join(' ')
            # lock in save data
            cdata.conceptURI = geoJSON
            cdata.conceptName = 'Point'
            #that.__updateResult(cdata, layout, opts)

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
            #that.__updateResult(cdata, layout, opts)

        if type == 'Polygon'
          # Each LinearRing of a Polygon must have 4 or more Positions
          if data.features[0].geometry.coordinates[0].length >= 5
            polygonCoords = data.features[0].geometry.coordinates
            # rewind the polygon to right hand rule (geojson-spec 1.0)
            turfPolygon = turf.polygon.polygon(polygonCoords)
            rewind = turf.rewind(turfPolygon);
            geoJSON.geometry.coordinates = rewind.geometry.coordinates
            geoJSON = JSON.stringify(geoJSON)

            # lock in save data
            cdata.conceptURI = geoJSON
            cdata.conceptName = 'Polygon'
            #that.__updateResult(cdata, layout, opts)
      return

    # add click listener on type-buttons
    typebuttons = document.getElementsByClassName('mapbox-gl-draw_ctrl-draw-btn')

    # remove existing features, if click on "add feature".
    removeExistingFeatures = ->
      # reset form
      cdata.conceptURI = ''
      cdata.conceptName = ''
      data = draw.getAll();
      draw.deleteAll()

    # click on "type" button (polygon, line, point)
    # --> delete "old" geometrys and clear cdata
    i = 0
    while i < typebuttons.length
      typebuttons[i].addEventListener 'mousedown', removeExistingFeatures, false
      i++


  #########################################################################
  # create form
  __getEditorFields: (cdata) ->
    fields = []

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
  # add various map layers for the different featuretypes
  addMapLayers: (map, source, id, interactive) ->
    # für Polygone
    map.addLayer
      'id': 'layerPolygon'
      'type': 'fill'
      'source': source
      'interactive': interactive
      'layout': {}
      'paint':
        'fill-color': '#C20000'
        'fill-opacity': 0.5
      'filter': ['==', '$type', 'Polygon']
    # für Linien
    map.addLayer
      'id': 'layerLineString'
      'type': 'line'
      'source': source
      'interactive': interactive
      'layout':
        'line-join': 'round'
        'line-cap': 'round'
      'paint':
        'line-color': '#C20000'
        'line-width': 4
      'filter': ['==', '$type', 'LineString']
    # für Punkte
    map.addLayer
      'id': 'layerPoint'
      'type': 'symbol'
      'source': source
      'interactive': interactive
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
      'filter': ['==', '$type', 'Point']

  #######################################################################
  # generates static mapbox-map via geojson
  initStaticMap:(containerID, cdata, parentNode) ->
    that = @
    timeout = 200

    # if container exists yet --> don't set a timeout
    container = CUI.dom.findElement(parentNode.DOM, "#" + containerID)
    if container
      timeout = 0

    setTimeout ->

      container = CUI.dom.findElement(parentNode.DOM, "#" + containerID)

      mapbox_access_token = that.getMapboxAccessToken()
      if mapbox_access_token
        mapboxgl.accessToken = mapbox_access_token

        mapContent = new CUI.Label
                      text: $$('custom.data.type.georef.edit.kartenansicht')

        geojsonFromCdata = JSON.parse(cdata.conceptURI)

        # if this is not a FeatureCollection yet
        if geojsonFromCdata?.type != "FeatureCollection"
          jsonStr = '{"type": "FeatureCollection","features": []}'
          geoJSON = JSON.parse(jsonStr)
          geoJSON.features.push geojsonFromCdata
        else
          geoJSON = geojsonFromCdata

        map = new mapboxgl.Map({
            container: container
            style: 'mapbox://styles/mapbox/satellite-streets-v10'
            center: [9.935,51.5338]
            zoom: 5
            maxZoom: 17
            attributionControl: false,
            interactive: false
        });
        map.on 'load', ->
          if geojsonFromCdata
            # create
            map.addSource 'Georeferenzierung',
              'type': 'geojson'
              'data': geoJSON

            that.addMapLayers(map, 'Georeferenzierung', 'Georeferenzierung', false)
            map.fitBounds geojsonExtent(geoJSON), padding: 20

          map.on 'idle', ->
            map.resize()
          # Add zoom and rotation controls to the map.
          map.addControl(new mapboxgl.NavigationControl());
      else
        console.error "no mapbox-access-token for georef"
    , timeout

  #######################################################################
  # update result in Masterform
  __updateResult: (cdata, layout, opts) ->
    that = @
    # if field is not empty
    if cdata?.conceptURI
      # die uuid einkürzen..
      displayURI = cdata.conceptURI
      displayURI = displayURI.replace('http://', '')
      displayURI = displayURI.replace('https://', '')
      uriParts = displayURI.split('/')
      uuid = uriParts.pop()
      if uuid.length > 10
        uuid = uuid.substring(0,5) + '…'
        uriParts.push(uuid)
        displayURI = uriParts.join('/')

      copyrightLabel = new CUI.Label
                      text: "Copyright"
                      size: "mini"
      copyrightLabel.DOM.innerHTML = "©&nbsp;<a href='https://www.mapbox.com/about/maps/'>Mapbox</a>&nbsp;&nbsp;©&nbsp;<a href='http://www.openstreetmap.org/copyright'>OpenStreetMap</a>&nbsp;&nbsp;<strong><a href='https://www.mapbox.com/map-feedback/' target='_blank'>Improve this map</a></strong>";

      info = new CUI.VerticalLayout
        class: 'ez5-info_commonPlugin'
        top:
          content:
            mapPane = new CUI.Pane
              class: "cui-mapbox-georef-pane"
              top:
                content: [
                  new CUI.PaneHeader
                    left:
                      content:
                        new CUI.Label
                          text: cdata.conceptName + ' (' + $$('custom.data.type.georef.edit.kartenansicht') + ')'
                ]
              center:
                content:
                  new CUI.SimplePane
                      id: "georef_mapbox_container_static"
                      class: "georef_mapbox_container_static"
                      content:
                          new CUI.Label
                              text: ""
              bottom:
                content: [
                  new CUI.PaneFooter
                    left:
                      content: copyrightLabel
                    right:
                      content: ""
                ]

      # load static map to container
      that.initStaticMap('georef_mapbox_container_static', cdata, layout)

      layout.replace(info, 'center')
      layout.addClass('ez5-linked-object-edit')
      options =
        class: 'ez5-linked-object-container'
      layout.__initPane(options, 'center')

    # if field is empty, display searchfield
    if ! cdata?.conceptURI
      suggest_Menu_directInput

      inputX = new CUI.Input
                  class: "pluginDirectSelectEditInput"
                  undo_and_changed_support: false
                  name: "directSelectInput"
                  content_size: false
                  onKeyup: (input) =>
                    input.setValue('')
      inputX.render()

      # init suggestmenu
      suggest_Menu_directInput = new CUI.Menu
          element : inputX
          use_element_width_as_min_width: true

      # init xhr-object to abort running xhrs
      searchsuggest_xhr = { "xhr" : undefined }

      layout.replace(inputX, 'center')
      layout.removeClass('ez5-linked-object-edit')
      options =
        class: ''
      layout.__initPane(options, 'center')

    # did data change?
    that.__setEditorFieldStatus(cdata, layout)


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
                  text: cdata.conceptName + ' (' + $$('custom.data.type.georef.edit.kartenansicht') + ')'
            right:
              content: [
                CUI.Pane.getToggleFillScreenButton()
              ]
        ]
      center:
        content:
          new CUI.SimplePane
              id: "georef_mapbox_container_static"
              class: "georef_mapbox_container_static"
              content:
                  new CUI.Label
                      text: ""
      bottom:
        content: [
          new CUI.PaneFooter
            left:
              content: copyrightLabel
            right:
              content: ""
        ]

    # load static map to container
    that.initStaticMap('georef_mapbox_container_static', cdata, mapPane)

    mapPane.DOM


  #######################################################################
  # zeige die gewählten Optionen im Datenmodell unter dem Button an
  getCustomDataOptionsInDatamodelInfo: (custom_settings) ->
    tags = []

    if custom_settings.mapbox_access_token?.value
      tags.push "✓ Mapbox-Access-Token"
    else
      tags.push "✘ Mapbox-Access-Token"

    if custom_settings.use_geocoder?.value
      tags.push "✓ Geocoder"
    else
      tags.push "✘ Geocoder"

    tags

CustomDataType.register(CustomDataTypeGeoref)
