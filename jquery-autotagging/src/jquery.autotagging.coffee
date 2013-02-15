define ['jquery', './lib/browserdetect', 'jquery-cookie-rjs',], ($, browserdetect) ->
  class WH
    cacheBuster:  0
    domain:       ''
    firstVisit:   null
    lastLinkClicked: null
    metaData:     null
    oneTimeData:  null
    path:         ''
    performance:  window.performance || {}
    sessionID:    ''
    userID:       ''
    warehouseTag: null

    init: (opts={}) =>
      @clickBindSelector = opts.clickBindSelector || 'a, input[type=submit], input[type=button], img'
      if opts.exclusions?
        @clickBindSelector = @clickBindSelector.replace(/,\s+/g, ":not(#{opts.exclusions}), ")

      @domain            = document.location.host
      @exclusionList     = opts.exclusionList || []
      @fireCallback      = opts.fireCallback
      @parentTagsAllowed = opts.parentTagsAllowed || /div|ul/
      @path              = "#{document.location.pathname}#{document.location.search}"
      @warehouseURL      = opts.warehouseURL

      @setCookies()
      @determineDocumentDimensions(document)
      @determineWindowDimensions(window)
      @determinePlatform(window)

      @metaData = @getDataFromMetaTags(document)
      @firePageViewTag()
      @bindBodyClicked(document)

    bindBodyClicked: (doc) ->
      $(doc).on 'click', @clickBindSelector, @elemClicked

    determineParent: (elem) ->
      for el in elem.parents()
        return @firstClass($(el)) if el.tagName.toLowerCase().match(@parentTagsAllowed)

    determineWindowDimensions: (obj) ->
      obj = $(obj)
      @windowDimensions = "#{obj.width()}x#{obj.height()}"

    determineDocumentDimensions: (obj) ->
      obj = $(obj)
      @browserDimensions = "#{obj.width()}x#{obj.height()}"

    determinePlatform: (win) ->
      @platform = browserdetect.platform(win)

    elemClicked: (e, opts={}) =>
      domTarget = e.target
      jQTarget = $(e.target)
      attrs = domTarget.attributes

      item = @firstClass(jQTarget) or ''
      subGroup = @determineParent(jQTarget) or ''
      value = jQTarget.text() or ''

      trackingData = {
        # cg, a.k.a. contentGroup, should come from meta tag with name "WH.cg"
        sg:     subGroup
        item:   item
        value:  value
        type:   'click'
        x:      e.clientX
        y:      e.clientY}

      for attr in attrs
        if attr.name.indexOf('data-') == 0 and attr.name not in @exclusionList
          realName = attr.name.replace('data-', '')
          trackingData[realName] = attr.value

      href = jQTarget.attr('href')
      if href and opts.followHref? and opts.followHref
        @lastLinkClicked = href
        e.preventDefault()

      @fire trackingData
      e.stopPropagation()

    fire: (obj) =>
      obj.ft                      = @firedTime()
      obj.cb                      = @cacheBuster++
      obj.sess                    = "#{@userID}.#{@sessionID}"
      obj.fpc                     = @userID
      obj.site                    = @domain
      obj.path                    = @path
      obj.title                   = $('title').text()
      obj.bs                      = @windowDimensions
      obj.sr                      = @browserDimensions
      obj.os                      = @platform.OS
      obj.browser                 = @platform.browser
      obj.ver                     = @platform.version
      obj.ref                     = document.referrer
      obj.registration            = if $.cookie('sgn') == '1' then 1 else 0
      obj.person_id               = $.cookie('zid') if $.cookie('sgn')?
      obj.email_registration      = if $.cookie('provider') == 'identity' then 1 else 0
      obj.facebook_registration   = if $.cookie('provider') == 'facebook' then 1 else 0
      obj.googleplus_registration = if $.cookie('provider') == 'google_oauth2' then 1 else 0
      obj.twitter_registration    = if $.cookie('provider') == 'twitter' then 1 else 0

      @fireCallback?(obj)

      if @oneTimeData?
        for key of @oneTimeData
          obj[key] = @oneTimeData[key]

      if @firstVisit
        obj.firstVisit = @firstVisit
        @firstVisit = null

      @obj2query($.extend(obj, @metaData), (query) =>
        requestURL = @warehouseURL + query

        # handle IE url length limit
        if requestURL.length > 2048 and navigator.userAgent.indexOf('MSIE') >= 0
          requestURL = requestURL.substring(0,2043) + "&tu=1"

        if @warehouseTag
          @warehouseTag[0].src = requestURL
        else
          @warehouseTag = $('<img/>',
            {id:'PRMWarehouseTag', border:'0', width:'1', height:'1', src: requestURL })

        @warehouseTag.onload = $('body').trigger('WH_pixel_success_' + obj.type)
        @warehouseTag.onerror = $('body').trigger('WH_pixel_error_' + obj.type)

        if @lastLinkClicked
          lastLinkRedirect = (e) ->
            # ignore obtrusive JS in an href attribute
            document.location = @lastLinkClicked if @lastLinkClicked.indexOf('javascript:') == -1

          @warehouseTag.unbind('load').unbind('error').
            bind('load',  lastLinkRedirect).
            bind('error', lastLinkRedirect))

    firedTime: =>
      now =
        @performance.now        or
        @performance.webkitNow  or
        @performance.msNow      or
        @performance.oNow       or
        @performance.mozNow
      (now? and now.call(@performance)) || new Date().getTime()

    firePageViewTag: ->
      @fire { type: 'pageview' }

    firstClass: (elem) ->
      return unless klasses = elem.attr('class')
      klasses.split(' ')[0]

    getDataFromMetaTags: (obj) ->
      retObj = { cg: '' }
      metas = $(obj).find('meta')

      for metaTag in metas
        metaTag = $(metaTag)
        if metaTag.attr('name') and metaTag.attr('name').indexOf('WH.') is 0
          name = metaTag.attr('name').replace('WH.', '')
          retObj[name] = metaTag.attr('content')
      retObj

    getOneTimeData: ->
      @oneTimeData

    obj2query: (obj, cb) =>
      rv = []
      for key of obj
        rv.push "&#{key}=#{encodeURIComponent(val)}" if obj.hasOwnProperty(key) and (val = obj[key])?
      cb(rv.join('').replace(/^&/,'?'))
      return

    setCookies: ->
      userID    = $.cookie('WHUserID')
      sessionID = $.cookie('WHSessionID')
      timestamp = new Date().getTime()

      unless userID
        userID = timestamp
        $.cookie('WHUserID', userID, { expires: 3650, path: '/' })

      unless sessionID
        sessionID = timestamp
        @firstVisit = timestamp
        $.cookie('WHSessionID', sessionID, { path: '/' })

      @sessionID = sessionID
      @userID = userID

  setOneTimeData: (obj) =>
    @oneTimeData ||= {}
    for key of obj
      @oneTimeData[key] = obj[key]
