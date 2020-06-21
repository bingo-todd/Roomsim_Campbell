function [Fs,humidity,temperature,order,H_length,H_filename,air_F,smooth_F,Fc_HP,plot_F2,plot_F3,dist_F,alpha_F...
         ,c,room_size,receiver_xyz,receiver_off,receiver,sensor_space,sensor_off,S_No,source_polar,F_abs,A]=text_setup(filename);
%Usage: [Fs,humidity,temperature,order,H_length,H_filename,air_F,smooth_F,HPass_F,plot_F2,plot_F3,dist_F,alpha_F...
%    ,c,room_size,receiver_xyz,receiver,sensor_space,sensor_off,S_No,source_polar,F_abs,A]=text_setup(filename);
% TEXT_SETUP.M reads filename.txt to obtain values for setting up roomsim.
% It calls GetTextSetup.m, to handle only text data for non-Excel users and to allow compilation to stand-alone code.
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
% Functions called: getTextSetup.m, 

%*** Globals ***
global hrir_l hrir_r; % Globals for CIPIC impulse responses left and right
global H3D; % Global for MIT impulse response data
global S3D_L S3D_R; % SENSOR impulse response data for Left (or single) and Right sensor. 
%***************

sensor_off=[]; % Declare empty array for sensor offsets
receiver_off=[];  % Declare empty array for receiver offsets

error_title='text_setup: Error';

%------------- Get the data from the setup Text files -----------------------
[Param_text, absorption_text, dir_text, sources_text] = getTextSetup(filename);

%----------------------- Simulation control parameters ------------------------------
Fs=str2num(Param_text{1}); % Sampling frequency (Hz)
humidity=str2num(Param_text{2}); % Relative humidity of air (%) (Used to calculate air absorption coefficient "m", valid range 20%< h <70%)
temperature=str2num(Param_text{3}); % Temperature of air (deg C) (Used to calculate speed of sound (m/s))
order=str2num(Param_text{4}); % If -ve then value computed in make_Roomsim is used, else value supplied here is used (limits order of reflections computed)
H_length=str2num(Param_text{5}); % If -ve then H_length is later set = RT60, else value supplied here is used.
H_filename=Param_text{6}; %Output filename for impulse response.

%--------------------------------------- Flags etc ---------------------------------------
air_F=logical(str2num(Param_text{7})); % false = no absorption due to air, true = air absorption is present.
dist_F=logical(str2num(Param_text{8})); % false = no distance effect, true = 1/R attenuation with distance applied.
Fc_HP = str2num(Param_text{9}); %0 = no High-Pass filter applied, scalar value for cut-off = High-Pass filter applied.
smooth_F=logical(str2num(Param_text{10})); %false = no smoothing filter applied, true = smoothing filter used.
plot_F2=logical(str2num(Param_text{11})); % false = no plot, true = 2D-plan, shows image rooms on xy plane.
plot_F3=logical(str2num(Param_text{12})); % false = no plot, true = 3D-plot, rotatable.
alpha_F=logical(str2num(Param_text{13})); % false = fixed transparent surfaces for Room Geometry plot, true = (surface opacity = reflectivity)

%--------- Room dimensionss --------------
Lx=str2num(Param_text{14}); % Height
Ly=str2num(Param_text{15}); % Width
Lz=str2num(Param_text{16}); % Length

% Receiver reference point [xp,yp,zp](m), if Head, it is mid-point of the inter_aural axis
xp=str2num(Param_text{17}); % x coordinate of receiver reference point
yp=str2num(Param_text{18}); % y coordinate of receiver reference point
zp=str2num(Param_text{19});% z e.g. Typical height above floor of ears of seated human subject = 1.2 m

% Sensor details
receiver=Param_text{20}; % Receiver type: one-mic, two_mic, mithrir, cipicir
sensor_space=str2num(Param_text{21}); % Sensor separation (if head it is implicit in the HRIR data)

%-------------- Identify path to filename for extraction of hrir from MIT Kemar data base -------------
MIT_root=Param_text{22}; % Root directory of the MIT Kemar data, an immediate sub-directory of the Roomsim directory
MIT_subdir1=Param_text{23};
MIT_subdir2=Param_text{24};
MIT_filename=Param_text{25};

%-------------- Identify path to filename for extraction of hrir from CIPIC data base -----------------
CIPIC_root=Param_text{26}; % Root directory of the CIPIC HRTF data, an immediate sub-directory of the Roomsim directory
CIPIC_subdir1=Param_text{27};
CIPIC_subdir2=Param_text{28};
S_No=Param_text{29}; % CIPIC subject number, format '&&&' (e.g. '021' Kemar with small pinnae)
CIPIC_filename=Param_text{30};

% Receiver orientation in room axes
receiver_off(1)=str2num(Param_text{31}); % yaw offset of receiver
receiver_off(2)=str2num(Param_text{32}); % pitch offset of receiver
receiver_off(3)=str2num(Param_text{33}); % roll offset of receiver

% Sound source position(s) relative to receiver reference point (Head or sensor(s)).
limit=size(sources_text,1); %Get the number of rows in the sheet (allows user to add sources)
for k=1:limit,
    if ~(isempty(sources_text{k,1})||isempty(sources_text{k,2})||isempty(sources_text{k,3})), % Prevent reading an empty cell
        R_s(1,k)=str2num(sources_text{k,1}); % Column vector of radial distance(s) of source(s) from head (m)
        alpha(1,k)=str2num(sources_text{k,2}); % Column vector of azimuth(s) of sources -180< alpha < 180 (deg) NB +ve is ACW on xy plane
        beta(1,k)=str2num(sources_text{k,3}); % Column vector of elevation(s) of sources -90< beta < 90 (deg).
    end;
end;

switch receiver % Selection of sensor type 
    case {'one_mic'}
        % Set up sensor directionality
        azim_off=str2num(dir_text{1,1}); % Minimum azimuth seen by sensor
        elev_off=str2num(dir_text{2,1}); % Maximum azimuth seen by sensor
        roll_off=str2num(dir_text{3,1}); % Minimum elevation seen by sensor
        sensor_off=[azim_off; elev_off; roll_off]; % Pack up sensor directionality one column per sensor
        SENSOR_root=dir_text{4,1}; % Root directory of the SENSOR data, an immediate sub-directory of the Roomsim directory
        SENSOR_subdir1=dir_text{5,1};
        SENSOR_filename=dir_text{6,1};
        SENSOR_file = fullfile(SENSOR_root,SENSOR_subdir1,SENSOR_filename); %Form pathname to SENSOR data file
        if (exist(SENSOR_file,'file')==2), % Check SENSOR file is installed
            load(SENSOR_file,'S3D'); % Load the SENSOR data file into the workspace and create S3D.
            S3D_L=S3D; % Copy cell array for Left sensor impulse responses
            clear S3D; % Free up memory
        else,
            h=errordlg([SENSOR_file '  NOT FOUND, exiting from text_setup'],error_title);
            beep;
            uiwait(h);
            return;
        end;

    case {'two_mic'}
        % Set up sensor directionality [Left Right]
        azim_off=[str2num(dir_text{1,1}) str2num(dir_text{1,2})];
        elev_off=[str2num(dir_text{2,1}) str2num(dir_text{2,2})];
        roll_off=[str2num(dir_text{3,1}) str2num(dir_text{3,2})];
        sensor_off=[azim_off; elev_off; roll_off]; % Pack up sensor directionality one column per sensor
        SENSOR_root=dir_text{4,1}; % Root directory of the SENSOR data, an immediate sub-directory of the Roomsim directory
        SENSOR_subdir1=dir_text{5,1};
        SENSOR_filename=dir_text{6,1};
        SENSOR_file = fullfile(SENSOR_root,SENSOR_subdir1,SENSOR_filename); %Form pathname to SENSOR data file
        if (exist(SENSOR_file,'file')==2), % Check SENSOR file is installed
            load(SENSOR_file,'S3D'); % Load the SENSOR data file into the workspace and create S3D.
            S3D_L=S3D; % Copy cell array for Left sensor impulse responses
            clear S3D; % Free up memory
        else,
            h=errordlg([SENSOR_file '  NOT FOUND, exiting from text_setup'],error_title);
            beep;
            uiwait(h);
            return;
        end;
        SENSOR_root=dir_text{4,2}; % Root directory of the SENSOR data, an immediate sub-directory of the Roomsim directory
        SENSOR_subdir1=dir_text{5,2};
        SENSOR_filename=dir_text{6,2};
        SENSOR_file = fullfile(SENSOR_root,SENSOR_subdir1,SENSOR_filename); %Form pathname to SENSOR data file
        if (exist(SENSOR_file,'file')==2), % Check SENSOR file is installed
            load(SENSOR_file,'S3D'); % Load the SENSOR data file into the workspace and create S3D.
            S3D_R=S3D; % Copy cell array for Right sensor impulse responses
            clear S3D; % Free up memory
        else,
            h=errordlg([SENSOR_file '  NOT FOUND, exiting from text_setup'],error_title);
            beep;
            uiwait(h);
            return;
        end;
        
    case 'mithrir' % Extract hrir from MIT Kemar data base
        MIT_file = fullfile(MIT_root,MIT_subdir1,MIT_subdir2,MIT_filename); %Form pathname to MIT Kemar data file
        if (exist(MIT_file,'file')==2), % Check MIT file is installed
            load(MIT_file); % Load the MIT Kemar data file into the workspace (creates H3D)
        else,
            h=errordlg([MIT_file '  NOT FOUND, exiting from text_setup'],error_title);
            beep;
            uiwait(h);
            return;
        end;
        
    case 'cipicir' % Extract hrir from CIPIC data base
        CIPIC_file = fullfile(CIPIC_root,CIPIC_subdir1,[CIPIC_subdir2 S_No],CIPIC_filename); %Form pathname to subject data file
        if (exist(CIPIC_file,'file')==2), % Check selected subject file is installed
            load(CIPIC_file); % Load the subject file into the workspace (loads hrir_l and hrir_r)
        else,
            h=errordlg([CIPIC_file '  NOT FOUND, check Subject No ' S_No 'is installed.'],error_title);
            beep;
            uiwait(h);
            S_No=-1;
            return;
        end;
end;

%---------------- Set the room surface absorptions ----------------------
for k=1:6,
    F_abs(k)=str2num(absorption_text{1,k});
    Ax1(k)=str2num(absorption_text{2,k}); % Absorption of wall in x=0 plane (behind Kemar in plan)
    Ax2(k)=str2num(absorption_text{3,k}); % Absorption of wall in x=Lx plane (front in plan)
    Ay1(k)=str2num(absorption_text{4,k}); % Absorption of wall in y=0 plane (right in plan)
    Ay2(k)=str2num(absorption_text{5,k}); % Absorption of wall in y=Ly plane (left in plan)
    Az1(k)=str2num(absorption_text{6,k}); % Absorption of floor i.e. z=0 plane
    Az2(k)=str2num(absorption_text{7,k}); % Absorption of ceiling i.e. z=Lz plane
end;
%---------------- End of surface absorption set up ---------------

c=round(331*sqrt(1+0.0036*temperature)); % Calculate speed of sound (m/s) as function of temperature

% Pack various parameters for the room simulation
room_size=[Lx;Ly;Lz]; % Pack up room dimensions into column vector.
receiver_xyz=[xp;yp;zp]; % Pack up receiver (listener's head) coordinates into column vector.
source_polar=[R_s;alpha;beta]; % Pack up source(s) coordinates into column vector.
A=[Ax1' Ax2' Ay1' Ay2' Az1' Az2']; % Pack up column vectors (NB Transposition) of absorption coefficients in array A
%----------------------------------------- End of text_setup.m ----------------------------------------
