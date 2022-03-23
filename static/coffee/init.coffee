---
---

root = exports ? this

root.utils ?= {}
root.effects = {}
root.controllers = {}
root.components = {}
root.variables = {}
root.events = {}

root.variables =
  debug: true
  controllers:
    # catch executions from handlers to oprevent whole page crashes.
    catchExceptions: false
    # log initial handler execution
    logInit: false
  navbarHeight: 50
  breakpoints:
    mobile: 768
    desktop: 769
    minWidth: 1000


root.utils.isBrowser = (browser) ->
  if browser == 'chrome'
    return isChrome = /Chrome/.test(navigator.userAgent) and /Google Inc/.test(navigator.vendor)
  # var isSafari = /Safari/.test(navigator.userAgent) && /Apple Computer/.test(navigator.vendor);

root.utils.isAtBreakpoint = (breakpoint) ->
  ### Detect if at breakpoints via labels corresponding to the SASS.
  Usage: mobile = isAtBreakpoint(mobile)
  ###
  breakpoints = root.variables.breakpoints

  # only switch to mobile when device is mobile as well
  if breakpoint == 'mobile' and window.is_mobile
    # width = if (window.innerWidth > 0)  then window.innerWidth else screen.width
    # return width < breakpoints.mobile
    return $(window).width() < breakpoints.mobile

  else if breakpoint == 'desktop'
    return $(window).width() > breakpoints.desktop

  else if breakpoint == 'tablet'
    return $(window).width() > breakpoints.mobile

root.utils.getCurrentBreakpoint = ->
  ### Get current breakpoint
  ###
  for breakpoint, px of root.variables.breakpoints
    isCurrent = root.utils.isAtBreakpoint breakpoint
    if isCurrent
      return breakpoint

root.utils.responsiveJS = (args) ->
  ### Simple responsive JS.
  Usage:
    responsiveJS
      query: ($window) ->   # function that returns true if valid.
      query: 'tablet'  # pipes to isAtBreakpoint function
      enter: ->  # function that triggers upon entering
      exit: ->  # function that triggers upon existing
  ###
  root.utils._responsiveJSQueries ?= []
  root.utils._responsiveJSQueries.push args

  @$window = $ window
  do responsiveJS = =>
    ### Go through all responsive queries.
    Find ones that match.
    Execute if entered.
    ###
    for responsive in root.utils._responsiveJSQueries
      if _.isFunction responsive.query
        matched = responsive.query @$window
      else
        # try to find a matching query
        matched = root.utils.isAtBreakpoint responsive.query

      if matched and not responsive.active
        responsive.active = true
        responsive.enter?()

      if not matched and responsive.active
        responsive.active = false
        responsive.exit?()

  @$window.on 'resize', _.debounce responsiveJS, 100

root.utils.lockScroll = (lock) ->
  ### Lock scroll for desktop.
  Mobile requires specific touch event locking.
  ###
  if lock == undefined
    $("html").toggleClass('no-scroll')
  else if lock
    $("html").addClass('no-scroll')
  else
    $("html").removeClass('no-scroll')

root.utils.scrollTo = ($el, options) ->
  animate = =>
    top = $el.offset().top
    $("html, body").animate
        scrollTop: top - (options.offset or 0)
      , options.speed or 1000, options.easing or 'easeInOutExpo'

  if options.delay
    _.delay animate, options.delay
  else
    animate()

root.utils.cookies =
  ### Cookie setters and getters
  ###
  set: (name, value, days) ->
    if days
      date = new Date()
      date.setTime date.getTime() + (days * 24 * 60 * 60 * 1000)
      expires = "; expires=" + date.toGMTString()
    else
      expires = ""
    document.cookie = name + "=" + value + expires + "; path=/"
  get: (name) ->
    nameEQ = name + "="
    ca = document.cookie.split(";")
    i = 0

    while i < ca.length
      c = ca[i]
      c = c.substring(1, c.length)  while c.charAt(0) is " "
      return c.substring(nameEQ.length, c.length)  if c.indexOf(nameEQ) is 0
      i++
    null
  delete: (name) ->
    setCookie name, "", -1

root.utils.getControllerInstance = (controllerName, $scope) ->
  ### Utility function to get an instance of a controller easily.
  ###
  if not $scope
    $scope = $ 'html'
  
  $controllers = $scope.find "[js-controller=\"#{controllerName}\"]"

  instances = ($(controller).data 'js-controller' for controller in $controllers)
  if instances.length == 1
    return instances[0]
  return instances

root.utils.evalAttribute = ($element, attribute) ->
  try
    return eval("(#{$element.attr(attribute)})") or {}
  catch ex
    console.log("Get args exception: ", ex, $element, attribute)
    return {}

root.utils.getArgs = ($element) ->
  ### Utilify function to get evaluated arguments from the DOM.
  ###
  return root.utils.evalAttribute $element, 'js-args'

root.utils.bindJSControllers = ($scope, force = false) ->
  ### Extremely light weight, anti framework DOM based JS execution model.
  An extremely simple implementation of web components, angular directives,
  react.js components.

  DOM elements with particular attributes will be automatically called:
     js-controller="controller"
     js-args="{foo: true}"

  Will be passed to a corresponding function in root.controllers
    i.e. root.controllers['controller']

  And passed the jQuery element as the first parameter and arguments as
  the second parameter.

  This system is the equivalent of calling `someFunction($(".selector), {})`
  and therefore has an extremely low complexity ceiling.
  ###
  if not $scope
    @$scope = $ 'html'
  else
    @$scope = $scope
  try
    tagname = @$scope.get(0)?.tagName? or ''
    console.log """Binding JS controllers/components for
      #{tagname}:#{@$scope.get(0).className}. Force: #{force}"""
  catch ex
    # console.error ex

  bindJSFactory = (attrName, objectName, $scope) ->
    ### Factory function to create binders for arbitrary attribute names.
    ###
    @attrName = attrName  # name of attr to respond to
    @objectName = objectName   # name of object to store functions in root/window.
    @loadedClass = "#{attrName}-loaded"
    @selector = "[#{attrName}]"

    if not force
      @selector += ":not(.#{loadedClass})"
    else
      console.log "Forcing re-binding"

    $scope.find(selector).each (index, el) =>
      bind = ($element) =>
        # find handler
        handler = $element.attr @attrName
        options = root.utils.getArgs $element
        controller = root[@objectName][handler]
        # only execute if controller found
        if controller
          handlerFunc = new (controller)($element, options)
        else if root.variables.controllers.logInit
          console.log "Controller not found for handler #{handler}"

        # set api and loaded class
        $element.data @attrName, handlerFunc
        $element.addClass @loadedClass

        if root.variables.controllers.logInit then console.log "#{handler} initialized with", {options}

        # destruct = =>
        #   try
        #     handlerFunc.destruct()
        #   catch ex
        #     if root.variables.debug
        #       console.error ex

      # only catch exceptions if settings forces so
      # helpful during development.
      if root.variables.controllers.catchExceptions
        try
          bind $(el)
        catch ex
          handler = $(el).attr @attrName
          console.error 'Error initializing: ', handler, ex
      else
        # don't catch exceptions
        bind $(el)
      return

  ### Initialize two different controller types:
  Controllers: for architectural logic that spans multiple components.
  Components: for reusable snippets isolated to a particular component.
  ###
  bindJSFactory 'js-controller', 'controllers', @$scope
  bindJSFactory 'js-component', 'components', @$scope

root.effects.handleFadeInOnLoad = ->
  ### Handle fade in / out on load
  ###
  if window.is_safari
    # only on safari, beforeunload doesn't fire..
    # but I also know that this method causes a dialog in older browsers.
    window.onbeforeunload = ->
      $("body").addClass('is-unloading')
      return

    $(window).bind "pageshow", (ev) ->
      if ev.originalEvent.persisted
        $("body").addClass 'is-loading'
      return
  else
    $(window).on 'beforeunload', ->
      $("body").addClass 'is-unloading'
      return

  # add loading animation on page load
  $("body").addClass 'is-loading'

# root.effects.resetAnimationState = ($scope) ->
#   if not $scope
#     @$scope = $ 'html'
#   else
#     @$scope = $scope

#   animated = @$scope.find '.a'
#   animated.removeClass 'a--animated a--animating'

# root.effects.handleScrollBasedAnimations = ->
#   ### Handle scroll based fade in based on .a classes.
#   ###
#   @$zeroHeightHiddenHelperCls = 'zero-height-hidden-helper'
#   @$zeroHeightHiddenHelperClsWithDot = '.zero-height-hidden-helper'

#   $.extend $.expr[':'],
#     zeroheight: (el, index, meta) ->
#       $el = $ el
#       # IE 11 fails calling height() here.
#       try
#         noHeight = $el.height() == 0
#         overflowHidden = $el.css('overflow') == 'hidden'
#       catch ex
#         console.log 'failed getting height', ex
#       if noHeight and overflowHidden
#         return true
#       return false

#     notzeroheightparent: (el, index, meta) =>
#       ### Account for instances where height of an element is 0.
#       0 height = not visible.
#       ###
#       $el = $ el
#       $zero = $el.closest(@$zeroHeightHiddenHelperClsWithDot)
#       if $zero.is(':zeroheight')
#         return false
#       return true

#   $(":zeroheight").each (index, el) =>
#     ### Detect zero height elements with hidden overflows as effectively non visible.
#     ###
#     $el = $ el
#     $el.addClass @$zeroHeightHiddenHelperCls

#   @$animatedCls = 'a--animated'
#   @$animatingCls = 'a--animating'
#   @$delay = 10
#   @$additionalDelay = 20
#   @$queued = 0

#   @getQueuedDelay = =>
#     delay = @$delay + (@$queued * @$additionalDelay)
#     # console.log "#{@$queued} in queue... delay is #{delay}"
#     return delay

#   @$animationSelector = """.a\
#     :in-viewport\
#     :not(.#{@$animatedCls})\
#     :not(.#{@$animatingCls})\
#     :not(:hidden)\
#     :notzeroheightparent
#     """

#   @animateInWindow = =>
#     ### Find elements that are not animated yet.
#     TODO: need mobile control. animate groups for desktop vs mobile.
#     ###
#     # exclusion = root.utils.getCurrentBreakpoint()
#     # selector = "#{@$animationSelector}:not(.a--ignore-#{exclusion})"
#     # console.log "Found exclusions: ", exclusion, 'final selector: ', selector
#     $toAnimate = $ @$animationSelector

#     $toAnimate.each (index, el) =>
#       $el = $ el
#       $el.addClass @$animatingCls

#       @$queued += 1
#       _.delay =>
#         $el.addClass @$animatedCls
#         @$queued -= 1
#       , @getQueuedDelay()
#       # console.log "Animating each... #{$el} adding #{@$animatedCls}", $el

#   $(window).on 'scroll', _.debounce @animateInWindow, 500
#   setInterval @animateInWindow, 200
#   setInterval =>
#     console.log "Queued: #{@$queued}"
#   , 10000

# root.effects.handleNavbarFadeIn = ->
#   ### Fade in navbar if it's hidden
#   ###
#   @$navbar = $ '[js-navbar]'
#   if @$navbar.is(':hidden')
#     @$navbar.addClass('notransition').delay(1000).fadeIn 'slow', 'easeInOutExpo', =>
#       @$navbar.removeClass 'notransition'

# root.effects.jquery =
#   slideDownFade: ($element, speed) ->
#     $element.css('opacity', 0).slideDown(speed, 'easeInOutExpo').animate({ opacity: 1 }, { queue: false, duration: speed })
#   slideUpFade: ($element, speed) ->
#     $element.css('opacity', 1).slideUp(speed, 'easeInOutExpo').animate({ opacity: 0 }, { queue: false, duration: speed })

# root.effects.init = () =>
# #   root.effects.handleFadeInOnLoad()
# #   root.effects.handleNavbarFadeIn()
# #   root.effects.handleScrollBasedAnimations()


root.responsiveImages = ->
  $("[data-responsive-image-color]").each ->
    color = $(this).attr('data-responsive-image-color')
    if not color
      color = 'rgba(0, 0, 0, .1)'
    $(this).css 'background-color', color

  $("[data-responsive-image-dimensions]").each ->
    $(this).wrapInner("<div class='image-background'/>");
    try
      dims = $(this).attr 'data-responsive-image-dimensions'
      dimPairs = dims.split 'x'
      height = Number dimPairs[0]
      width = Number dimPairs[1]
      $(this).css
        paddingBottom: (width/height)*100 + '%'
        position: 'relative'
        'background-color': $(this).attr('data-responsive-image-color')

      $(this).find('> img').css
        position: 'absolute'
        bottom: 0
        right: 0
        left: 0
        top: 0

    catch ex

root.init = ->
  ### Modernizr to initialize this.
  $.load is too early before components load.
  ###
  root.effects.handleFadeInOnLoad()
  root.utils.bindJSControllers()
  root.responsiveImages()
  $(window).on 'resize', _.debounce(root.responsiveImages, 500)
  # _.delay =>
  #   root.utils.bindJSControllers()
  # , 1000

  # add is loaded class for init animations
  $('body').addClass 'is-loaded'

$ ->
  root.init()
  console.log("Initialized 2022")

window.debug = (msg) ->
	$("[js-debug-txt]").html msg
	console.log msg
