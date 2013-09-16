'use strict'

define ['map/ui/base_map', 'map/hybrid_list'], (BaseMap, HybridList) ->

  class MapCanvas
    constructor: (@canvas) ->
      @listenForCanvasChanges()
      @resetPosition()

    listenForCanvasChanges: ->
      $(window).bind "resize", =>
        @triggerContainerSizeChange()

    resetPosition: ->
      $(@canvas).css({height: @containerHeight, width: @containerWidth})

    triggerContainerSizeChange: =>
      $(document).trigger 'mapCanvasResized', {height: @containerHeight(), width: @containerWidth()}

    containerHeight: ->
      canvasHeight = $("body").height() - $('#header').height()

    containerWidth: ->
      mapWindowWidth = $(window).width() - $('#hybrid_list').width()

  class MapUi

    @initialize: =>
      mapCanvas = new MapCanvas("#map_canvas")
      BaseMap.attachTo(mapCanvas.canvas)
      HybridList.attachTo('#hybrid_list')

  return MapUi.initialize