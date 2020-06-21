function [hrir_L_R] = getNearestMITpulse(elevation,azimuth,H3D);
%Usage: [hrir_L_R] = getNearestMITpulse(elevation,azimuth,H3D);
%Retrieves from H3D, the impulse response (a cell array) that is closest to
%the specified elevation and azimuth. On entry angles are converted from
%radians to deg. NB Saturates at elevations < -40 irrespective of azimuth.
%--------------------------------------------------------------------------
% Acknowledgement: This function is a modification of code published by the
% MIT Media Lab.
%--------------------------------------------------------------------------
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

if nargin < 3
    fprintf('Format: [hrir_L_R, azerr, elerr] = getNearestMITpulse(azimuth,elevation,H3D)\n');
    return;
end

elevation=rad2deg.*elevation; % Convert radians to degrees
azimuth=rad2deg.*azimuth;

elevations = [-40 -30 -20 -10  0 10 20 30 40 50 60 70 80 90;
	           56  60  72  72 72 72 72 60 56 45 36 24 12  1]; 
% Find the index el of the value within elevations which is the minimum distance from elevation
[elerr el]=min(abs(elevations(1,:)-elevation));

%Quantize azimuth
if azimuth < 0 
  azimuth=360+azimuth;
end

azim_incr = 360./elevations(2,el);
azimuths = round([0:azim_incr:360-azim_incr]);
% Find the index az of the value within azimuths which is the minimum distance from azimuth
[azerr az]=min(abs(azimuths-azimuth));

hrir_L_R = H3D{el,az}; % Extract the required hrir L&R pair (Left is first column ie hrir_L_R(:,1) )
%--------------------- End of getNearestMITpulse.m -----------------------------
