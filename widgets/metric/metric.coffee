class Dashing.Metric extends Dashing.Widget
  xformatter: {
    'day': 'MMM DD',
    'week': 'YYYY ww',
    'month': 'YYYY MMM'
  }
  
  interval: 'month'

  @accessor 'current', ->
    return @get('displayedValue') if @get('displayedValue')
    
    points = @get('points')
    if points
      points[points.length - 1].y

  ready: ->
    @graphColor = @graphColor || '#C93C26' #'rgba(0, 0, 0, 0.5)'
    container = $(@node).parent()
    interval = @interval
    xformatter = @xformatter

    # Gross hacks. Let's fix this.
    width = (Dashing.widget_base_dimensions[0] * container.data('sizex')) + Dashing.widget_margins[0] * 2 * (container.data('sizex') - 1)
    height = (Dashing.widget_base_dimensions[1] * container.data('sizey'))
    
    # Create graph
    @graph = new Rickshaw.Graph(
      element: @node
      width: width
      height: height
      padding: { top: 1, right: 0, bottom: 0, left: 0 }
      series: [{
        color: @graphColor,
        data: [{ x: 0, y: 0 }]
      }]
    )
    # Assign data
    @graph.series[0].data = @get('points') if @get('points')

    # Define and format axis
    y_axis = new Rickshaw.Graph.Axis.Y({
      graph: @graph
      pixelsPerTick: 80
      tickFormat: Rickshaw.Fixtures.Number.formatKMBT
    })
    x_axis = new Rickshaw.Graph.Axis.X({
      graph: @graph
      pixelsPerTick: 80
      tickFormat: (x) ->
        moment.unix(x).format(xformatter[interval])
    });
    
    hover = new Rickshaw.Graph.HoverDetail({
      graph: @graph,
      formatter: (series, x, y) ->
        y + '<br />' + moment.unix(x).format(xformatter[interval])
    });
    
    @graph.render()

  onData: (data) ->
    # Update graph
    if @graph
      @graph.series[0].data = data.points
      @graph.render()
      
    # Update details
    @start_date = moment.unix(data.points[0].x).format(@xformatter[@interval])
    @end_date = moment.unix(data.points[data.points.length - 1].x).format(@xformatter[@interval])
