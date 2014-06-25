function [ geostructs ] = wkt2geostruct(wkts, geocoords)
% WKT2GEOSTRUCT convert Well-known text (WKT) string(s) to geostruct(s)
%	S = WKT2GEOSTRUCT(WKTS) returns a geostruct array S,
%	of the same dimensions as WKTS. WKTS may be a single string,
%	or it may be a cell array of strings.
%
%	S = WKT2GEOSTRUCT(WKTS,GEOCOORDS) if GEOCOORDS is false,
%	returns a mapstruct instead of a geostruct.
%
%	Well-known text: http://en.wikipedia.org/wiki/Well-known_text
%
%	Supported shape types
%	---------------------
%	WKT2GEOSTRUCT only supports a subset of the WKT format.
%	Only 2 dimensional geometries without a linear reference are supported.
%	The supported types are:
%	 * Point
%	 * LineString
%	 * Polygon
%	 * MultiPoint
%	 * MultiLineString
%	 * MultiPolygon
%
% SEE ALSO GEOSHOW, GEOSTRUCT2WKT

% Alex Layton 10/30/2013
% alex@layton.in

% Check inputs
narginchk(1, 2);
if nargin < 2
	geocoords = true;
end

% Split out the geometry type and its points
shapes = regexp(wkts, '^(?<geometry>\w+) *\(+(?<points>.*[^)])\)+$', 'names');
% I want a structure array, not cells with structures in them
if iscell(shapes)
	shapes = cell2mat(shapes);
end

% Crafty stuff to trick str2num into parsing the WKT
% First make commas colons so that Lat and Lon are separate columns
% Then separate groups of points by NaNs
points = {shapes.points};
points = reshape(points, size(shapes));
points = regexprep(points, ', *', ';');
points = regexp(points, '\)+;\(+', 'split');

% Set coordinate system
if geocoords
	cf1 = 'Lon';
	cf2 = 'Lat';
else
	cf1 = 'X';
	cf2 = 'Y';
end

% Initialize loop output
c = cell(size(shapes));
geostructs = struct('Geometry', c, cf1, c, cf2, c, 'BoundingBox', c);
clear c;
% Loop through all the WKTs
parfor I = 1:numel(shapes)
	% Make Lat and Lon into numbers
	nums = cellfun(@(c) [str2num(c); NaN NaN], points{I}, ...
			'UniformOutput', false);
	% MATLAB wants CW polygons
	if mean(cellfun(@(c) ispolycw(c(:, 1), c(:, 2)), nums)) < 0.5
		% Change CW to CCW and vise versa
		nums = cellfun(@(c) [c(end-1:-1:1, :); c(end, :)], nums);
	end
	% Put nums into matrix form [Lon, Lat]
	nums = vertcat(nums{:});
	% Remove trailing NaN's
	nums = nums(1:end-1,:);
	% Put them into the struct
	geostructs(I).(cf1) = nums(:, 1);
	geostructs(I).(cf2) = nums(:, 2);

	% MATLAB is very picky about the capitalization of Geometry
	geostructs(I).Geometry = lower(shapes(I).geometry);
	geostructs(I).Geometry(1) = upper(geostructs(I).Geometry(1));
	% Multipoint => MultiPoint
	% Multilinestring => Linestring
	% Multipolygon => Polygon
	if geostructs(I).Geometry(1) == 'M'
		geostructs(I).Geometry(6) = upper(geostructs(I).Geometry(6));
		if geostructs(I).Geometry(8) ~= 'i' % MultiPoint
			geostructs(I).Geometry = geostructs(I).Geometry(6:end);
		end
	end
	% Remove word string after line
	% Linestring => Line
	if geostructs(I).Geometry(1) == 'L'
		geostructs(I).Geometry = geostructs(I).Geometry(1:4);
	end

	% Calculate bounding box
	geostructs(I).BoundingBox = ...
			[min(geostructs(I).(cf1)) min(geostructs(I).(cf2)); ...
			max(geostructs(I).(cf1)) max(geostructs(I).(cf2))];
end

end

