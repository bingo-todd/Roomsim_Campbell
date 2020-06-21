function [Fs,humidity,temperature,order,H_length,H_filename,air_F,smooth_F,Fc_HP,plot_F2,plot_F3,dist_F,alpha_F...
         ,c,room_size,receiver_xyz,receiver_off,receiver,sensor_space,sensor_off,S_No,source_polar,F_abs,A]=excel_setup(filename);
%Usage: [Fs,humidity,temperature,order,H_length,H_filename,air_F,smooth_F,HPass_F,plot_F2,plot_F3,dist_F,alpha_F...
%    ,c,room_size,receiver_xyz,receiver,sensor_space,sensor_dir,S_No,source_polar,F_abs,A]=excel_setup(filename);
% EXCEL_SETUP.M reads the Excel spreadsheet file SETUP.XLS to obtain values for setting up roomsim.
% It calls GetExcelSetup.m, a version of the standard Matlab XLSREAD.M function modified to handle only text data
%   and to allow compilation to stand-alone code.
%---------------------------------------------------------------------------- 
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
% 
% You should have received a copy of the GNU General Public License
% along with this program in the MATLAB file roomsim_licence.m ; if not,
%  write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
%---------------------------------------------------------------------------------
% Functions called: getExcelSetup.m,

%*** Globals ***
global hrir_l hrir_r; % Globals for CIPIC impulse responses left and right
global H3D; % Global for MIT impulse response data
global S3D_L S3D_R; % SENSOR impulse response data for Left (or single) and Right sensor. 
%***************

sensor_off=[]; % Declare empty array
sensor_dir=[]; % Declare empty array
error_title='excel_setup: Error';

%------------- Get the setup data from an Excel spreadsheet -----------------------
[param_num, param_text] = getExcelSetup(filename,'single values'); % Various single item setup parameters
sources_num = getExcelSetup(filename,'sources'); % Sound source position(s) relative to receiver reference point (Head or sensor(s)).
[dir_num, dir_text]= getExcelSetup(filename,'sensor dir'); % Sensor directivity
abs_num = getExcelSetup(filename,'surface absorption'); % Absorption of the room surfaces

%------------- Check the setup data from Excel spreadsheet -----------------------
kRow=2;
while ~isnan(sources_num(kRow,2)), % Find the number of sources
    kRow=kRow+1;
end;
sources_num=sources_num(2:kRow-1,2:4); % Compact the sources data array
if isempty(sources_num)||any(any(isnan(sources_num)))
    h=errordlg(['Empty or Non-Number in ' filename '\sources data, exiting from excel_setup'],error_title);
    beep;
    uiwait(h);
    return;
end;

dir_num=dir_num(2:4,2:3); % Compact the directivity data array
if isempty(dir_num)||any(any(isnan(dir_num)))
    h=errordlg(['Empty or Non-Number in ' filename '\surface absorption data, exiting from excel_setup'],error_title);
    beep;
    uiwait(h);
    return;
end;

abs_num=abs_num(2:8,2:7); % Compact the absorption data array
if isempty(abs_num)||any(any(isnan(abs_num)))
    h=errordlg(['Empty or Non-Number in ' filename '\surface absorption data, exiting from excel_setup'],error_title);
    beep;
    uiwait(h);
    return;
end;

%----------------------- Simulation control parameters ------------------------------
Fs=param_num(2,2); % Sampling frequency (Hz)
humidity=param_num(3,2); % Relative humidity of air (%) (Used to calculate air absorption coefficient "m", valid range 20%< h <70%)
temperature=param_num(4,2); % Temperature of air (deg C) (Used to calculate speed of sound (m/s))
order=param_num(5,2); % If -ve then value computed in make_Roomsim is used, else value supplied here is used (limits order of reflections computed)
H_length=param_num(6,2); % If -ve then H_length is later set = RT60, else value supplied here is used.
H_filename=param_text{7,2}; %Output filename for impulse response.

%--------------------------------------- Flags etc. ---------------------------------------
air_F=logical(param_num(8,2)); % false = no absorption due to air, true = air absorption is present.
dist_F=logical(param_num(9,2)); % false = no distance effect, true = 1/R attenuation with distance applied.
Fc_HP = param_num(10,2); %0 = no High-Pass filter applied, scalar value cut-off frequency = High-Pass filter applied.
smooth_F=logical(param_num(11,2)); %false = no smoothing filter applied, true = smoothing filter used.
plot_F2=logical(param_num(12,2)); % false = no plot, true = 2D-plan, shows image rooms on xy plane.
plot_F3=logical(param_num(13,2)); % false = no plot, true = 3D-plot, rotatable.
alpha_F=logical(param_num(14,2)); % false = fixed transparent surfaces for Room Geometry plot, true = (surface opacity = reflectivity)

%--------- Room dimensionss --------------
Lx=param_num(15,2); % Height
Ly=param_num(16,2); % Width
Lz=param_num(17,2); % Length

% Receiver reference point [xp,yp,zp](m), if Head, it is mid-point of the inter_aural axis
xp=param_num(18,2); % x coordinate of receiver reference point
yp=param_num(19,2); % y coordinate of receiver reference point
zp=param_num(20,2);% z e.g. Typical height above floor of ears of seated human subject = 1.2 m

% Sensor details
receiver=param_text{21,2}; % Receiver type: one-mic, two_mic, mithrir, cipicir
sensor_space=param_num(22,2); % Sensor separation (if head it is implicit in the HRIR data)

%-------------- Identify path to filename for extraction of hrir from MIT Kemar data base -------------
MIT_root=param_text{23,2}; % Root directory of the MIT Kemar data, an immediate sub-directory of the Roomsim directory
MIT_subdir1=param_text{24,2};
MIT_subdir2=param_text{25,2};
MIT_filename=param_text{26,2};

%-------------- Identify path to filename for extraction of hrir from CIPIC data base -----------------
CIPIC_root=param_text{27,2}; % Root directory of the CIPIC HRTF data, an immediate sub-directory of the Roomsim directory
CIPIC_subdir1=param_text{28,2};
CIPIC_subdir2=param_text{29,2};
S_No=param_text{30,2}; % CIPIC subject number, format '&&&' (e.g. '021' Kemar with small pinnae)
CIPIC_filename=param_text{31,2};

%--------- Receiver orientation in room axes --------------------
receiver_off(1)=param_num(32,2); % yaw offset of receiver
receiver_off(2)=param_num(33,2); % pitch offset of receiver
receiver_off(3)=param_num(34,2); % roll offset of receiver

%------------- Pack up sensor data ------------
S3D_L={}; S3D_R={}; % Declare cell arrays for sensor impulse responses
switch receiver % Selection of sensor type 
    case {'one_mic'}, % Get sensor directionality and impulse response
        % Pack up sensor directionality as a column vector
        sensor_off=dir_num(1:3,1);
        
        %-------------- Identify path to filename for extraction of hrir from SENSOR data base -------------
        SENSOR_root=dir_text{5,2}; % Root directory of SENSOR Type data, an immediate sub-directory of the Roomsim directory
        SENSOR_subdir1=dir_text{6,2};
        SENSOR_filename=dir_text{7,2};
        SENSOR_file = fullfile(SENSOR_root,SENSOR_subdir1,SENSOR_filename); %Form pathname to SENSOR data file
        if (exist(SENSOR_file,'file')==2), % Check SENSOR file is installed
            load(SENSOR_file, 'S3D'); % Load the SENSOR data file into the workspace and create S3D.
            S3D_L=S3D; % Copy cell array for sensor impulse responses
            clear S3D; % Free up memory
        else
            h=errordlg([SENSOR_file '  NOT FOUND, exiting from excel_setup'],error_title);
            beep;
            uiwait(h);
            return;
        end
        
    case {'two_mic'},  % Get sensor directionality [Left Right] and impulse responses
        % Pack up sensor directionality one column per sensor
        sensor_off=dir_num(1:3,1:2);
        
        % Identify path to filename for extraction of impulse response from Left sensor data base
        SENSOR_root=dir_text{5,2}; % Root directory of the SENSOR Type data, an immediate sub-directory of the Roomsim directory
        SENSOR_subdir1=dir_text{6,2};
        SENSOR_filename=dir_text{7,2};
        SENSOR_file = fullfile(SENSOR_root,SENSOR_subdir1,SENSOR_filename); %Form pathname to SENSOR data file
        if (exist(SENSOR_file,'file')==2), % Check SENSOR file is installed
            load(SENSOR_file,'S3D'); % Load the SENSOR data file into the workspace and create S3D.
            S3D_L=S3D; % Copy cell array for Left sensor impulse responses
            clear S3D; % Free up memory
        else
            h=errordlg([SENSOR_file '  NOT FOUND, exiting from excel_setup'],error_title);
            beep;
            uiwait(h);
            return;
        end
        % Identify path to filename for extraction of impulse response from Right sensor data base
        SENSOR_root=dir_text{5,3}; % Root directory of the SENSOR Type data, an immediate sub-directory of the Roomsim directory
        SENSOR_subdir1=dir_text{6,3};
        SENSOR_filename=dir_text{7,3};
        SENSOR_file = fullfile(SENSOR_root,SENSOR_subdir1,SENSOR_filename); %Form pathname to SENSOR data file
        if (exist(SENSOR_file,'file')==2), % Check SENSOR file is installed
            load(SENSOR_file,'S3D'); % Load the SENSOR data file into the workspace and create S3D.
            S3D_R=S3D; % Copy cell array for Right sensor impulse responses
            clear S3D; % Free up memory
        else
            h=errordlg([SENSOR_file '  NOT FOUND, exiting from excel_setup'],error_title);
            beep;
            uiwait(h);
            return;
        end
        
    case {'mithrir'} % Extract hrir from MIT Kemar data base
        MIT_file = fullfile(MIT_root,MIT_subdir1,MIT_subdir2,MIT_filename); %Form pathname to MIT Kemar data file
        if (exist(MIT_file,'file')==2), % Check MIT file is installed
            load(MIT_file); % Load the MIT Kemar data file into the workspace (creates H3D)
        else
            h=errordlg([MIT_file '  NOT FOUND, exiting from excel_setup'],error_title);
            beep;
            uiwait(h);
            return;
        end
        
    case {'cipicir'} % Extract hrir from CIPIC data base
        CIPIC_file = fullfile(CIPIC_root,CIPIC_subdir1,[CIPIC_subdir2 S_No],CIPIC_filename); %Form pathname to subject data file
        if (exist(CIPIC_file,'file')==2), % Check selected subject file is installed
            load(CIPIC_file); % Load the subject file into the workspace (loads hrir_l and hrir_r)
        else
            h=errordlg([CIPIC_file '  NOT FOUND, check Subject No ' S_No 'is installed.'],error_title);
            beep;
            uiwait(h);
            S_No=-1;
            return;
        end;
end

%---------------- Pack up the room surface absorptions ----------------------

    F_abs = abs_num(1,1:6);
    % Ax1 Absorption of wall in x=0 plane (behind Kemar in plan)
    % Ax2 Absorption of wall in x=Lx plane (front in plan)
    % Ay1 Absorption of wall in y=0 plane (right in plan)
    % Ay2 Absorption of wall in y=Ly plane (left in plan)
    % Az1 Absorption of floor i.e. z=0 plane
    % Az2 Absorption of ceiling i.e. z=Lz plane
    % Pack up column vectors (NB Transposition) of absorption coefficients in array A
    A=abs_num(2:7,1:6)'; % [Ax1;Ax2;Ay1;Ay2;Az1;Az2]
%---------------- End of surface absorption set up ---------------

% Pack various parameters for the room simulation
room_size=[Lx;Ly;Lz]; % Pack up room dimensions into column vector.
receiver_xyz=[xp;yp;zp]; % Pack up receiver (listener's head) coordinates into column vector.
source_polar=sources_num'; % Pack up source(s) coordinates into column vector(s).

c=round(331*sqrt(1+0.0036*temperature)); % Calculate speed of sound (m/s) as function of temperature

%----------------------------------------- End of excel_setup.m ----------------------------------------
