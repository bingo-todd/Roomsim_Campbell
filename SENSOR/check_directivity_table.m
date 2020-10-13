% check_directivity_table;
%Script to check a sensor directivity pattern
% This script reads a directivity cell array and plots
% The directivity pattern using polar plots.
% The pattern can be displayed with an angular offset from the sensor axis.
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

%***************************

clear all;
deg2rad=pi/180;
rad2deg=180/pi;

repeat=true;
while repeat,
    repeat=false; % Do once if correct filename and ext given
    beep;
    [name path] = uigetfile('sensor_directivity.mat', 'Get a sensor directivity data file'); %Display the dialogue box
    if ~any(name), 
        return; % **Alternate return for cancel operation. No data read from file.
    end;
    filename = [path name]; % Form full filename as path+name
    [pathstr,name,ext,versn] = fileparts(filename);
    if ~strcmpi(lower(ext),'.mat'),
        h=errordlg('You must specify a .mat extension ','Error in check_sensitivity');
        beep;
        uiwait(h);
        repeat=true;
    end;
end; % of while loop to trap non .mat files

load(filename, 'S3D');
SS3D=cell2mat(S3D);

%--------------------------------------------

for azim = -180:180, % All possible source azimuths
    a_index=azim+181; % 1<= a_index <=361
    for elev=-90:90, % All necessary source elevations
        e_index=elev+91; % 1<= e_index <=181
        imp_read(e_index,a_index)=max(SS3D(e_index,a_index,:)); % Extract directivity data for display
%         [sensor_ir]=getSENSORpulse(azim*deg2rad,elev*deg2rad,S3D); % Used to check getSENSORpulse is reading OK
    end;
end;

figure(1);
alpha=[-180:180]; beta=[-90:90];
imagesc(alpha,beta,imp_read); % Display the sensor directivity matrix in sensor axes
axis image;
axis xy;
colorbar;
title('Sensor directivity in sensor axes');
xlabel('Azimuth (deg)');
ylabel('Elevation (deg)');
%-------------------------------------------
% ***** Prompt for Elevation and Azimuth slices to use for polar plot ****
prefix='man_inp__directivity slice: ';
error_title=[prefix ' Error'];
answer={};
while isempty(answer),
    beep;
    %Declare and clear slice polar coordinates
    azim_slice=[]; elev_slice=[];

    banner = 'Sensor directivity: polar plot inputs';
    prompt = {'Enter azimuth for slice (-180<deg<180) :'...
        ,'Enter elevation for slice (-90<deg<90) :'};
    lines = 1;
    def = {'0','0'}; %Default values
    beep;

    answer = inputdlg(prompt,banner,lines,def,'on');
    if ~isempty(answer),% Trap CANCEL button operation
        azim_slice=str2num(answer{1});
        elev_slice=str2num(answer{2});
    else
        h=errordlg('Sensor slice plot: data input cancelled. ',error_title);
        beep;
        uiwait(h); % Wait for user response
        answer={}; % Clear answer flag for test on return
    end;
    if (abs(azim_slice) > 180) | (abs(elev_slice)) >90, % Trap out of range values
        h=errordlg('Sensor slice plot: data input out of range. ',error_title);
        beep;
        uiwait(h); % Wait for user response
        answer={}; % Clear answer flag for test on return
    end;
end; %end while
%-------------------------------------------------------------------------
% Create polar plotting coordinates beta and alpha (deg)
beta=[-90:90];
alpha=[-180:180];
% Display polar plots of the sensor directivity in sensor axes
figure(2);

subplot(2,1,1);
% Polar plot of sensor elevational directivity -180deg to +180deg at a chosen azimuth
el_title=['Elevational response for azimuth plane = ' num2str(azim_slice) ' deg'];
% Plot the directivity from -90 deg to + 90 deg at azimuth (front)
polar(beta'.*deg2rad,imp_read(round(beta+91),azim_slice+181),'r'); 
hold on;
% Plot the directivity from 90 deg to -90 deg at azimuth (back)
polar((beta'+180).*deg2rad,imp_read(round(beta+91),azim_slice+1),'r'); 
hold off;
title(el_title);

subplot(2,1,2);
% Polar plot of sensor azimuthal directivity -180deg to +180deg at a chosen elevation
az_title=['Azimuthal response for elevation plane = ' num2str(elev_slice) ' deg'];
polar(alpha.*deg2rad,imp_read(elev_slice+91,round(alpha+181)),'r');
title(az_title);

% End of check_directivity_table.m
