function [geostruct] = wkt2geostruct(wkts, geocoords)
% WKT2GEOSTRUCT convert Well-known text (WKT) string(s) to geostructs
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
%	'Point', 'LineString', 'Polygon', and 'MultiPoint' types are supported.
%
% SEE ALSO GEOSHOW

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
% points = strrep(regexprep(points, ', *', ';'), ');(', '; NaN NaN;');
points = regexprep(points, ', *', ';');
points = regexp(points, ');(', 'split');

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
geostruct = struct('Geometry', c, cf1, c, cf2, c, 'BoundingBox', c);
clear c;
% Loop through all the WKTs
parfor I = 1:numel(shapes)
	% Make Lat and Lon into numbers
	% Use flipdim to change CW to CCW and vise versa
	nums = cellfun(@(c) [flipdim(str2num(c), 1); NaN NaN], points{I}, ...
			'UniformOutput', false);
	% Put nums into matrix form [Lon, Lat]
	nums = vertcat(nums{:});
	% Put them into the struct
	geostruct(I).(cf1) = nums(:, 1);
	geostruct(I).(cf2) = nums(:, 2);

	% MATLAB is very picky about the capitalization of Geometry
	s = 1;
	geostruct(I).Geometry = lower(shapes(I).geometry);
	geostruct(I).Geometry(1) = upper(geostruct(I).Geometry(1));
	if geostruct(I).Geometry(1) == 'M'
		geostruct(I).Geometry(6) = upper(geostruct(I).Geometry(6));
		s = s + 5;
	end
	% Remove word string after line
	if geostruct(I).Geometry(s) == 'L'
		geostruct(I).Geometry = geostruct(I).Geometry(1:s+3);
	end

	% Calculate bounding box
	geostruct(I).BoundingBox = ...
			[min(geostruct(I).(cf1)) min(geostruct(I).(cf2)); ...
			max(geostruct(I).(cf1)) max(geostruct(I).(cf2))];
end

end

