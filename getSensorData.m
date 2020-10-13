function [azim_off, elev_off, roll_off, S3D]=getSensorData(S,SENSOR_path);
%Usage: [azim_off, elev_off, roll_off, S3D]=getSensorData(S,SENSOR_path); 
%Change to directory SENSOR_path, read sensor directionality and sensor directivity data,
% and change back to path at entry.
%------------------------------------------------------------------
% Copyright (C) 2003  Douglas R Campbell
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% along with this program in the MATLAB file roomsim_licence.m ; if not,
% 
% You should have received a copy of the GNU General Public License
%  write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
%----------------------------------------------------------------------
% Functions called:

%*** Global Declarations ***
global LOG_FID; % Identifier of logfile. Loaded in roomsim.m

%***************************
error_title='getSensorData error';

% Declare arrays for angular offsets
azim_off=[];
elev_off=[];
roll_off=[];

S3D={}; % Declare cell array for loading sensor data
                        
save_path=pwd; % Save pathname to present directory (folder)                       
cd(SENSOR_path); % Change directory to the sensor types directory (folder)                      

banner= ['Select a sensor data file for ' S];
repeat=true;
while repeat,
    repeat=false; % Do once if filename and ext accepted
    beep;
    [name path] = uigetfile('omnidirectional.mat', banner); %Display the dialogue box, omnidirectional is default.
    if ~any(name),
        cd(save_path); % Restore the previous directory (folder) path                 
        return; % **Alternate return for cancel operation. No data read from file.
    end;
    filename = [path name]; % Form full filename as path+name
    [pathstr,name,ext,versn] = fileparts(filename);
    if ~strcmpi(lower(ext),'.mat'),
        h=errordlg('You must specify a .mat extension ',error_title);
        beep;
        uiwait(h);
        repeat=true;
    end;
end; % of while loop to trap non .mat files

%------Get the sensor offsets and check they're sensible ----------------
if strcmpi(lower(name),'omnidirectional'),
    azim_off=0;
    elev_off=0;
    roll_off=0;
else,
    out_of_range = true;
    while out_of_range, %Loop if sensor offset data is not sensible
        answer={};
        banner = 'Sensor offset from receiver axes system';
        prompt = {'Enter -180< azimuth offset <180 deg:'...
                ,'Enter -90< elevation offset <90 deg:'...
                ,'Enter -180< roll offset <180 deg:'};
        lines = 1;
        def = {'0','0','0'}; %Default values for x axis look direction
        beep;
        answer = inputdlg(prompt,banner,lines,def,'on');
        if isempty(answer),
            cd(save_path); % Restore the previous directory (folder) path                  
            return;% Close window or CANCEL button operated
        end;  
        
        azim_off=str2num(answer{1});
        elev_off=str2num(answer{2});
        roll_off=str2num(answer{3});
        
        % Check values within range
        if azim_off < -180 || azim_off > 180,
            message='-180< Sensor azimuth offset <180 deg';
        elseif elev_off < -90 || elev_off > 90,
            message='-90< Sensor elevation offset <90 deg';
        elseif roll_off < -180 || roll_off > 180,
            message='-180< Sensor roll offset <180 deg';
        else,
            out_of_range = false; % Input accepted
        end;
        
        if out_of_range  
            banner='Re-enter value';
            h=msgbox(message,banner,'warn');  %Warn & beep.
            beep;
            uiwait(h);% Wait for user to acknowledge
            answer={};
        end;
    end; % Of WHILE loop checking out of range
end;

%----- Load into workspace the cell array S3D containing the sensor impulse response
load(filename, 'S3D'); % Load the SENSOR data file into the workspace cell array S3D

fprintf(LOG_FID,'\n\n Sensor directivity file =  %s ',filename); % Print sensor file to the log file
cd(save_path); % Restore the previous directory (folder) path                  

%------------------ End of getSensorData.m --------------------