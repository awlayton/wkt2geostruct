function [ wkts ] = geostruct2wkt(geostructs, geocoords)
% GEOSTRUCT2WKT convert geostruct(s) to Well-known text (WKT) string(s)
%   WKT = GEOSTRUCT2WKT(GEOSTRUCTS) returns a cell array of WKT strings S,
%   of the same dimensions as GEOSTRUCTS. GEOSTRUCTS is an array of
%   geostructs.
%
%   WKT = GEOSTRUCT2WKT(STRUCTS,GEOCOORDS) if GEOCOORDS is false,
%   then STRUCTS should be an array of mapstructs instead of geostructs.
%
%   Well-known text: http://en.wikipedia.org/wiki/Well-known_text
%
%   Supported shape types
%   ---------------------
%   GEOSTRUCT2WKT only supports a subset of the WKT format.
%   Only 2 dimensional geometries without a linear reference are supported.
%   The supported types are:
%    * Point
%    * LineString
%    * Polygon
%    * MultiPoint
%    * MultiLineString
%
% SEE ALSO GEOSHOW, WKT2GEOSTRUCT

% Alex Layton 6/23/2014
% alex@layton.in

narginchk(1, 2);
if nargin < 2
	geocoords = true;
end

% Set coordinate system
if geocoords
    cf1 = 'Lon';
    cf2 = 'Lat';
else
    cf1 = 'X';
    cf2 = 'Y';
end

% Iniialize output
wkts = cell(size(geostructs));
% Loop through geostructs
parfor I = 1:numel(geostructs)
	geometry = geostructs(I).Geometry;
	opening = '';
	closing = '';
	points = [geostructs(I).(cf1)(:), geostructs(I).(cf2)(:)];

	switch geometry(4)
		case {'n', 't'} % {Point, MultiPoint}
			% Remove NaN's
			points = points(~any(isnan(points)'),:);

			% MATLAB is pretty lax about Point vs MultiPoint
			if size(points, 1) > 1
				geometry = 'MULTIPOINT';
			else
				geometry = 'POINT';
			end

		case 'e' % Line
			% MATLAB treats LineString and MultiLineString both as Line
			if sum(isnan(points(:))) > 0
				geometry = 'MULTILINESTRING';
				opening = '(';
				closing = ')';
			else
				geometry = 'LINESTRING';
			end

		case 'y' % Polygon
			% TODO: Implement MultiPolygon
			geometry = 'POLYGON';
			opening = '(';
			closing = ')';
	end

	% Split on NaN's
	lens = diff([0, find(isnan(points(:,1))), length(points(:,1))+1]) - 1;
	lens = [lens; ones(size(lens))];
	points = mat2cell(points, lens(1:end-1), 2);
	% Flip CW and CCW
	points = cellfun(@(c) flipdim(c, 1), points, 'UniformOutput', false);
	% Put back together
	points = vertcat(points{:});

	% Finagle mat2str output into what we want
	points = mat2str(points);
	points = strrep(points, '[', '(');
	points = strrep(points, ']', ')');
	points = strrep(points, ';', ', ');
	points = regexprep(points, '(, NaN NaN, )+', '), (');

	% Construct WKT string
	wkts{I} = [geometry ' ' opening points closing];
end

end

