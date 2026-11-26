any ux generated for this project or changes to html files needs to be compatible with internet exploer 7 host

IE7 zoom quirk (the dialog zooms with `document.body.style.zoom`): in VCarve's IE7 host, the zoom is NOT applied to
- anything with `position: absolute`, and
- anything put into the isometric view (`#BoxIsoView`) through innerHTML after the page has loaded - even plain normal-flow content.

Such content stays at 100% and lands small and in the wrong place when zoomed. So: build new dialog UI with floats / normal flow, and size anything that goes into `#BoxIsoView` (shapes, labels, messages) by hand with `isoZoomFix(view)` - width, height, line-height, font-size and positions all multiplied by it, the way the labels and the "Your box is being drawn" message do. Headless Edge / other browsers zoom everything correctly, so this can't be caught in a screenshot there; check every new piece of UI for it explicitly.
