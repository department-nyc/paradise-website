---
---

root = exports ? this

root.globalAPI = {}
root.globalAPI.isMobile = ->
    return $("body").hasClass 'layout-mobile'

root.globalAPI.handleHeroAlign = ->
    if not root.globalAPI.isMobile() and not root.globalAPI.fullProjectView and root.globalAPI.currentOverlay == 'projects'
      targetHeight = $(".navbar__items").offset().top - 75
      if targetHeight < 200
        return
      $('.module-hero__background').height targetHeight

root.globalAPI.toggleFPV = ->
  $project = $("[js-index-project]:in-viewport:first")
  projectAPI = $project.data 'js-controller'
  projectAPI.toggleFullProjectView()

root.controllers.indexSwiper = ($element, args) ->
  swiper = root.components.swiper $element,
    # loop: true
    lazyLoading: true
    lazyLoadingInPrevNext: true
    autoplay: 3000,
    effect: 'fade',
    fade: {
      crossFade: true
    },
    speed: 500
    onInit: (swiper) ->


root.controllers.projects = ($element, args) ->
  do handleProjectLinks = ->
    $triggers = $ '[js-project-link]'
    $triggers.on 'click', ->
      projectHash = $(this).attr 'js-project-link'
      window.location.hash = projectHash
      root.globalAPI.desktopDirectLoadOnHash('#' + projectHash)


root.controllers.project = ($element, args) ->
  api = {}

  $(window).on 'resize', (ev) ->
    root.globalAPI.handleHeroAlign()

  do handleViewFullProject = ->
    $scrollingContainer = $("[js-index-content=\"projects\"]")
    # $scrollingContainer = $("html, body'")

    $trigger = $element.find '[js-index-view-full-project]'

    api.animateProjectBodyIn = (apply=true) ->
      # animate the project body in. slide down first, then transform in left
      $body = $element.find '.module-text__body'
      if apply
        $body.slideDown 600, 'easeInOutExpo', ->
          $body.show().addClass 'animating-in'
      else
        $body.removeClass('animating-in').slideUp(200)

    api.toggleFullProjectView = ->
      # v2 toggle full project
      # try removing content above current project
      $currentRow = $element.closest ".index-project-row"
      $projectRows = $ ".index-project-row"
      currentProjectIndex = $projectRows.index $currentRow

      # hide projects above this one
      @hideProjectsBeforeIndex = (index) ->
        $projectRowsBefore = $projectRows.filter ":lt(#{index})"
        $projectRowsBefore.hide()

      $itemsToFade = $(".navbar__items")

      @fadeOutNav = (cb) ->
        $result = $itemsToFade.animate opacity: 0, 500, 'easeInOutExpo'
        if cb
          $result.promise().then cb

      @fadeInNav = (cb) ->
        $result = $itemsToFade.animate opacity: 1, 500, 'easeInOutExpo'
        if cb
          $result.promise().then cb


      @scrollToElement = ->
        # scroll to this element inside scrolling container.
        absoluteScrollOffset = $element.offset().top + $scrollingContainer.scrollTop()
        $scrollingContainer.scrollTop absoluteScrollOffset

      @scrollToElementAnimated = (duration) ->
        absoluteScrollOffset = $element.offset().top + $scrollingContainer.scrollTop()
        return $scrollingContainer.animate scrollTop: absoluteScrollOffset, duration or 500, 'easeInOutExpo'

      # NOTE: window trigger resize repositions nav. It needs to fire earlier.
      # to prevent FOUC. It seems it's not in the right position
      @enterFPV = =>
        root.globalAPI.fullProjectView = true
        _.delay ->
          root.globalAPI.allowScrollSpyAnimateInBody = true
        , 1000
        @fadeOutNav =>
          $('html').addClass 'js-viewing-full-project'
          $(window).trigger 'resize'
          # $(".index-project .animate-in").removeClass('animating-out').addClass 'animating-in'
          _.delay =>
            $projectRows.show()
            @scrollToElement()
            api.animateProjectBodyIn()
          , 600

      @exitFPV = =>
        # $('html').addClass 'js-viewing-full-project--animating-out'
        $('html').removeClass 'js-viewing-full-project'

        _.delay =>
          # $('html').removeClass 'js-viewing-full-project--animating-out'
          @fadeInNav()
        , 1000

        # only show rows above / scroll to element instantly after CSS animation completes
        _.delay =>
            $(".module-text__body").hide().removeClass 'animating-in'
            $projectRows.show()
            $(window).trigger 'resize'
            @scrollToElement()
            # $(".index-project .animate-in").addClass('animating-out').removeClass 'animating-in'
        , 600  # CSS animation duration

      @toggleFPV = ->
        if $('html').hasClass 'js-viewing-full-project'
          # prevent scrollspy from triggering body in animation
          root.globalAPI.allowScrollSpyAnimateInBody = false

          root.globalAPI.fullProjectView = false

          api.animateProjectBodyIn false
          _.delay =>
            @exitFPV()
          , 400
        else
          @enterFPV()

      # 1: scroll to top of project first. then hide content above.
      # change scrolling timing if far from current location
      scrollTopDifference = Math.abs($element.offset().top)
      if scrollTopDifference > 100
        if scrollTopDifference > 1000
          duration = 1000
        else
          duration = 500
      else
        duration = 200

      $result = @scrollToElementAnimated duration

      # 2: when scrolling done, hide all projects above
      $result.promise().then =>
        @hideProjectsBeforeIndex currentProjectIndex
        $scrollingContainer.scrollTop 0
        @toggleFPV()

    $trigger.on 'click', api.toggleFullProjectView

    # bind close handler once.
    $close = $('[js-index-project-close]')
    if not $close.data 'js-loaded'
      $close.on 'click', ->
        $project = $("[js-index-project]:in-viewport(500):first")
        projectAPI = $project.data 'js-controller'
        projectAPI.toggleFullProjectView()

      $close.data 'js-loaded', true

  return api

root.controllers.moduleCredits = ($element, args) ->
  ### Distribute credits into each column.
  ###
  $a = $element.find "[js-module-credits-item]"

  do populateColumns = ->
    $visibleCols = $element.find '[js-module-credit-column]:visible'
    $visibleCols.html ''

    length = $visibleCols.length
    counter = 0
    $a.each ->
      $(this).appendTo $visibleCols.eq(counter)

      if counter != (length-1)
        counter += 1
      else
        counter = 0

  $(window).on 'resize', _.throttle populateColumns, 100


root.controllers.navbar2 = ($element, args) ->
  api = {}

  do handleColumnSizing = ->
    ### Handle column sizing.
    Can't do with pure CSS, therefore use JS to emulate.
    ###
    $navbarColumns = $ ".navbar__item"

    getColumnWidth = ->
      ### There are 2 columns each being 1/8 wide.
      Padding is 20px.
      Total width is composed of:
      [LEFT MARGIN][GUTTER][COLUMN][GUTTER][COLUMN][GUTTER]

      Rows contain -1/2 gutter margin.
      Given window width of 1000px
        Usable space is 1000-30 margins = 970px
        970*1/8
      ###
      MARGIN = 30
      windowWidth = $(window).width()
      usableSpace = windowWidth - MARGIN
      columnWidth = usableSpace * (1/8)
      return columnWidth

    width = getColumnWidth()
    $navbarColumns.css
      width: width
  $(window).on 'resize', handleColumnSizing

  do handleMobileNav = ->
    $navOpen = $("[js-mobile-navbar-open]")
    toggleMobileNavbar = ->
      if $("body").hasClass 'mobile-navbar-is-open'
        $("body").removeClass 'mobile-navbar-is-open'
      else
        $("body").addClass 'mobile-navbar-is-open'

    $navOpen.on 'click', toggleMobileNavbar

  do centerNavbar = ->
    $wrapper = $element.find('[js-wrapper]')
    height = $wrapper.height()
    wHeight = $(window).height()
    marginTop = (wHeight/2) - (height/2)
    console.log 'nav height: ', height, 'w height', wHeight, 'marginTop: ', marginTop
    $wrapper.css
      marginTop: marginTop

  $(window).on 'resize', centerNavbar


  $allContent = $("[js-index-content]")
  api.hideAllContentAndFadeInOne = ($content) ->
    if $content.is(':visible')
      # console.log "Content visible, skipping fade in"
      return

    $allContent.stop(true, true).fadeOut().promise().done ->
      $content.fadeIn()

  do handleLogoClick = ->
    $logo = $element.find('[js-navbar-logo]')
    # show slider on logo click
    $logo.on 'click', (ev) ->
      if not root.globalAPI.isMobile()
        ev.preventDefault()
        if root.globalAPI.fullProjectView
          console.log 'exiting FPV'
          root.globalAPI.toggleFPV()
          return false

        $el = $("[js-index-content=\"index\"]")
        api.hideAllContentAndFadeInOne $el
        api.clearNavbarState()
        window.location.hash = '#'
        return false


  showDropdown = ($dropdown, apply) ->
    if root.globalAPI.isMobile()
      # no more mobile navbar
      # if apply and not $dropdown.hasClass 'is-open'
      #   $dropdown.show()
      # else
      #   $dropdown.hide()
      #   $dropdown.find('.is-active').removeClass 'is-active'
    else
      if apply # and not $dropdown.hasClass 'is-open'
        $dropdown.show()
        _.delay ->  $dropdown.addClass 'is-open', 100
      else
        $dropdown.removeClass 'is-open'
        $dropdown.hide()
        # _.delay ->
        #   if not $dropdown.hasClass 'is-open'
        #     $dropdown.hide()
        # , 600
        $dropdown.find('.is-active').removeClass 'is-active'

  api.clearNavbarState2 = ->
    console.log "Clearing navbar state"
    $dropdowns = $element.find '.navbar__dropdown'
    $dropdowns.removeClass('is-open').hide()

  api.clearNavbarState = ->
    api.disableScrollingCallbacks = false
    for dropdown in $element.find('[js-item-dropdown]')
      showDropdown $(dropdown), false

    $('.navbar__item').removeClass 'is-active'
    $("[js-item-dropdown]").css
      marginTop: 0

  lastActiveItem = null
  initItem = ($item) ->
    # console.log 'initializing item', $item
    $label = $item.find '[js-item-label]:first'
    $siblingItems = $item.siblings()

    alignItemWithParent = ($item) ->
      # align the active element to parent
      $dropdown = $item.closest('.navbar__dropdown')
      height = $item.parent().height()
      top = $item.position().top
      # console.log 'top: ', top, ' height:', height
      # console.log 'dropdown css is -', top, $dropdown

      if top > 200
        console.log 'top > 200.. can\'t be right'
        return

      $item.parent().stop(true).animate
        marginTop: "-#{top}px"
      , 600

    scrollTo = ($item) ->
      scrollSpyTarget = $label.attr 'js-scrollspy-nav'
      args = root.utils.getArgs($label)

      console.log 'scrolling to.. target', scrollSpyTarget
      if scrollSpyTarget
        api.disableScrollingCallbacks = true
        $target = $("[js-scrollspy=\"#{scrollSpyTarget}\"]")

        $scrollingContainer = $("[js-index-content=\"#{args.overlay}\"]")
        if args.scrollAlignToNav
          # align to first tier navbar active
          position = $("[js-navbar-item-root].is-active").position().top
          console.log("Align to nav.. position: ", position)
          offset = $target.offset().top - position + 5  # compensate for font heights
          offset = offset + (Number(args.scrollAlignToNavOffset) or 0)
          console.log("Align to nav.. position2: ", position)
        else
          console.log 'not align', $target
          offset = $target.offset().top

        # offset is relative to current container scrollTop. Adjust final by current scrollTop
        scrollingContainerScrollTop =  $scrollingContainer.scrollTop()
        offset = scrollingContainerScrollTop + offset
        console.log 'scrolling to offset: ', offset

        $scrollingContainer.stop(true, true).animate
          scrollTop: offset
        , 750, 'easeInOutExpo', ->
          api.disableScrollingCallbacks = false
          activateItem $item

        # if args.overlay == 'projects'
        #     $projectsContainer = $("[js-index-content=\"projects\"]")

        #     if args.scrollAlignToNav
        #       position = $('.navbar__item.is-active:first').position().top
        #       offset = $target.offset().top - position + 5  # compensate for font heights
        #     else
        #       offset = $target.offset().top

        #     # offset is relative to current container scrollTop. Adjust final by current scrollTop
        #     projectsScrollTop =  $projectsContainer.scrollTop()
        #     offset = projectsScrollTop + offset

        #     $projectsContainer.stop(true, true).animate
        #       scrollTop: offset
        #     , 750, 'easeInOutExpo', ->
        #       api.disableScrollingCallbacks = false
        #       activateItem $item
        # else
          # console.log "non project scorll'"

    activateItem = ($item, preventAlign = false) ->
      $dropdown = $item.find '[js-item-dropdown]:first'
      args = root.utils.getArgs($label)
      # console.log 'activating item'
      if root.globalAPI.isMobile()
        # console.log 'is mobile'
        if args.mobileURL
          window.location.href = args.mobileURL
          # console.log 'moving', args.mobileURL
          return false  # scroll param

      root.globalAPI.currentOverlay = args.overlay

      switch args.overlay

        when 'index'
          $el = $("[js-index-content=\"index\"]")
          api.hideAllContentAndFadeInOne $el

        when 'projects'
          $el = $("[js-index-content=\"projects\"]")
          api.hideAllContentAndFadeInOne $el
          root.globalAPI.handleHeroAlign()
        when 'studio'
          $el = $("[js-index-content=\"studio\"]")
          api.hideAllContentAndFadeInOne $el

          if not root.globalAPI.hoverImagesLoaded
            for index in [1..7]
              $img = new Image()
              $img.src = "/static/img/hover-#{index}.jpg"
            root.globalAPI.hoverImagesLoaded = true

        when 'journal'
          $el = $("[js-index-content=\"journal\"]")
          api.hideAllContentAndFadeInOne $el
        else
          console.log "Not Found", args.overlay


      if args.rootNode
        # is root node - misnamed arg
        console.log 'is root node'
        # for dropdown in $element.find('[js-item-dropdown]')
        #   $(dropdown).hide()
        # $element.find('.is-active').removeClass 'is-active'
        # $element.find('.is-open').removeClass 'is-open'
        api.clearNavbarState()
        # api.clearNavbarState2()
        $('html, body').scrollTop(0)
        $("[js-index-content]").scrollTop(1).scrollTop(0)


      showDropdown2 = (apply) ->
        if apply
          $dropdown.show().addClass 'is-open'

      showDropdown $dropdown, true
      # showDropdown2 $dropdown, true
      # console.log($dropdown)

      $siblingItems.removeClass 'is-active'
      $item.addClass 'is-active'

      lastActiveItem = $item
      if not args.rootNode and not preventAlign
        alignItemWithParent($item)

      scrollSpy = $label.attr('js-scrollspy-nav')
      if scrollSpy
        hash = scrollSpy
        if root.globalAPI.fullProjectView
          hash = hash + ":full-project-view"
        window.location.hash = hash

      if args.rootNode and not root.globalAPI.isMobile()
        # is root node - misnamed arg
        $nextItem = $item.find '.navbar__item:first'
        $nextItem.addClass 'is-active'
        window.location.hash = $nextItem.find('[js-scrollspy-nav]:first').attr 'js-scrollspy-nav'

        # reset shown state
        $("[js-show-contact-info-if-visible]").data('shown', false)

      console.log 'activate item returning true'
      return true

    $label.on 'click', ->
      scroll = activateItem $item
      if not scroll
        console.log 'not scroll, skipping scrollTo'
        return
      console.log 'scrolling to'
      scrollTo $item

    if not root.globalAPI.isMobile()
      $label.on 'scrollspy:activate', ->
        # console.log("api.disableScrollingCallbacks: ", api.disableScrollingCallbacks);
        if not api.disableScrollingCallbacks
          activateItem $item, false


  $items = $element.find '.navbar__item'
  for item in $items
    initItem $(item)

  do handleDirectLoadViaHash = (hash = '') ->
    console.log 'loading direct from hash'
    if not hash
        hash = window.location.hash

    if not hash
      return

    hash = hash.substr 1
    if hash.indexOf(':') > 0
      splits = hash.split ':'
      hash = splits[0]
      action = splits[1]

    $scrollSpyNav = $("[js-scrollspy-nav=\"#{hash}\"]")
    if $scrollSpyNav
      #  click parent
      $parentNav = $scrollSpyNav.parent().parent().parent()
      $parentNav.find('[js-item-label]:first').click()

      _.delay ->
        $scrollSpyNav.click()
        console.log 'clicking scrollspy nav', $scrollSpyNav
      , 500

      switch action
        when 'full-project-view'
          _.delay ->
            root.globalAPI.toggleFPV()
          , 1600

  root.globalAPI.desktopDirectLoadOnHash = handleDirectLoadViaHash
  # console.log 'pre handle scrollspy'
  do handleScrollSpy = ->
    # console.log 'handling scrollspy'
    onScroll = ->
      $spiesInViewport = $("[js-scrollspy]:in-viewport(500):visible:first")
      # console.log 'spies in viweport: ', $spiesInViewport
      target = $spiesInViewport.attr 'js-scrollspy'
      $nav = $("[js-scrollspy-nav=\"#{target}\"]")
      $nav.trigger 'scrollspy:activate'

      if root.globalAPI.fullProjectView and root.globalAPI.allowScrollSpyAnimateInBody
        if $spiesInViewport.hasClass 'index-project-row'
          # console.log 'spies in VP - loading project body in'
          # is a project
          $project = $spiesInViewport.find('[js-index-project]')
          projectAPI = $project.data 'js-controller'
          projectAPI.animateProjectBodyIn()

      # show contact element if a show contact div is in viewport.
      $showContact = $("[js-show-contact-info-if-visible]:in-viewport:visible:first")
      # console.log "show contact element: ", $showContact, $showContact.is(':visible')

      if ($showContact.length > 0) and not $showContact.data('shown') and root.globalAPI.showContactBar
        root.globalAPI.showContactBar()
        $showContact.data 'shown', true

    # $(window).on 'scroll', _.throttle onScroll, 50
    $("[js-index-content]").on 'scroll', _.throttle(onScroll, 70)

root.controllers.studioContent = ($element, args) ->
  $navItem = $("[js-navbar-studio]")

  do updatePadding = ->
    $element.css
      paddingTop: $navItem.offset().top - $(window).scrollTop() - 25

  $(window).on 'resize', _.throttle(updatePadding, 500)

root.controllers.studioLocation = ($element, args) ->
  do updateTime = ->
    switch args.location
      when 'lac'
        time = moment().tz('America/Los_Angeles')
      when 'sydney'
        time = moment().tz('Australia/Sydney')
    $time = $element.find '[js-time]'
    $date = $element.find '[js-date]'
    $date.html time.format('dddd MMMM D')
    $time.html time.format('h:mma')
  setInterval updateTime, 60*1000

root.controllers.footer = ($element, args) ->
  handleOnClickOutside = (cb) ->
    $(document).on 'click', (event) ->
      if $(event.target).is('[js-footer-show]')
        return

      if not $(event.target).closest('.footer').length and not $(event.target).is('.footer')
        cb()
  close = ->
    $element.slideUp 'slow', 'easeInOutExpo'

    # allow popup to be shown again via scroll Xs after closing
    _.delay ->
      $("[js-show-contact-info-if-visible]").data('shown', false)
    , 1500


  open = ->
    $element.slideDown 'slow', 'easeInOutExpo'

  root.globalAPI.showContactBar = open

  $open = $('[js-footer-show]')
  $open.on 'click', ->
    if $element.is(':visible')
      close()
    else
      open()

  $("[js-footer-close]").on 'click', close

  handleOnClickOutside close


root.controllers.mobileStudio = ($element, args) ->
  # do handleDirectLoadViaHash = ->
  #   hash = window.location.hash
  #   if not hash
  #     return
  #   $("body").removeClass 'mobile-navbar-is-open'
  #   _.delay ->
  #     hash = hash.substr 1
  #     if not hash
  #       offset = 1
  #     else
  #       if hash == 'manifesto'
  #         adjustment = 100
  #       else
  #         adjustment = 50
  #       $target = $("[js-scrollspy=\"#{hash}\"]")
  #       offset = $target.offset().top - (adjustment)
  #     $("html, body").animate
  #       scrollTop: offset
  #     , 1000, 'easeInOutExpo'
  #   , 500

  # window.onhashchange = handleDirectLoadViaHash


root.controllers.layoutDefault = ($element, args) ->
  ### Desktop template general controller
  ###

  do handleLinkHoverEffects = ->
    console.log 'handling link hover effects'

    getOrCreateHoverEl = (index) ->
      $el = $(".js-hover-element")
      if not $el.length
        $el = $ "<img class='js-hover-element' />"
        $('body').append $el
      if index
        $el.attr 'src', "/static/img/hover-#{index}.jpg"
      return $el

    $triggers = $element.find('.hover-effect')

    mouseLeave = (ev) ->
      $img = getOrCreateHoverEl()
      $img.hide()

    mouseEnter = (ev) ->
      # get number
      index = $(".hover-effect").index($(ev.currentTarget)) + 1

      # add random hover
      wh = $(window).height()
      ww = $(window).width()

      $img = getOrCreateHoverEl(index)
      $img.css
        width: (Math.random() * 200) + 250
        opacity: 0
      $img.show()
      imgW = $img.width()
      imgH = $img.height()

      top = Math.random() * (wh - imgH - 200)
      left = Math.random() * (ww - imgW - 200)

      # imgRight = imgW + left

      # if imgRight > ww
      #   left = ww - imgW - 30

      # imgBot = imgH + top
      # if imgBot > wh
      #   top = wh - imgH - 30

      $img.css
        position: 'fixed'
        top: top
        left: left
      _.delay ->
        $img.css opacity: 1
      , 100

    $triggers.on 'mouseleave', (ev) ->
      try mouseLeave(ev) catch ex
    $triggers.on 'mouseenter', (ev) ->
      try mouseEnter(ev) catch ex


root.controllers.mobileProjectBody = ($element, args) ->
  $readMore = $element.find('[js-mobile-module-read-more]')
  $readMore.on 'click', =>
    $readMore.slideUp ->
      $element.find('[js-mobile-module-body]').slideDown 'slow', 'easeInOutExpo'


root.controllers.lazyLoadBg = ($element, args) ->
  $element.on ''

