##
# JS for file metric
##
metricColors = ['#DC5B47', '#477DDC', '#47DC5B', '#DCA547']
metricColor = 0;

# 
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
      change_second_label: 'from last year',
      change_second_points: 51
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
  
  setBackground: ->
    $(@node).parent().css('background-color', metricColors[metricColor])
    metricColor = if metricColor == metricColors.length - 1 then 0 else metricColor + 1

  ready: ->
    container = $(@node).parent()
    @setBackground()
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
        color: 'rgba(0, 0, 0, 0.3)',
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
    @set('start_date', moment.unix(data.points[0].x).format(settings.axis_label))
    @set('end_date',  moment.unix(data.points[last].x).format(settings.axis_label))
    
    # Update intervals
    @set('change_first_interval', if (!data.points[last - 1].y) then 0 else
      ((data.points[last].y - data.points[last - 1].y) / 
      data.points[last - 1].y * 100).toFixed(2))
    @set('change_first_interval_label', 'Change ' + settings.change_first_label + ', ' +  
      moment.unix(data.points[last - 1].x).format(settings.hover_label))
    
    @set('change_second_interval', if (!data.points[last - settings.change_second_points].y) then 0 else
      ((data.points[last].y - data.points[last - 
      settings.change_second_points].y) / data.points[last - 
      settings.change_second_points].y * 100).toFixed(2))
    @set('change_second_interval_label', 'Change ' + settings.change_second_label + ', ' +  
      moment.unix(data.points[last - settings.change_second_points].x).format(settings.hover_label))
