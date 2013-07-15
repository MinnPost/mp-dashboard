class Dashing.Metric extends Dashing.Widget
  xformatter: {
    'day': {
      axis_label: 'MMM DD',
      hover_label: 'MMM DD',
      change_first_label: 'from yesterday',
      change_second_label: 'from last month',
      change_second_points: 30
    },
    'week': {
      axis_label: 'YYYY MMM',
      hover_label: 'YYYY [week:] ww',
      change_first_label: 'from last week',
      change_second_label: 'from ~6 months',
      change_second_points: 24
    },
    'month': {
      axis_label: 'YYYY MMM',
      hover_label: 'YYYY MMM',
      change_first_label: 'from last month',
      change_second_label: 'from last year',
      change_second_points: 12
    }
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
        moment.unix(x).format(xformatter[interval].axis_label)
    });
    
    hover = new Rickshaw.Graph.HoverDetail({
      graph: @graph,
      formatter: (series, x, y) ->
        y + '<br />' + moment.unix(x).format(xformatter[interval].hover_label)
    });
    
    @graph.render()

  onData: (data) ->
    last = data.points.length - 1
    settings = @xformatter[@interval]
  
    # Update graph
    if @graph
      @graph.series[0].data = data.points
      @graph.render()
      
    # Update range details
    @start_date = moment.unix(data.points[0].x).format(settings.axis_label)
    @end_date = moment.unix(data.points[last].x).format(settings.axis_label)
    
    # Update intervals
    @change_first_interval = ((data.points[last].y - data.points[last - 1].y) / 
      data.points[last - 1].y * 100).toFixed(2)
    @change_first_interval_label = 'Change ' + settings.change_first_label + ', ' +  
      moment.unix(data.points[last - 1].x).format(settings.hover_label)
    
    @change_second_interval = ((data.points[last].y - data.points[last - 
      settings.change_second_points].y) / data.points[last - 
      settings.change_second_points].y * 100).toFixed(2)
    @change_second_interval_label = 'Change ' + settings.change_second_label + ', ' +  
      moment.unix(data.points[last - settings.change_second_points].x).format(settings.hover_label)
