function [geostruct] = wkt2geostruct(wkts)

% Split out the geometry type and its points
shapes = regexp(wkts, '^(?<geometry>\w+)\(+(?<points>.*[^)])\)+$', 'names');
% I want a structure array, not cells with structures in them
shapes = [shapes{:}];

% Crafty stuff to trick str2num into parsing the WKT
% First make commas colons so that Lat and Lon are separate columns
% Then separate groups of points by NaNs
points = strrep(strrep({shapes.points}, ',', ';'), ');(', '; NaN NaN;');

% Initialize loop output
c = cell(length(shapes), 1);
geostruct = struct('Geometry', c, 'Lon', c, 'Lat', c, 'BoundingBox', c);
% Loop through all the WKTs
parfor I = 1:length(shapes)
	% Make Lat and Lon into numbers
	nums = str2num(points{I});
	% Put them into the struct
	geostruct(I).Lon = nums(:, 1);
	geostruct(I).Lat = nums(:, 2);

	% MATLAB is very picky about the capitalization of Geometry
	geostruct(I).Geometry = lower(shapes(I).geometry);
	geostruct(I).Geometry(1) = upper(geostruct(I).Geometry(1));

	% Calculate bounding box
	geostruct(I).BoundingBox = [min(geostruct(I).Lon) min(geostruct(I).Lat); ...
		max(geostruct(I).Lon) max(geostruct(I).Lat)];
end

end

