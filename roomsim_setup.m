function [data_complete,Fs,c,humidity,order,H_length,H_filename,air_F,smooth_F,Fc_HP,plot_F2,plot_F3,dist_F,alpha_F...
        ,room_size,receiver_xyz,receiver_off,receiver,sensor_space,sensor_off,S_No,source_polar,F_abs,A]=roomsim_setup
%Usage: [Fs,c,humidity,order,H_length,H_filename,air_F,smooth_F,Fc_HP,plot_F2,plot_F3,dist_F,alpha_F...
%       ,room_size,receiver_xyz,receiver_off,receiver,sensor_space,sensor_off,source_polar,F_abs,A]=roomsim_setup;
% Setup code for roomsim. This function prompts for either:
% 1) Manual input via dialogue prompts. This choice will be given the option to save resulting setup data as a MAT file for future use.
% 2) A previously saved *.mat file.
% 3) Input from an Text file.(Allows non-Excel users a stored editable input form.)
% 4) Input from an Excel spreadsheet file.

%------------------------------------------------------------------------------------- 
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
%----------------------------------------------------------------------------------------
%
% The required parameters for this function are:
% Fs, the sampling frequency (Hz).
% humidity, of the air in the room. A formula (valid for 20<= h <= 70) is used to compute the absorption m of the air volume (%).
% temperature, of the air in the room. This is used to compute the speed of sound in the room (m/s)
% order, a column vector containing the order of reflections to be calculated for each dimension x,y,z.
% H_length, maximum required length in samples of room impulse response(s).
% H_filename, a string identifier naming the file to which the final impulse responses H will be saved.
% air_F, logical Flag value 0 or 1, false = no absorption due to air, true = air absorption is present.
% dist_F, logical Flag value 0 or 1, Set to enable 1/R distance attenuation effect.
% Fc_HP, scalar, the cut-off frequency of the high-pass filter applied to attenuate DC, 0 = no High-pass filter (A6 used 100 Hz)
% smooth_F, logical Flag value 0 or 1, false = no smoothing filter applied to weight intersample impulses, true = smoothing filter used (A5)
% plot_F2, logical Flag value 0 or 1, Set this to plot the geometry of receiver, source(s), image sources & image rooms,
%   false= no plot, true= 2D-plan showing image rooms on constant z plane.
% plot_F3, logical Flag value 0 or 1, Set for a rotatable 3D-plot using the MATLAB controls.
% alpha_F, logical Flag value 0 or 1, Set to enable display of room surface opacity proportional to reflectivity
% room_size(Lx;Ly;Lz), a column vector containing the length x width y and height z of the room in metres.
% receiver_xyz(xp;yp;zp), a column vector containing the RH Cartesian cordinates locating the receiver reference point in metres.
%   (NB no facility at present to set an angle for the Head sagittal plane ie it is aligned with the x axis).
% receiver_off(yaw;pitch;roll), a column vector of the angular offsets of the receiver system (in receiver axes)
%   Yaw is positive as for MATLAB azimuth (slew left), pitch is the -ve of MATLAB elevation (+ve nose up)
%   Roll is +ve "right wing down". NB These are independent of sensor offsets.
% receiver, text string value identifying type of receiver system, 
%   one of: One sensor ('one_mic'), Two sensors (two_mic'), MIT Kemar ('mithrir'), CIPIC Head ('cipicir').
% sensor_off(azim_off;elev_off;roll_off)  a column vector of the angular offsets of the sensor in sensor axes:
%   azim_off, a scalar, azimuth offset 
%   elev_off, a scalar, elevation offset
%   roll_off, a scalar, roll offset
% sensor_space, a scalar, sensor separation for the two_sensor case (if MIT or CIPIC it is implicit in the HRIR data)
% S_No, text value, CIPIC subject number format '&&&' (e.g. '021' is Kemar with small pinnae)
% R_s, radial distance (m) between receiver and source(s). NB a check is performed to ensure that all sources are inside the room.
% alpha, a scalar (or vector) of azimuth(s), -180< alpha < 180 (deg), used to set the source location(s) relative to receiver.
%   NB 0 deg has a source located in the xz plane , +ve deg rotates Anti-CW on the xy plane viewed in plan.
% beta, a scalar (or vector) of elevations(s), -90< beta < 90 (deg), used to set the source location(s) relative to receiver.
%   NB 0 deg has a source located in the xy plane, +ve deg rotates upwards.
% A, a matrix of Sabine energy surface absorption coefficients for the "shoebox" enclosure containing (in columns)
%   Ax1,Ax2,Ay1,Ay2,Az1,Az2, all being column vectors of frequency dependent absorption coefficients at the six standard measurement frequencies.
%   x1, y1 and z1 refer to the surfaces lying in the x=0, y=0 and z=0 planes respectively, while
%   x2, y2 and z2 refer to the surfaces lying in the x=Lx, y=Ly and z=Lz planes respectively.
%   Thus x1 & x2, y1 & y2, z1 & z2 are opposing surfaces eg. z1 refers to the floor and z2 the ceiling.
%-----------------------------------------------------------------------------------
% Functions called: man_inp_params.m, man_inp_room_surfaces.m, man_inp_receiver_sources.m,
% excel_setup.m, text_setup.m.

%*** Globals ***
global deg2rad; % Conversion factor degrees to radians. Loaded in roomsim.m
global rad2deg; % Conversion factor radians to degrees. Loaded in roomsim.m

global LOG_FID; % Identifier of logfile. Loaded in roomsim.m
global MACHINE % Users machine identifier. Loaded in roomsim.m
%Following three are Loaded via man_inp_receiver_sources.m, or here from an *.mat file
%or excel_setup.m, or text_setup.m.
global S3D_L S3D_R; % SENSOR impulse response data for Left (or single) and Right sensor.
global hrir_l hrir_r; % Globals for CIPIC impulse responses left and right
global H3D; % Global for MIT impulse response data. Loaded in this function roomsim_setup.m
%****************

%------------------------------ Declarations -------------------------------------
% Declare and clear sensor impulse response arrays
S3D_L={}; S3D_R={}; hrir_l=[]; hrir_r=[]; H3D=[];
% Declare and clear simulation parameters
Fs =[]; c =[]; humidity =[];
order =[]; H_length =[]; 
H_filename =[];
air_F =[]; dist_F =[]; smooth_F =[]; Fc_HP =[];
plot_F2 =[]; plot_F3 =[];
alpha_F =[]; room_size =[];
% Declare and clear receiver Yaw, Pitch & Roll offsets
receiver =[]; receiver_xyz =[]; receiver_off =zeros(3,1); 
% Declare and clear sensor arrays and CIPIC subject number
sensor_space =[]; sensor_off =[]; S_No =[];
% Declare and clear source polar coordinates array
source_polar =[];
% Declare and clear absorption and absorption frequencies arrays
F_abs =[]; A =[];


prefix='roomsim_setup: ';
error_title=[prefix ' Error'];
%--------------------------------------------------------------------------

data_complete = false;
while ~data_complete,
    beep;
    %Display the menu
    M_banner='roomsim_setup: Set up the simulation parameter values';
    Button1='Manual input following prompts';
    Button2='Load previously saved MAT file';
    Button3='Read from a Text file';
    if strcmp(MACHINE,'PCWIN'); % If PCWin detected at startup, offer Excel facility.
        Button4='Read from an Excel spreadsheet';
        M_Inputcase = menu(M_banner,Button1,Button2,Button3,Button4); % Menu with Excel offer
    else,
        M_Inputcase = menu(M_banner,Button1,Button2,Button3);
    end;
    
    switch M_Inputcase
        case 0, % Close window button pressed return to main menu
            data_complete = false;
            h=warndlg('Window closed, but data entry not completed',prefix);
            beep;
            pause(1);
            try,
                close(h); % Destroy the advisory notice if user has not cancelled
            catch,
            end;
            return;
            
        case 1, %Manual input
            %----------Start of user manual input section-----------------------------
            answer={}; % Clear the answer flag and get the simulation parameters
            [answer,Fs,humidity,temperature,order,H_length,H_filename,air_F,dist_F,Fc_HP,plot_F2,plot_F3,alpha_F]=man_inp_params;
            if ~isempty(answer),
                answer={}; % Clear the answer flag and get the room sizes and surface data
                [answer,room_size,F_abs,A]=man_inp_room_surfaces;
                if ~isempty(answer),
                    c=round(331*sqrt(1+0.0036*temperature)); % Calculate speed of sound (m/s) for use in sensor separation check
                    answer={}; % Clear the answer flag and get the receiver and source(s) data
                    [answer,receiver,receiver_xyz,receiver_off,smooth_F,sensor_space,sensor_off,S_No,source_polar]=man_inp_receiver_sources(Fs,c,room_size);
                end;
            end;
            
            if isempty(answer),
                data_complete = false;
                h=warndlg('Manual input: data entry not completed',prefix);
                beep;
                pause(1);
                try,
                    close(h); % Destroy the advisory notice if user has not cancelled
                catch,
                end;
            else,
                data_complete = true;
                fprintf(LOG_FID,'\n\n roomsim_setup: Simulation data was entered manually. \n');
                
                %----------------- Save manual set-up data to a MATLAB loadable file -----------------
                file_spec='setup_*.mat';
                title='roomsim_setup: Save data as a MAT file for future set-ups';
                dot_ext=[];
                while isempty(dot_ext),
                    beep;                    
                    save_path=pwd; % Save pathname to present directory (folder)                       
                    cd('Mat_setups'); % Change directory to the Mat_setups directory (folder)
                    [name path] = uiputfile(file_spec, title); %Display the dialogue box                    
                    cd(save_path); % Restore the previous directory (folder) path                  
                    if ~any(name), % File select was cancelled, exit the while loop.
                        fprintf(LOG_FID,'\n\n roomsim_setup: Setup parameters have not been saved'); % Print to log file (avoids wait for user response)
                        break; % Alternate return for cancel operation. No data saved to file. 
                    end;
                    filename = [path name]; % Form path+filename
                    [pathstr,name,ext] = fileparts(filename);
                    dot_ext = findstr(filename,'.'); % Find the extension marker
                    if ~strcmp(lower(ext),'.mat'),
                        h=errordlg('You must specify a *.mat extension','roomsim_run error');
                        beep;
                        uiwait(h);
                        dot_ext=[]; % Force resubmit of filename
                    else,
                        switch lower(ext),
                            case '.mat'
                                % Using the functional form of SAVE (NB Non-EVAL code for compilation)
                                % to save these workspace variables to a ".mat" file
                                save(filename, 'Fs','humidity','temperature','order','H_length','H_filename','air_F','smooth_F'...
                                    ,'Fc_HP','plot_F2','plot_F3','dist_F','alpha_F','c','room_size','receiver_xyz','receiver_off'...
                                    ,'receiver','sensor_space','sensor_off','S_No','source_polar','F_abs','A'...
                                    ,'S3D_L','S3D_R','hrir_l','hrir_r','H3D');
                                fprintf(LOG_FID,'\n\n roomsim_setup: Setup parameters have been saved to %s', filename); % Print to log file (avoids wait for user response)
                            otherwise,
                                h=errordlg('Data file extension not recognised, exiting','roomsim_setup: save error');
                                beep;
                                uiwait(h);
                                return;
                        end;
                    end;
                end; % of while loop to trap missing .mat extension
            end;
            %---------------- End of manual set up case ---------------
            
        case 2, %Input from MAT file
            banner='roomsim_setup: Select a MAT File containing set-up data';
            repeat=true;
            while repeat,
                beep;
                save_path=pwd; % Save pathname to present directory (folder)                       
                cd('Mat_setups'); % Change directory to the Mat_setups directory (folder)
                [name path] = uigetfile('setup_*.mat', banner); %Display the dialogue box
                cd(save_path); % Restore the previous directory (folder) path                  
                if ~any(name), 
                    repeat=false; % Do once if correct filename and ext given                       
                    % **Alternate return for cancel operation. No data read from file.
                else,
                    filename = [path name]; % Form full filename as path+name
                    [pathstr,name,ext] = fileparts(filename);
                    if strcmpi(lower(ext),'.mat'),
                        load(filename); %Put the previously stored values into the workspace
                        fprintf(LOG_FID,'\n\n roomsim_setup: MAT file used for setup was %s', filename);% Record setup MAT file in log file
                        data_complete=true;
                        return; % Nothing more to do so exit to calling program                      
                    else,
                        h=errordlg('You must specify a .mat extension ',error_title);
                        beep;
                        uiwait(h);
                    end;
                end; % of while loop to trap non .mat files
            end;  % of while loop
            
        case 3, % Allow user access to Text set-ups
            banner='roomsim_setup: Select the text file containing the set-up data';
            repeat=true;
            while repeat,
                repeat=false; % Do once if correct filename and ext given
                beep;
                save_path=pwd; % Save pathname to present directory (folder)                       
                cd('Text_setups'); % Change directory to the Text_setups directory (folder)
                [name path] = uigetfile('setup_*.txt', banner); %Display the dialogue box
                cd(save_path); % Restore the previous directory (folder) path                  
                if ~any(name), 
                    repeat=false; % Do once if correct filename and ext given
                    % **Alternate return for cancel operation. No data read from file.
                else,
                    filename = [path name]; % Form full filename as path+name
                    [pathstr,name,ext] = fileparts(filename);
                    if strcmpi(lower(ext),'.txt'),
                        [Fs,humidity,temperature,order,H_length,H_filename,air_F,smooth_F,Fc_HP,plot_F2,plot_F3,dist_F,alpha_F...
                                ,c,room_size,receiver_xyz,receiver_off,receiver,sensor_space,sensor_off,S_No,source_polar,F_abs,A]...
                            =text_setup(filename);
                        % Record Text setup files in log file
                        fprintf(LOG_FID,'\n\n roomsim_setup: Text file used for setup was %s', filename);
                        data_complete=true;
                        return; % Nothing more to do so exit to calling program                      
                    else,
                        h=errordlg('You must specify a .txt extension ',error_title);
                        beep;
                        uiwait(h);
                    end;
                end; % of if trap for no file selected
            end; % of while loop to trap non .txt files
            
        case 4, %Input from Excel spreadsheet or Text file
            banner='roomsim_setup: Select an Excel File containing set-up data';
            repeat=true;
            while repeat,
                beep;
                save_path=pwd; % Save pathname to present directory (folder)                       
                cd('Excel_setups'); % Change directory to the Excel_setups directory (folder)
                [name path] = uigetfile('setup_*.xls', banner); %Display the dialogue box
                cd(save_path); % Restore the previous directory (folder) path                  
                if ~any(name), 
                    repeat=false; % Do once if correct filename and ext given
                    % **Alternate return for cancel operation. No data read from file.
                else,
                    filename = [path name]; % Form full filename as path+name
                    [pathstr,name,ext] = fileparts(filename);
                    if strcmpi(lower(ext),'.xls'),
                        [Fs,humidity,temperature,order,H_length,H_filename,air_F,smooth_F,Fc_HP,plot_F2,plot_F3,dist_F,alpha_F...
                                ,c,room_size,receiver_xyz,receiver_off,receiver,sensor_space,sensor_off,S_No,source_polar,F_abs,A]...
                            =excel_setup(filename);
                        
                        % Record Excel setup file in log file
                        fprintf(LOG_FID,'\n\n roomsim_setup: Excel file used for setup was %s', filename);
                        data_complete=true;
                        return; % Nothing more to do so exit to calling program                      
                    else,
                        h=errordlg('You must specify a .xls extension ',error_title);
                        beep;
                        uiwait(h);
                    end;
                end; % of if trap for no file selected
            end;  % of while loop to trap non .xls files
            
    end; % of M_inputcase switch
end; % of while loop to test for complete data

%-------------------------------- End of roomsim_setup.m ----------------------------------------
