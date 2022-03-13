(function () {
  var root;

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  root.globalAPI = {};

  root.globalAPI.isMobile = function () {
    return $("body").hasClass("layout-mobile");
  };

  root.globalAPI.handleHeroAlign = function () {
    var targetHeight;
    if (
      !root.globalAPI.isMobile() &&
      !root.globalAPI.fullProjectView &&
      root.globalAPI.currentOverlay === "projects"
    ) {
      targetHeight = $(".navbar__items").offset().top - 75;
      if (targetHeight < 200) {
        return;
      }
      return $(".module-hero__background").height(targetHeight);
    }
  };

  root.globalAPI.toggleFPV = function () {
    var $project, projectAPI;
    $project = $("[js-index-project]:in-viewport:first");
    projectAPI = $project.data("js-controller");
    return projectAPI.toggleFullProjectView();
  };

  root.controllers.indexSwiper = function ($element, args) {
    var swiper;
    return (swiper = root.components.swiper($element, {
      lazyLoading: true,
      lazyLoadingInPrevNext: true,
      autoplay: 3000,
      effect: "fade",
      fade: {
        crossFade: true,
      },
      speed: 500,
      onInit: function (swiper) {},
    }));
  };

  root.controllers.projects = function ($element, args) {
    var handleProjectLinks;
    return (handleProjectLinks = function () {
      var $triggers;
      $triggers = $("[js-project-link]");
      return $triggers.on("click", function () {
        var projectHash;
        projectHash = $(this).attr("js-project-link");
        window.location.hash = projectHash;
        return root.globalAPI.desktopDirectLoadOnHash("#" + projectHash);
      });
    })();
  };

  root.controllers.project = function ($element, args) {
    var api, handleViewFullProject;
    api = {};
    $(window).on("resize", function (ev) {
      return root.globalAPI.handleHeroAlign();
    });
    (handleViewFullProject = function () {
      var $close, $scrollingContainer, $trigger;
      $scrollingContainer = $('[js-index-content="projects"]');
      $trigger = $element.find("[js-index-view-full-project]");
      api.animateProjectBodyIn = function (apply) {
        var $body;
        if (apply == null) {
          apply = true;
        }
        $body = $element.find(".module-text__body");
        if (apply) {
          return $body.slideDown(600, "easeInOutExpo", function () {
            return $body.show().addClass("animating-in");
          });
        } else {
          return $body.removeClass("animating-in").slideUp(200);
        }
      };
      api.toggleFullProjectView = function () {
        var $currentRow,
          $itemsToFade,
          $projectRows,
          $result,
          currentProjectIndex,
          duration,
          scrollTopDifference;
        $currentRow = $element.closest(".index-project-row");
        $projectRows = $(".index-project-row");
        currentProjectIndex = $projectRows.index($currentRow);
        this.hideProjectsBeforeIndex = function (index) {
          var $projectRowsBefore;
          $projectRowsBefore = $projectRows.filter(":lt(" + index + ")");
          return $projectRowsBefore.hide();
        };
        $itemsToFade = $(".navbar__items");
        this.fadeOutNav = function (cb) {
          var $result;
          $result = $itemsToFade.animate(
            {
              opacity: 0,
            },
            500,
            "easeInOutExpo"
          );
          if (cb) {
            return $result.promise().then(cb);
          }
        };
        this.fadeInNav = function (cb) {
          var $result;
          $result = $itemsToFade.animate(
            {
              opacity: 1,
            },
            500,
            "easeInOutExpo"
          );
          if (cb) {
            return $result.promise().then(cb);
          }
        };
        this.scrollToElement = function () {
          var absoluteScrollOffset;
          absoluteScrollOffset =
            $element.offset().top + $scrollingContainer.scrollTop();
          return $scrollingContainer.scrollTop(absoluteScrollOffset);
        };
        this.scrollToElementAnimated = function (duration) {
          var absoluteScrollOffset;
          absoluteScrollOffset =
            $element.offset().top + $scrollingContainer.scrollTop();
          return $scrollingContainer.animate(
            {
              scrollTop: absoluteScrollOffset,
            },
            duration || 500,
            "easeInOutExpo"
          );
        };
        this.enterFPV = (function (_this) {
          return function () {
            root.globalAPI.fullProjectView = true;
            _.delay(function () {
              return (root.globalAPI.allowScrollSpyAnimateInBody = true);
            }, 1000);
            return _this.fadeOutNav(function () {
              $("html").addClass("js-viewing-full-project");
              $(window).trigger("resize");
              return _.delay(function () {
                $projectRows.show();
                _this.scrollToElement();
                return api.animateProjectBodyIn();
              }, 600);
            });
          };
        })(this);
        this.exitFPV = (function (_this) {
          return function () {
            $("html").removeClass("js-viewing-full-project");
            _.delay(function () {
              return _this.fadeInNav();
            }, 1000);
            return _.delay(function () {
              $(".module-text__body").hide().removeClass("animating-in");
              $projectRows.show();
              $(window).trigger("resize");
              return _this.scrollToElement();
            }, 600);
          };
        })(this);
        this.toggleFPV = function () {
          if ($("html").hasClass("js-viewing-full-project")) {
            root.globalAPI.allowScrollSpyAnimateInBody = false;
            root.globalAPI.fullProjectView = false;
            api.animateProjectBodyIn(false);
            return _.delay(
              (function (_this) {
                return function () {
                  return _this.exitFPV();
                };
              })(this),
              400
            );
          } else {
            return this.enterFPV();
          }
        };
        scrollTopDifference = Math.abs($element.offset().top);
        if (scrollTopDifference > 100) {
          if (scrollTopDifference > 1000) {
            duration = 1000;
          } else {
            duration = 500;
          }
        } else {
          duration = 200;
        }
        $result = this.scrollToElementAnimated(duration);
        return $result.promise().then(
          (function (_this) {
            return function () {
              _this.hideProjectsBeforeIndex(currentProjectIndex);
              $scrollingContainer.scrollTop(0);
              return _this.toggleFPV();
            };
          })(this)
        );
      };
      $trigger.on("click", api.toggleFullProjectView);
      $close = $("[js-index-project-close]");
      if (!$close.data("js-loaded")) {
        $close.on("click", function () {
          var $project, projectAPI;
          $project = $("[js-index-project]:in-viewport(500):first");
          projectAPI = $project.data("js-controller");
          return projectAPI.toggleFullProjectView();
        });
        return $close.data("js-loaded", true);
      }
    })();
    return api;
  };

  root.controllers.moduleCredits = function ($element, args) {
    /* Distribute credits into each column.
     */
    var $a, populateColumns;
    $a = $element.find("[js-module-credits-item]");
    (populateColumns = function () {
      var $visibleCols, counter, length;
      $visibleCols = $element.find("[js-module-credit-column]:visible");
      $visibleCols.html("");
      length = $visibleCols.length;
      counter = 0;
      return $a.each(function () {
        $(this).appendTo($visibleCols.eq(counter));
        if (counter !== length - 1) {
          return (counter += 1);
        } else {
          return (counter = 0);
        }
      });
    })();
    return $(window).on("resize", _.throttle(populateColumns, 100));
  };

  root.controllers.navbar2 = function ($element, args) {
    var $allContent,
      $items,
      api,
      centerNavbar,
      handleColumnSizing,
      handleDirectLoadViaHash,
      handleLogoClick,
      handleMobileNav,
      handleScrollSpy,
      i,
      initItem,
      item,
      lastActiveItem,
      len,
      showDropdown;
    api = {};
    (handleColumnSizing = function () {
      /* Handle column sizing.
        Can't do with pure CSS, therefore use JS to emulate.
         */
      var $navbarColumns, getColumnWidth, width;
      $navbarColumns = $(".navbar__item");
      getColumnWidth = function () {
        /* There are 2 columns each being 1/8 wide.
          Padding is 20px.
          Total width is composed of:
          [LEFT MARGIN][GUTTER][COLUMN][GUTTER][COLUMN][GUTTER]
          
          Rows contain -1/2 gutter margin.
          Given window width of 1000px
            Usable space is 1000-30 margins = 970px
            970*1/8
           */
        var MARGIN, columnWidth, usableSpace, windowWidth;
        MARGIN = 30;
        windowWidth = $(window).width();
        usableSpace = windowWidth - MARGIN;
        columnWidth = usableSpace * (1 / 8);
        return columnWidth;
      };
      width = getColumnWidth();
      return $navbarColumns.css({
        width: width,
      });
    })();
    $(window).on("resize", handleColumnSizing);
    (handleMobileNav = function () {
      var $navOpen, toggleMobileNavbar;
      $navOpen = $("[js-mobile-navbar-open]");
      toggleMobileNavbar = function () {
        if ($("body").hasClass("mobile-navbar-is-open")) {
          return $("body").removeClass("mobile-navbar-is-open");
        } else {
          return $("body").addClass("mobile-navbar-is-open");
        }
      };
      return $navOpen.on("click", toggleMobileNavbar);
    })();
    (centerNavbar = function () {
      var $wrapper, height, marginTop, wHeight;
      $wrapper = $element.find("[js-wrapper]");
      height = $wrapper.height();
      wHeight = $(window).height();
      marginTop = wHeight / 2 - height / 2;
      console.log(
        "nav height: ",
        height,
        "w height",
        wHeight,
        "marginTop: ",
        marginTop
      );
      return $wrapper.css({
        marginTop: marginTop,
      });
    })();
    $(window).on("resize", centerNavbar);
    $allContent = $("[js-index-content]");
    api.hideAllContentAndFadeInOne = function ($content) {
      if ($content.is(":visible")) {
        return;
      }
      return $allContent
        .stop(true, true)
        .fadeOut()
        .promise()
        .done(function () {
          return $content.fadeIn();
        });
    };
    (handleLogoClick = function () {
      var $logo;
      $logo = $element.find("[js-navbar-logo]");
      return $logo.on("click", function (ev) {
        var $el;
        if (!root.globalAPI.isMobile()) {
          ev.preventDefault();
          if (root.globalAPI.fullProjectView) {
            console.log("exiting FPV");
            root.globalAPI.toggleFPV();
            return false;
          }
          $el = $('[js-index-content="index"]');
          api.hideAllContentAndFadeInOne($el);
          api.clearNavbarState();
          window.location.hash = "#";
          return false;
        }
      });
    })();
    showDropdown = function ($dropdown, apply) {
      if (root.globalAPI.isMobile()) {
      } else {
        if (apply) {
          $dropdown.show();
          return _.delay(function () {
            return $dropdown.addClass("is-open", 100);
          });
        } else {
          $dropdown.removeClass("is-open");
          $dropdown.hide();
          return $dropdown.find(".is-active").removeClass("is-active");
        }
      }
    };
    api.clearNavbarState2 = function () {
      var $dropdowns;
      console.log("Clearing navbar state");
      $dropdowns = $element.find(".navbar__dropdown");
      return $dropdowns.removeClass("is-open").hide();
    };
    api.clearNavbarState = function () {
      var dropdown, i, len, ref;
      api.disableScrollingCallbacks = false;
      ref = $element.find("[js-item-dropdown]");
      for (i = 0, len = ref.length; i < len; i++) {
        dropdown = ref[i];
        showDropdown($(dropdown), false);
      }
      $(".navbar__item").removeClass("is-active");
      return $("[js-item-dropdown]").css({
        marginTop: 0,
      });
    };
    lastActiveItem = null;
    initItem = function ($item) {
      var $label, $siblingItems, activateItem, alignItemWithParent, scrollTo;
      $label = $item.find("[js-item-label]:first");
      $siblingItems = $item.siblings();
      alignItemWithParent = function ($item) {
        var $dropdown, height, top;
        $dropdown = $item.closest(".navbar__dropdown");
        height = $item.parent().height();
        top = $item.position().top;
        if (top > 200) {
          console.log("top > 200.. can't be right");
          return;
        }
        return $item
          .parent()
          .stop(true)
          .animate(
            {
              marginTop: "-" + top + "px",
            },
            600
          );
      };
      scrollTo = function ($item) {
        var $scrollingContainer,
          $target,
          offset,
          position,
          scrollSpyTarget,
          scrollingContainerScrollTop;
        scrollSpyTarget = $label.attr("js-scrollspy-nav");
        args = root.utils.getArgs($label);
        console.log("scrolling to.. target", scrollSpyTarget);
        if (scrollSpyTarget) {
          api.disableScrollingCallbacks = true;
          $target = $('[js-scrollspy="' + scrollSpyTarget + '"]');
          $scrollingContainer = $('[js-index-content="' + args.overlay + '"]');
          if (args.scrollAlignToNav) {
            position = $("[js-navbar-item-root].is-active").position().top;
            console.log("Align to nav.. position: ", position);
            offset = $target.offset().top - position + 5;
            offset = offset + (Number(args.scrollAlignToNavOffset) || 0);
            console.log("Align to nav.. position2: ", position);
          } else {
            console.log("not align", $target);
            offset = $target.offset().top;
          }
          scrollingContainerScrollTop = $scrollingContainer.scrollTop();
          offset = scrollingContainerScrollTop + offset;
          console.log("scrolling to offset: ", offset);
          return $scrollingContainer.stop(true, true).animate(
            {
              scrollTop: offset,
            },
            750,
            "easeInOutExpo",
            function () {
              api.disableScrollingCallbacks = false;
              return activateItem($item);
            }
          );
        }
      };
      activateItem = function ($item, preventAlign) {
        var $dropdown,
          $el,
          $img,
          $nextItem,
          hash,
          i,
          index,
          scrollSpy,
          showDropdown2;
        if (preventAlign == null) {
          preventAlign = false;
        }
        $dropdown = $item.find("[js-item-dropdown]:first");
        args = root.utils.getArgs($label);
        if (root.globalAPI.isMobile()) {
          if (args.mobileURL) {
            window.location.href = args.mobileURL;
            return false;
          }
        }
        root.globalAPI.currentOverlay = args.overlay;
        switch (args.overlay) {
          case "index":
            $el = $('[js-index-content="index"]');
            api.hideAllContentAndFadeInOne($el);
            break;
          case "projects":
            $el = $('[js-index-content="projects"]');
            api.hideAllContentAndFadeInOne($el);
            root.globalAPI.handleHeroAlign();
            break;
          case "studio":
            $el = $('[js-index-content="studio"]');
            api.hideAllContentAndFadeInOne($el);
            if (!root.globalAPI.hoverImagesLoaded) {
              for (index = i = 1; i <= 7; index = ++i) {
                $img = new Image();
                $img.src = "/static/img/hover-" + index + ".jpg";
              }
              root.globalAPI.hoverImagesLoaded = true;
            }
            break;
          case "journal":
            $el = $('[js-index-content="journal"]');
            api.hideAllContentAndFadeInOne($el);
            break;
          default:
            console.log("Not Found", args.overlay);
        }
        if (args.rootNode) {
          console.log("is root node");
          api.clearNavbarState();
          $("html, body").scrollTop(0);
          $("[js-index-content]").scrollTop(1).scrollTop(0);
        }
        showDropdown2 = function (apply) {
          if (apply) {
            return $dropdown.show().addClass("is-open");
          }
        };
        showDropdown($dropdown, true);
        $siblingItems.removeClass("is-active");
        $item.addClass("is-active");
        lastActiveItem = $item;
        if (!args.rootNode && !preventAlign) {
          alignItemWithParent($item);
        }
        scrollSpy = $label.attr("js-scrollspy-nav");
        if (scrollSpy) {
          hash = scrollSpy;
          if (root.globalAPI.fullProjectView) {
            hash = hash + ":full-project-view";
          }
          window.location.hash = hash;
        }
        if (args.rootNode && !root.globalAPI.isMobile()) {
          $nextItem = $item.find(".navbar__item:first");
          $nextItem.addClass("is-active");
          window.location.hash = $nextItem
            .find("[js-scrollspy-nav]:first")
            .attr("js-scrollspy-nav");
          $("[js-show-contact-info-if-visible]").data("shown", false);
        }
        console.log("activate item returning true");
        return true;
      };
      $label.on("click", function () {
        var scroll;
        scroll = activateItem($item);
        if (!scroll) {
          console.log("not scroll, skipping scrollTo");
          return;
        }
        console.log("scrolling to");
        return scrollTo($item);
      });
      if (!root.globalAPI.isMobile()) {
        return $label.on("scrollspy:activate", function () {
          if (!api.disableScrollingCallbacks) {
            return activateItem($item, false);
          }
        });
      }
    };
    $items = $element.find(".navbar__item");
    for (i = 0, len = $items.length; i < len; i++) {
      item = $items[i];
      initItem($(item));
    }
    (handleDirectLoadViaHash = function (hash) {
      var $parentNav, $scrollSpyNav, action, splits;
      console.log("loading direct from hash");
      if (!hash) {
        hash = window.location.hash;
      }
      if (!hash) {
        return;
      }
      hash = hash.substr(1);
      if (hash.indexOf(":") > 0) {
        splits = hash.split(":");
        hash = splits[0];
        action = splits[1];
      }
      $scrollSpyNav = $('[js-scrollspy-nav="' + hash + '"]');
      if ($scrollSpyNav) {
        $parentNav = $scrollSpyNav.parent().parent().parent();
        $parentNav.find("[js-item-label]:first").click();
        _.delay(function () {
          $scrollSpyNav.click();
          return console.log("clicking scrollspy nav", $scrollSpyNav);
        }, 500);
        switch (action) {
          case "full-project-view":
            return _.delay(function () {
              return root.globalAPI.toggleFPV();
            }, 1600);
        }
      }
    })("");
    root.globalAPI.desktopDirectLoadOnHash = handleDirectLoadViaHash;
    return (handleScrollSpy = function () {
      var onScroll;
      onScroll = function () {
        var $nav, $project, $showContact, $spiesInViewport, projectAPI, target;
        $spiesInViewport = $("[js-scrollspy]:in-viewport(500):visible:first");
        target = $spiesInViewport.attr("js-scrollspy");
        $nav = $('[js-scrollspy-nav="' + target + '"]');
        $nav.trigger("scrollspy:activate");
        if (
          root.globalAPI.fullProjectView &&
          root.globalAPI.allowScrollSpyAnimateInBody
        ) {
          if ($spiesInViewport.hasClass("index-project-row")) {
            $project = $spiesInViewport.find("[js-index-project]");
            projectAPI = $project.data("js-controller");
            projectAPI.animateProjectBodyIn();
          }
        }
        $showContact = $(
          "[js-show-contact-info-if-visible]:in-viewport:visible:first"
        );
        if (
          $showContact.length > 0 &&
          !$showContact.data("shown") &&
          root.globalAPI.showContactBar
        ) {
          root.globalAPI.showContactBar();
          return $showContact.data("shown", true);
        }
      };
      return $("[js-index-content]").on("scroll", _.throttle(onScroll, 70));
    })();
  };

  root.controllers.studioContent = function ($element, args) {
    var $navItem, updatePadding;
    $navItem = $("[js-navbar-studio]");
    (updatePadding = function () {
      return $element.css({
        paddingTop: $navItem.offset().top - $(window).scrollTop() - 25,
      });
    })();
    return $(window).on("resize", _.throttle(updatePadding, 500));
  };

  root.controllers.studioLocation = function ($element, args) {
    var updateTime;
    (updateTime = function () {
      var $date, $time, time;
      switch (args.location) {
        case "lac":
          time = moment().tz("America/Los_Angeles");
          break;
        case "sydney":
          time = moment().tz("Australia/Sydney");
      }
      $time = $element.find("[js-time]");
      $date = $element.find("[js-date]");
      $date.html(time.format("dddd MMMM D"));
      return $time.html(time.format("h:mma"));
    })();
    return setInterval(updateTime, 60 * 1000);
  };

  root.controllers.footer = function ($element, args) {
    var $open, close, handleOnClickOutside, open;
    handleOnClickOutside = function (cb) {
      return $(document).on("click", function (event) {
        if ($(event.target).is("[js-footer-show]")) {
          return;
        }
        if (
          !$(event.target).closest(".footer").length &&
          !$(event.target).is(".footer")
        ) {
          return cb();
        }
      });
    };
    close = function () {
      $element.slideUp("slow", "easeInOutExpo");
      return _.delay(function () {
        return $("[js-show-contact-info-if-visible]").data("shown", false);
      }, 1500);
    };
    open = function () {
      return $element.slideDown("slow", "easeInOutExpo");
    };
    root.globalAPI.showContactBar = open;
    $open = $("[js-footer-show]");
    $open.on("click", function () {
      if ($element.is(":visible")) {
        return close();
      } else {
        return open();
      }
    });
    $("[js-footer-close]").on("click", close);
    return handleOnClickOutside(close);
  };

  root.controllers.mobileStudio = function ($element, args) {};

  root.controllers.layoutDefault = function ($element, args) {
    /* Desktop template general controller
     */
    var handleLinkHoverEffects;
    return (handleLinkHoverEffects = function () {
      var $triggers, getOrCreateHoverEl, mouseEnter, mouseLeave;
      console.log("handling link hover effects");
      getOrCreateHoverEl = function (index) {
        var $el;
        $el = $(".js-hover-element");
        if (!$el.length) {
          $el = $("<img class='js-hover-element' />");
          $("body").append($el);
        }
        if (index) {
          $el.attr("src", "/static/img/hover-" + index + ".jpg");
        }
        return $el;
      };
      $triggers = $element.find(".hover-effect");
      mouseLeave = function (ev) {
        var $img;
        $img = getOrCreateHoverEl();
        return $img.hide();
      };
      mouseEnter = function (ev) {
        var $img, imgH, imgW, index, left, top, wh, ww;
        index = $(".hover-effect").index($(ev.currentTarget)) + 1;
        wh = $(window).height();
        ww = $(window).width();
        $img = getOrCreateHoverEl(index);
        $img.css({
          width: Math.random() * 200 + 250,
          opacity: 0,
        });
        $img.show();
        imgW = $img.width();
        imgH = $img.height();
        top = Math.random() * (wh - imgH - 200);
        left = Math.random() * (ww - imgW - 200);
        $img.css({
          position: "fixed",
          top: top,
          left: left,
        });
        return _.delay(function () {
          return $img.css({
            opacity: 1,
          });
        }, 100);
      };
      $triggers.on("mouseleave", function (ev) {
        var ex;
        try {
          return mouseLeave(ev);
        } catch (error) {
          ex = error;
        }
      });
      return $triggers.on("mouseenter", function (ev) {
        var ex;
        try {
          return mouseEnter(ev);
        } catch (error) {
          ex = error;
        }
      });
    })();
  };

  root.controllers.mobileProjectBody = function ($element, args) {
    var $readMore;
    $readMore = $element.find("[js-mobile-module-read-more]");
    return $readMore.on(
      "click",
      (function (_this) {
        return function () {
          return $readMore.slideUp(function () {
            return $element
              .find("[js-mobile-module-body]")
              .slideDown("slow", "easeInOutExpo");
          });
        };
      })(this)
    );
  };

  root.controllers.lazyLoadBg = function ($element, args) {
    return $element.on("");
  };
}.call(this));
