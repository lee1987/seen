class seen.Scene
  defaults:
    cullBackfaces : true
    projection    : seen.Projections.perspective(-100, 100, -100, 100, 100, 300)
    viewport      : seen.Viewports.centerOrigin(500, 500)

  constructor: (options) ->
    seen.Util.defaults(@, options, @defaults)

    @dispatch = d3.dispatch('beforeRender', 'afterRender')
    d3.rebind(@, @dispatch, ['on'])

    @group  = new seen.Group()
    @shader = seen.Shaders.phong
    @lights =
      points   : []
      ambients : []
    @surfaces = []

  startRenderLoop: (msecDelay = 30) ->
    setInterval(@render, msecDelay)

  render: () =>
    @dispatch.beforeRender()
    surfaces = @renderSurfaces()
    @renderer.render(surfaces)
    @dispatch.afterRender(surfaces : surfaces)
    return @

  renderSurfaces: () =>
    # compute projection matrix
    projection = @projection.multiply(@viewport)

    # clear renderable surfaces array
    @surfaces.length = 0
    @group.eachTransformedShape (shape, transform) =>
      for surface in shape.surfaces
        # compute transformed and projected geometry
        render = surface.updateRenderData(transform, projection)
        
        # test for culling
        if (not @cullBackfaces or not surface.cullBackfaces or render.projected.normal.z < 0)
          # apply material shading
          render.fill   = surface.fill?.render(@lights, @shader, render.transformed)
          render.stroke = surface.stroke?.render(@lights, @shader, render.transformed)

          # add surface to renderable surfaces array
          @surfaces.push(surface)

    # sort for painter's algorithm
    @surfaces.sort (a, b) ->
      return  b.render.projected.barycenter.z - a.render.projected.barycenter.z

    return @surfaces
