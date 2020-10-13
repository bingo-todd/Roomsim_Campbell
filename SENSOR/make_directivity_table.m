function make_directivity_table(F,H);
%Usage: make_directivity_table(F,H);
% Create a sensor directivity table in one degree increments -90<elev<90,-180<azim<180
%
% N.B. Uncomment the desired sensor code in make_sensor_ir.m before running make_directivity_table.m
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
%Functions called: make_sensor_ir.m

F=1;
H=1; %Flat 0 dB sensor gain with frequency

%TEST values: LP response cutting off at 1/4 sampling.
% F=[0:0.1:1];
% H=[ones(1,fix(length(F)/2)) zeros(1,length(F)-fix(length(F)/2))];

if nargin < 2,
    fprintf('Format: make_directivity_table(F,H);\n');
    return;
end;

a_index=0;
for azim = -180:180,  % for all possible azimuths
    a_index=azim+181;
    e_index=0;
    for elev = -90:90, % for all necessary elevations
        e_index=elev+91;
        S3D{e_index,a_index}= make_sensor_ir(elev,azim,H,F); % Put the impulse response for this elevation and azimuth in a cell.
        % In impulse response, time runs down the column vector.
    end;
end;

save sensor_directivity.mat S3D; % Save S3D in a .mat file (NB Give it a descriptive name later)
% End of make_directivity_table.m
