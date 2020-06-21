function [answer,receiver,receiver_xyz,receiver_off,smooth_F,sensor_space,sensor_off,S_No,source_polar]=man_inp_receiver_sources(Fs,c,room_size);
% Usage: [answer,receiver,receiver_xyz,receiver_off,smooth_F,sensor_space,sensor_off,S_No,source_polar]=man_inp_receiver_sources(Fs,c,room_size);
% Prompted manual input to identify receiver type and obtain receiver and source location(s)
%-------------------------------------------------------------------------------- 
% Copyright (C) 2004  Douglas R Campbell
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
%--------------------------------------------------------------------------------------
% Functions called: getSensorData.m, getReceiverOffset.m, man_inp_sources.m.

%*** Global Declarations ***
global S3D_L S3D_R; % SENSOR impulse response data for Left (or single) and Right sensor. Loaded here via getSensorData.m
global hrir_l hrir_r; % Globals for CIPIC impulse responses left and right. Loaded here.
global H3D; % Global for MIT impulse response data. Loaded here.
%***************************

% Declare and clear receiver coordinates
receiver_xyz =[];
%Declare and clear source polar coordinates
source_polar=[];
% Declare and clear receiver, and receiver Yaw, Pitch & Roll offsets
receiver =[]; receiver_off=zeros(3,1); 
% Declare and clear sensor arrays and CIPIC subject number
sensor_space =[]; sensor_off =[]; S_No =[]; smooth_F =[];
% Declare and clear sensor impulse response arrays
S3D_L={}; S3D_R={}; hrir_l=[]; hrir_r=[]; H3D={};

prefix='man_inp_receiver_sources: ';
error_title=[prefix ' Error'];

% ---------------------------- Get Receiver location ----------------------
[answer,receiver_xyz]=man_inp_receiver(room_size);
if isempty(answer),% Trap CANCEL or close window button operation
    return % Return to calling program
end;

% -------------- Get Source location(s) ------------------
answer={}; % Clear the answer flag
[answer,source_polar]=man_inp_sources;
if isempty(answer),% Trap CANCEL or close window button operation
    return % Return to calling program
end;

% ---------------------------- Receiver details ----------------------
ButtonName=[];
answer={};
while isempty(answer),
    beep;
    ButtonName=menu('Specify Receiver System and Source(s)', ...
        'One sensor','Two sensors','MIT Kemar','CIPIC Head','Vacancy','Vacancy');   
    switch ButtonName,
        case 0 % Trap Close menu window button operation
            return; % to calling menu
            
        case 1, 
            receiver='one_mic';
            banner = 'Single sensor';
            prompt = {'Enter Smoother flag, 1 = Smoother present (0 = not present):'};
            lines =1;
            def = {'0'}; %Default value
            beep;
            answer={};
            answer = inputdlg(prompt,banner,lines,def,'on');

            if ~isempty(answer),% Trap CANCEL button operation
                smooth_F=logical(str2num(answer{1}));
                
                %Single sensor rotation is achieved by sensor offsets
                receiver_off=zeros(3,1); % Clear receiver Yaw, Pitch & Roll offsets
                
                azim_off=[];
                elev_off=[];
                roll_off=[];
                
                % Form the pathname to the sensor types 
                SENSOR_root = 'SENSOR'; %Root name of SENSOR directory (folder)
                SENSOR_subdir1='Types';
                SENSOR_path = fullfile(SENSOR_root,SENSOR_subdir1); %Form pathname to SENSOR files
                
                % Get the sensor direction offset data and load the impulse response
                [azim_off, elev_off, roll_off, S3D_L]=getSensorData('Single sensor',SENSOR_path);
                if isempty(S3D_L),
                    h=errordlg(['SENSOR data input was cancelled or is empty (Check the file) ' SENSOR_path],error_title);
                    beep;
                    uiwait(h);
                    answer={}; % Clear answer flag for test on return
                else,
                    sensor_off=[azim_off; elev_off; roll_off]; % Pack up sensor directionality one column per sensor
                end;
            end;
            
        case 2,
            receiver='two_mic';                        
            delay_m=0;
            while delay_m <1, %Loop if sensors are separated by less than one sample delay
                answer={};
                banner = 'Two sensor array';
                prompt = {'Enter Sensor separation (m) (Default is CIPIC average head width) :'
                    ,'Enter Smoother flag, 1 = Smoother present (0 = not present):'...
                    };
                lines = 1;
                def = {'0.145','0'}; %Default separation value is CIPIC average head width rounded to nearest mm.
                beep;
                answer={};
                answer = inputdlg(prompt,banner,lines,def,'on');
                if isempty(answer),% Trap CANCEL button operation
                    break; % out of while loop
                else % Check spacing value
                    sensor_space=str2num(answer{1});
                    smooth_F=logical(str2num(answer{2}));
                    delay_m=sensor_space*Fs/c; % delay in samples = (Samples per sec)*(Distance)/speed of sound
                    if delay_m < 1, % Check two sensor separation is greater than one sample distance
                        banner='Re-enter value';
                        message='Two sensor separation < 1 sample distance';
                        h=msgbox(message,banner,'warn');  %Warn & beep.
                        beep;
                        uiwait(h);% Wait for user to acknowledge
                    end;
                end;
            end; % of while loop to check sensor separation
            
            if ~isempty(answer),% Trap CANCEL button operation
                % Declare sensor Yaw, Pitch & Roll offsets
                azim_off_L=[];azim_off_R=[];
                elev_off_L=[];elev_off_R=[];
                roll_off_L=[];roll_off_R=[];
                
                % Form the pathname to the sensor types 
                SENSOR_root = 'SENSOR'; %Root name of SENSOR directory (folder)
                SENSOR_subdir1='Types';
                SENSOR_path = fullfile(SENSOR_root,SENSOR_subdir1); %Form pathname to SENSOR files
                
                % Get the Left sensor impulse response and direction offset data
                [azim_off_L, elev_off_L, roll_off_L, S3D_L]=getSensorData('Left sensor',SENSOR_path);
                if isempty(S3D_L),
                    h=errordlg(['SENSOR data input was cancelled or is empty (Check the file) ' SENSOR_path],error_title);
                    beep;
                    uiwait(h);
                    answer={}; % Clear answer flag for test on return
                else,                        
                    % Get the Right sensor impulse response and direction offset data
                    [azim_off_R, elev_off_R, roll_off_R, S3D_R]=getSensorData('Right sensor',SENSOR_path);
                    if isempty(S3D_R),
                        h=errordlg(['SENSOR data input was cancelled or is empty (Check the file) ' SENSOR_path],error_title);
                        beep;
                        uiwait(h);
                        answer={}; % Clear answer flag for test on return
                    else,
                        % Pack up L and R offsets
                        azim_off=[azim_off_L azim_off_R];
                        elev_off=[elev_off_L elev_off_R];
                        roll_off=[roll_off_L roll_off_R];
                        sensor_off=[azim_off; elev_off; roll_off]; % Pack up sensor directionality one column per sensor
                        
                        %Get the receiver offsets and check they're sensible
                        answer={}; % Clear answer flag       
                        [answer,receiver_off]=getReceiverOffset;
                        if isempty(answer),
                            h=errordlg('Receiver offset data input was cancelled' ,error_title);
                            beep;
                            uiwait(h);
                            answer={}; % Clear answer flag for test on return
                        end;
                    end;
                end;
            end;
                        
        case 3,
            receiver='mithrir';
            MIT_root = 'MIT_HRTF'; %Root name of MIT directory (folder)
            MIT_subdir1='Kemar';
            MIT_subdir2='compact';
            MIT_filename='hrir_final.mat';
            MIT_file = fullfile(MIT_root,MIT_subdir1,MIT_subdir2,MIT_filename); %Form pathname to Kemar data file
            H3D={}; % Clear array for loading MIT data
            
            if (exist(MIT_file,'file')==2), % Check MIT file is installed
                load(MIT_file); % Load the MIT Kemar data file into the workspace (creates H3D)
                if isempty(H3D),
                    h=errordlg(['MIT data is empty. Check the file ' MIT_file],error_title);
                    beep;
                    uiwait(h);
                    answer={}; % Clear answer flag
                else,
                    % Clear sensor offsets
                    azim_off=0;
                    elev_off=0;
                    roll_off=0;
                    
                    %Get the receiver offsets and check they're sensible
                    answer={}; % Clear answer flag       
                    [answer,receiver_off]=getReceiverOffset;
                    if isempty(answer),
                        h=errordlg('Receiver offset data input was cancelled' ,error_title);
                        beep;
                        uiwait(h);
                        answer={}; % Clear answer flag for test on return
                    end;
                end;
            else
                h=errordlg([MIT_file '  NOT FOUND. Check the file structure.'],error_title);
                beep;
                uiwait(h);
                answer={}; % Clear answer flag
            end

        case 4,
            receiver='cipicir';
            CIPIC_root = 'CIPIC_HRTF'; %Root name of CIPIC directory (folder)
            CIPIC_subdir1='standard_hrir_database';
            CIPIC_subdir2='subject_';
            CIPIC_filename='hrir_final.mat';
            
            ITD=[]; OnL=[]; OnR=[]; hrir_l=[]; hrir_r=[]; % Clear arrays for loading CIPIC data
            
            if (exist(CIPIC_root,'dir')==7)
                S_No=[];
                ok=0;
                % Setup list box for picking CIPIC subject number           
                subject_list={'003','008','009','010','011','012','015','017','018','019'...
                        ,'020','021','027','028','033','040','044','048','050','051'...
                        ,'058','059','060','061','065','119','124','126','127','131'...
                        ,'133','134','135','137','147','148','152','153','154','155'...
                        ,'156','158','162','163','165'};
                beep;
                [selection,ok] = listdlg('PromptString','Select a CIPIC subject number (021 is Kemar small pinnae)'...
                    ,'SelectionMode','single','InitialValue',12,'ListSize',[300 300],'ListString',subject_list);
                
                if ok~=0,% Trap CANCEL button or close dialogue box operation
                    S_No = subject_list{selection};% Return CIPIC subject number (as character)
                    CIPIC_file = fullfile(CIPIC_root,CIPIC_subdir1,[CIPIC_subdir2 S_No],CIPIC_filename); %Form pathname to subject data file
                    if (exist(CIPIC_file,'file')==2), % Check selected subject file is installed and load the impulse responses
                        load(CIPIC_file,'hrir_l','hrir_r'); % Load hrir_l and hrir_r into the workspace from the subject file
                        if isempty(hrir_l)|isempty(hrir_r),
                            h=errordlg(['CIPIC data is empty, Check the subject file ' CIPIC_file],error_title);
                            beep;
                            uiwait(h);
                            answer={}; % Clear answer flag
                        else,
                            % Clear sensor offsets
                            azim_off=0;
                            elev_off=0;
                            roll_off=0;
                            
                            %Get the receiver offsets and check they're sensible
                            answer={}; % Clear answer flag       
                            [answer,receiver_off]=getReceiverOffset;
                            if isempty(answer),
                                h=errordlg('Receiver offset data input was cancelled' ,error_title);
                                beep;
                                uiwait(h);
                                answer={}; % Clear answer flag for test on return
                            end;
                    end;
                    else,
                        h=errordlg([CIPIC_file '  NOT FOUND, check Subject No ' S_No 'is installed.'],error_title);
                        beep;
                        uiwait(h);
                        S_No=[];
                        answer={}; % Clear answer flag
                    end;
                else,
                    answer={}; % Clear answer flag 
                end;
                
            else,
                h=errordlg([CIPIC_root '  NOT FOUND, Check the file structure.'],error_title);
                beep;
                uiwait(h);
                answer={}; % Clear answer flag
            end;

        case 5, % *** Expansion space ***
            h=msgbox('This item has been left vacant for future expansion','roomsim_setup');
            beep;
            uiwait(h);% Wait for user to acknowledge
            answer={}; % Clear answer flag for test on return
            
        case 6, % *** Expansion space ***
            h=msgbox('This item has been left vacant for future expansion','roomsim_setup');
            beep;
            uiwait(h);% Wait for user to acknowledge
            answer={}; % Clear answer flag for test on return
            
    end; % receiver switch   
end; % while loop for Specify Receiver System menu

%------ End of man_inp_receiver_sources.m ----------------