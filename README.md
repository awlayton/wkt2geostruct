wkt2geostruct
-------------
*wkt2geostruct* converts geometries in the [well-known text (WKT)][wkt] markup
language to geostructs (or mapstructs). The structs it creates are the type
used/created by functions from the Mapping Toolbox.
[wkt]: http://en.wikipedia.org/wiki/Well-known_text "well-known text"

Supported shape types
---------------------
*wkt2geostruct* only supports a subset of the WKT format. Only 2 dimensional
geometries without a linear reference are supported.

The supported geometry types are:

* Point
* LineString
* Polygon
* MultiPoint
* MultiLineString
* MultiPolygon

