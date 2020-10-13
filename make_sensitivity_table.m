function make_sensitivity_table(F,H);
%Usage: make_sensitivity_table(F,H);
% Create a sensor sensitivity table in one degree increments -90<elev<90,-180<azim<180
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
%TEST values:
% F=[0:0.1:1];
% H=[ones(1,fix(length(F)/2)) zeros(1,length(F)-fix(length(F)/2))];

if nargin < 2,
    fprintf('Format: make_sensitivity_table(F,H);\n');
    return;
end;

deg2rad=pi./180;
e_index=0;
for elev=-90:90,
    elev=elev.*deg2rad;
    e_index=e_index+1;
    a_index=0;
    for azim = -180:180,
        azim=azim.*deg2rad;
        a_index=a_index+1;
        S3D{e_index,a_index}=make_sensor_ir(elev,azim,H,F); % Put the impulse response for this elevation and azimuth in a cell. 
        % In impulse response, time runs down the column vector.
    end;
end;
save sensor_sensitivity.mat S3D; % Save S3D in a .mat file
