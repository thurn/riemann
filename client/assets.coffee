###
# To the extent possible under law, the author(s) have dedicated all copyright
# and related and neighboring rights to this software to the public domain
# worldwide. This software is distributed without any warranty. You should have
# received a copy of the CC0 Public Domain Dedication along with this software.
# If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
###

noughts.assets = {}

assets = {
  x: {
    method: "path",
    args: ["m 13.951449,175.57936 c 2.990413,-3.47415 9.032589,-11.02219 12.243447,-15.29485 1.481221,-1.97105 12.451265,-17.32061 24.377875,-34.11013 L 72.257509,95.647969 53.909421,69.986648 C 35.059946,43.624097 33.016007,40.845456 23.68757,28.901406 l -5.448775,-6.976562 28.927089,0.06509 28.927089,0.06509 1.492357,3.455738 c 1.651397,3.824024 3.956701,8.519772 5.340962,10.879173 1.476129,2.515992 17.279498,26.238005 17.479498,26.238005 0.2344,0 15.21662,-22.972887 17.48669,-26.813081 2.01494,-3.408603 4.47539,-8.247834 5.82468,-11.45601 l 0.96894,-2.303825 28.66736,-0.0651 28.66738,-0.06509 -3.62894,4.54656 c -6.9979,8.76736 -14.56239,19.092621 -32.25465,44.026537 l -17.84465,25.148675 19.24015,27.199344 c 26.24199,37.09769 26.31934,37.20384 35.72411,49.02169 l 4.94,6.20753 -29.6413,0 -29.64132,0 -2.85598,-5.69556 c -1.5708,-3.13256 -3.96972,-7.59426 -5.33093,-9.91489 -2.82828,-4.82171 -20.30513,-32.00193 -20.57719,-32.00193 -0.279658,0 -18.251751,28.32535 -20.746141,32.69748 -1.223663,2.14484 -3.462221,6.37811 -4.974566,9.40729 l -2.749725,5.50761 -29.938284,0 -29.938284,0 2.148309,-2.4958 z"]
    attrs: {fill: "#000000", stroke: "#000000"}
  }
  o: {
    method: "path"
    args: ["M 96.813156,183.95918 C 87.104272,183.75076 77.273867,182.15168 68.713869,179.38836 39.682109,170.01638 20.890031,146.83244 16.510767,114.98497 15.534677,107.88653 15.260058,97.642452 15.853805,90.478288 18.026264,64.265258 29.308833,43.400264 48.313019,30.451046 63.62602,20.016956 82.320217,15.282133 104.96065,16.103464 c 19.98319,0.724931 37.73591,6.807117 51.25874,17.561529 2.96764,2.360094 8.73188,8.156518 11.12222,11.184309 9.61986,12.185305 15.32702,27.468485 16.84741,45.115753 0.35597,4.131793 0.35881,14.387735 0.005,18.347945 -2.07812,23.26547 -11.25734,42.54103 -26.56332,55.78066 -15.78042,13.65005 -36.41275,20.3894 -60.817621,19.86552 z m 9.238114,-39.18777 c 14.03831,-2.16731 23.31318,-11.53074 27.33847,-27.59949 1.99503,-7.96408 2.37363,-21.209888 0.862,-30.15793 C 131.42142,70.260052 122.86211,59.074235 110.1571,55.525678 104.17023,53.853522 95.976955,53.86919 89.935765,55.56435 82.573048,57.630333 76.56174,61.987072 72.287471,68.355086 c -2.219007,3.305983 -3.552329,6.086524 -4.988438,10.403002 -2.29476,6.897304 -3.066335,12.942575 -2.871491,22.498002 0.08533,4.18442 0.286308,7.51514 0.557452,9.23813 3.137391,19.93664 12.904894,31.52512 28.877091,34.26071 2.608902,0.44682 9.342725,0.45593 12.189185,0.0164 z"]
    attrs: {fill: "#cb4437", stroke: "#cb4437"}
  }
  box: {
    method: "rect"
    args: [0, 0, 200, 200]
    attrs: {fill: "#ffffff", stroke: "#aaaaaa"}
  }
}

noughts.assets.get = (canvas) ->
  result = {}

  # Draw an asset onto the canvas. The optional "attrs" and "transformation"
  # parameters specify attributes and transformations to apply to the asset.
  result.draw = (name, attrs, transformation) ->
    asset = assets[name]
    unless asset?
      throw "Invalid asset name: #{name}"
    attrs ||= {}
    element = canvas[asset.method].apply(canvas, asset.args)
    for key,value of asset.attrs
      element.attr(key, value)
    for key,value of attrs
      element.attr(key, value)
    if transformation?
      element.transform(transformation)
    return element

  # Draw the provided asset at the specified (x,y) coordinates. The optional
  # "attrs" parameter specifies attributes to apply to the asset.
  result.drawAt = (name, x, y, attrs) ->
    return result.draw(name, attrs, "t#{x},#{y}")

  return result

# Make Emacs not wrap lines in this file.
# Local Variables:
# truncate-lines: t
# End: