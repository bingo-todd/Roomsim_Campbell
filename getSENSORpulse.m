function [sensor_ir]=getSENSORpulse(azim,elev,S3D);
%Usage: [sensor_ir]=getSENSORpulse(azim,elev,S3D);
% Retrieves from S3D (a cell array), the impulse response sensor_ir (a column vector)
% that is closest (rounded to nearest degree) to the specified -pi/2<elevation<pi/2 and -pi<azimuth<pi (rad)
%----------------------------------------------------------------------------- 
% 
% Copyright (C) 2003  Douglas R Campbell
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program in the MATLAB file roomsim_licence.m ; if not,
%  write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
%-----------------------------------------------------------------------------------
%Functions called: 

%*** Global Declarations ***
global rad2deg; % Conversion factor radians to degrees
%***************************

if nargin < 3,
    fprintf('Format: [sensor_ir]=getSENSORpulse(azim,elev,S3D)\n');
    return;
end;

% -pi >= azimuth >= pi rads, -pi/2 >= elevation >= pi/2 rads
% Round to nearest degree and add half range address offset
a_index=round(azim.*rad2deg)+181; 
e_index=round(elev.*rad2deg)+91;
sensor_ir=S3D{e_index,a_index}; % Get the impulse response for this elevation and azimuth from a cell.

%------------------ End of getSENSORpulse.m -------------------------------