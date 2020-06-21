function [run_once, n_sources]=roomsim_run(run_once);
% Usage: [run_once, n_sources]=roomsim_run(run_once);
% Calls the set-up function, does some checks, calls the core image calculation
% function, calls various ploting functions, and allows saving the set-up as a MAT file for later re-use.
%-------------------------------------------------------------------------------- 
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
%--------------------------------------------------------------------------------------
% Functions called: roomsim_setup.m, roomplot.m, reverberation_time.m, roomsim_core.m, roomplot_imp.m,
%   roomplot_magf.m, roomplot_2D.m, roomplot_3D.m, check_simulation_time.m, check_length_order.m .

%*** Global Declarations ***
global deg2rad; % Conversion factor degrees to radians. Loaded in roomsim.m
global rad2deg; % Conversion factor radians to degrees. Loaded in roomsim.m
global LOG_FID; % Identifier of logfile. Loaded in roomsim.m
global H_filename; % Identifier for current impulse response file.
%***************************

%------------------- Declarations and Equates -----------------------------
H_filename=[];
n_sources=[];
head_width=0.145; % Value is CIPIC average head width rounded to nearest mm.
run_once=false; % Flag indicates successful data acquisition and checking when true

% Common message texts for roomsim_run 
prefix='roomsim_run: ';
terminate_msg=[prefix ' terminating']; % Termination title for error dialogue box
error_title=[prefix 'Error'];

%------------------------------ Start of user input section -----------------------------
% Call the function to get the user setup values from file or manually
data_complete = false;
[data_complete,Fs,c,humidity,order,H_length,H_filename,air_F,smooth_F,Fc_HP,plot_F2,plot_F3,dist_F,alpha_F...
        ,room_size,receiver_xyz,receiver_off,receiver,sensor_space,sensor_off,S_No,source_polar,F_abs,A]=roomsim_setup;
if ~data_complete,
    run_once=false;
    return;
end;
%------------------------------- End of user input section ---------------------

% Simulation constants dependent on setup
T=1/Fs; % Sampling period
nyquist=Fs/2;
Fs_c = Fs/c; % Samples per metre

% Create inertial axes to body axis transformation matrix 
receiver_off=deg2rad.*receiver_off;
[tm]=tm3DR(receiver_off(1),-receiver_off(2),receiver_off(3)); % NB -ve sign for pitch adjusts for MATLAB rotational conventions

%---------------------------------------- Start of sanity checks ------------------------------------------------

%------------------- Check sampling frequency -----------------------
% Check and prevent possible aliasing of HRIR data
switch receiver % ---------- Identify receiver system---------------------
    case {'mithrir','cipicir'}
        if (Fs ~= 44100) % Warn of inappropriate sampling frequency
            msg_title=[prefix 'Forcing Fs= 44.1kHz'];
            message=['MIT and CIPIC HRIR data requires Fs = 44100 Hz, Your Fs = ' num2str(Fs) ' Hz'];
            h=msgbox(message,msg_title,'warn');  %Warn & beep.
            beep;
            uiwait(h);% Wait for user to acknowledge
            Fs=44100;
        end;
end;

% Check and warn of possible aliasing of absorption frequencies

if max(F_abs)>= nyquist % Warn Fs too low for absorption data
    answer={};
    msg_title = [prefix 'Low sampling frequency'];
    prompt = {['Set a new sampling frequency > 2*' num2str(max(F_abs)) 'Hz']};
    lines = 1;
    def = {'44100'}; % Default value
    beep;
    answer = inputdlg(prompt,msg_title,lines,def,'on');
    if isempty(answer), % Trap CANCEL button operation
        run_once=false;
        return;
    else,
        Fs=str2num(answer{1});
    end;
end;

%--- Convert source radial distance (R_s), azimuth (alpha) and elevation (beta) to x,y,z coordinates of each parent source -------
xp=receiver_xyz(1);
yp=receiver_xyz(2);
zp=receiver_xyz(3);
alpha_rad=deg2rad.*source_polar(2,:); %Azimuth in rads
beta_rad=deg2rad*source_polar(3,:); %Elevation in rads
hypxy=source_polar(1,:).*cos(beta_rad); %projection of R_s on xy plane
x=xp+hypxy.*cos(alpha_rad);% sound source x position.
y=yp+hypxy.*sin(alpha_rad);% sound source y position.
z=zp+source_polar(1,:).*sin(beta_rad);% sound source z position.
source_xyz=[x;y;z]; % Pack up source(s) coordinates into array one column vector per source.

% Calculate sensor coordinates in room axes for selected receiver type
switch receiver, % Select receiver system
    case 'one_mic',
        sensor_xyz(:,1) = receiver_xyz; %  Co-ordinates of single sensor
        receiver_off=zeros(3,1); % Force receiver Yaw, Pitch & Roll offset to zero
    case 'two_mic', % Sensor pair centered on receiver reference point(xp,yp,zp).
        % Sources are allowed to exist between a widely spaced sensor pair.
        sensor_xyzp(:,1) = [0;+sensor_space/2;0]; % Coordinates of Left sensor in receiver axes.
        sensor_xyzp(:,2) = [0;-sensor_space/2;0]; % Coordinates of Right sensor in receiver axes.
        % Rotate the receiver axes to align with room axes (body to room axes transformation)
        sensor_xyzp=tm'*sensor_xyzp; % Body axes to inertial axes transformation
        sensor_xyz(:,1) = receiver_xyz + sensor_xyzp(:,1); % Add L sensor coordinates and receiver origin to give room coords of L sensor
        sensor_xyz(:,2) = receiver_xyz + sensor_xyzp(:,2); % Add R sensor coordinates and receiver origin to give room coords of R sensor         
    case {'mithrir','cipicir'},
        sensor_space = head_width; % Separation of sensor pair is head_width metres.
        sensor_xyzp(:,1) = [0;+sensor_space/2;0]; % Coordinates of Left sensor in receiver axes.
        sensor_xyzp(:,2) = [0;-sensor_space/2;0]; % Coordinates of Right sensor in receiver axes.
        % Rotate the receiver axes to align with room axes (body to room axes transformation)
        sensor_xyzp=tm'*sensor_xyzp; % Body axes to inertial axes transformation
        sensor_xyz(:,1) = receiver_xyz + sensor_xyzp(:,1); % Add L sensor coordinates and receiver origin to give room coords of L sensor
        sensor_xyz(:,2) = receiver_xyz + sensor_xyzp(:,2); % Add R sensor coordinates and receiver origin to give room coords of R sensor         
end; % switch receiver

%-------- Check for primary source/receiver coincident ---------------------------
n_sources=size(source_xyz,2); % Number of sources = number of columns in source_xyz
for ps=1:n_sources % For each parent source
    switch receiver, % Select receiver system
        case 'one_mic',
            dist_s = norm(source_xyz(:,ps)-sensor_xyz(:,1),2); % Distance (m) between primary source and receiver single sensor
            delay_s(ps) = Fs_c*dist_s; % Delay in samples = (Samples per metre)*Distance
        case 'two_mic', % Sensor pair centered on receiver reference point(xp,yp,zp), lying in xy plane and aligned with y axis.
            % Sources are allowed to exist between a widely spaced sensor pair.
            dist_s(1) = norm(source_xyz(:,ps)-sensor_xyz(:,1),2); % Distance (m) between primary source and receiver left sensor
            dist_s(2) = norm(source_xyz(:,ps)-sensor_xyz(:,2),2); % Distance (m) between primary source and receiver right sensor
            delay_s(ps,:) = Fs_c*dist_s; % L & R delays in samples = (Samples per metre)*Distance
        case {'mithrir','cipicir'},
            dist_s(1) = norm(source_xyz(:,ps)-sensor_xyz(:,1),2); %Distance (m) between primary source and receiver left sensor
            dist_s(2) = norm(source_xyz(:,ps)-sensor_xyz(:,2),2); %Distance (m) between primary source and receiver right sensor
            delay_s(ps,:) = Fs_c*dist_s; % L & R delays in samples = (Samples per metre)*Distance
    end; % switch receiver
    
    % Warn of sources within one sample period of receiver/sensor location
    if ~all(delay_s >= 1) % Some delays are less than one sample so display a menu & beep.
        M_Title=[prefix 'WARNING Source ' num2str(ps) ' and sensor coincident.'];
        B1_text='Continue with present value';
        B2_text='Cancel and return to Roomsim Main Menu';
        beep;
        M_IRLcase = menu(M_Title,B1_text,B2_text);
        switch M_IRLcase
            case 0 % Close window button was selected
                run_once=false;
                return; % Return to calling program (main menu)
                
            case 1
                %                 Continue
            case 2
                run_once=false;
                return; % Return to calling program (main menu)
        end;
    end;
end; % of loop for each primary source ps

%---------- Check for sources outside of room and find max and min axis values for plotting ------------
source_outside=false; %Initialise flag
Lx=room_size(1);
Ly=room_size(2);
Lz=room_size(3);

source_error='Source outside of room, '; % Message warning of impossible source location
if min(x)<0
    xmin=min(x);
    h=errordlg([source_error ' x = ' num2str(xmin) '.'],terminate_msg);% Warn of impossible source location
    beep;
    uiwait(h);
    source_outside=true;
else
    xmin=-0.1;
end;
if min(y)<0
    ymin=min(y);
    h=errordlg([source_error ' y = ' num2str(ymin) '.'],terminate_msg)% Warn of impossible source location
    beep;
    uiwait(h);
    source_outside=true;
else
    ymin=-0.1;
end;
if min(z)<0
    zmin=min(z);
    h=errordlg([source_error ' z = ' num2str(zmin) '.'],terminate_msg);% Warn of impossible source location
    beep;
    uiwait(h);
    source_outside=true;
else
    zmin=-0.1;
end;
if max(x)>=Lx
    xmax=max(x);
    h=errordlg([source_error ' x = ' num2str(xmax) '.'],terminate_msg);% Warn of impossible source location
    beep;
    uiwait(h);
    source_outside=true;
else
    xmax=Lx+0.1;
end;
if max(y)>=Ly
    ymax=max(y);
    h=errordlg([source_error ' y = ' num2str(ymax) '.'],terminate_msg);% Warn of impossible source location
    beep;
    uiwait(h);
    source_outside=true;
else
    ymax=Ly+0.1;
end;
if max(z)>=Lz
    zmax=max(z);
    h=errordlg([source_error ' z = ' num2str(zmax) '.'],terminate_msg);% Warn of impossible source location
    beep;
    uiwait(h);
    source_outside=true;
else
    zmax=Lz+0.1;
end;
%------------------- End of source location checks -----------------------

%-------------------- Check for sensors outside of room --------------------
sensor_outside=false; %Initialise flag
% Check that sensor(s) are within room    
if (min(min(sensor_xyz))<0)||(max(sensor_xyz(1,:))>=Lx)||(max(sensor_xyz(2,:))>=Ly)||(max(sensor_xyz(3,:))>=Lz)
    sensor_error='Sensor(s) outside of room.';
    h=errordlg(sensor_error,terminate_msg);% Warn of impossible sensor location
    beep;
    uiwait(h); % Wait for user response
    sensor_outside=true;
end; % of sensor location check -----------------------------

B=realsqrt(1-A); % Calculate the frequency dependent pressure reflection coefficients (NB +ve for air to hard surface interface)

% Display the room geometry with receiver and source(s) locations as a 3D plot for visual confirmation
if alpha_F,
    % Make opacity of each face proportional to mean over frequency (ie. down the columns) of the reflection coefficients B NB TRANSPOSE
    alph=floor(mean(64*B,1)');
else, % Fix transparency for Ax1,Ax2,Ay1,Ay2,Az1,Az2
    alph=[32; 32; 32; 32; 64; 1]; % Opacity of faces fixed, opaque floor, clear ceiling, 50% transparent walls
end;
roomplot(room_size,source_xyz,receiver_xyz,receiver_off,receiver,sensor_xyz,head_width,alph); % Display room for checking

if source_outside || sensor_outside, % Source or sensor outside room, so warning beep, and exit. 
    beep;
    run_once=false;
    return; % Force return to main menu
end;
%-------------------- Data passed sanity checks so start the simulation -------------

%------------- Display the Frequency variation of the surface absorption coefficients --------------
roomplot_absorption(F_abs,A);

fprintf(LOG_FID,'\n\n Speed of sound  c = %d m/s ',c); % Print c to the log file
fprintf(LOG_FID,'\n\n Length (Depth) (Lx) of room = %6.2f m',Lx);
fprintf(LOG_FID,'\n Width (Ly) of room = %6.2f m',Ly);
fprintf(LOG_FID,'\n Height (Lz) of room = %6.2f m',Lz);

%------------- Check values for H_length and order ----------
if max(max(B))==0, % Anechoic case, set H_length and order to ensure FULL CODE PATH EXECUTED in all following functions incl. Plots.
    order = [2; 2; 2]; 
    H_length = ceil(max(max(delay_s))); % Round up furthest distance in samples between a source and sensor
    H_length = H_length+200; % Ensure H_length > 200 points so that a full CIPIC or MIT HRIR can be viewed
    msg_title=[prefix 'Anechoic room detected.'];
    message=['Forcing order = ',num2str(max(order)),' and Impulse response length = ',num2str(H_length)];
    h=warndlg(message,msg_title);  %Warn & beep.
    beep;
    pause(1);
    try,
        close(h); % Destroy the advisory notice if user has not cancelled
    catch,
    end;
    fprintf(LOG_FID,['\n\n Anechoic room detected ']); % Record anechoic case in the log file
else, % Set up the air absorption model and estimate reverberation time RT60
    RT60_estimator = 'Norris_Eyring'; %The Norris_Eyring RT60 estimator gives a shorter estimate than the Sabine ones.
    m_air=zeros(size(F_abs)); % Initialise air absorption to zero at octave frequencies
    [RT60 MFP]= reverberation_time(c,room_size,A,F_abs,m_air,RT60_estimator); % Estimate a room reverberation time RT60 WITHOUT air absorption
    if air_F, % Check effect of air on RT60
        % The variation of air absorption coefficient "m" with humidity and frequency can be approximaCted by
        %    (from L E Kinsler et al "Fundamentals of acoustics", 3rd Ed., Wiley, New York, 1982.
        m_air = 5.5E-4*(50/humidity)*(F_abs/1000).^(1.7); % Valid Ranges are: relative humidity 20%< h <70%, 1500< F_abs <10000 Hz.
        % Calculate a room reverberation time RT60, used to size impulse response length "H_length" and set "order".
        [RT60_Air MFP_Air]= reverberation_time(c,room_size,A,F_abs,m_air,RT60_estimator); % Estimate a room reverberation time RT60 WITH air absorption
        air_effect = max(abs(1-RT60_Air./RT60))*100; % Calculate the % difference due to including the effect of air
        fprintf(LOG_FID,'\n\n RT60 estimate: Air absorption makes %5.2f percent difference in this room.', air_effect); % Record air absorption case in the log file
        RT60=RT60_Air; % RT60 including air absorption
    end; % of air absorption set up
    roomplot_RT60(F_abs, RT60); % Plot the reverberation time RT60 vs frequency
    % Record reverberation times in the log file
    fprintf(LOG_FID,['\n\n Reverberation Times by ' RT60_estimator ' estimator']); % Print to the log file
    for ii=1:length(F_abs)
        fprintf(LOG_FID,'\n At frequency = %6.0f Hz RT60 = %8.4g s', F_abs(ii), RT60(ii)); % Print RT60 to the log file
    end;
    
    %Estimate room break frequencies according to Everest (4th Ed) p324 
    F1=c/max([Lx Ly Lz]); % Below F1 no resonant support for sound in room ie Lowest room mode
    F2=11250*sqrt(0.0283*mean(RT60)/(Lx*Ly*Lz)); % Between F1 and F2 room modes dominate, between F2 and F3 diffraction and diffusion dominate
    F3=4*F2; % Above F3 specular reflections and ray acoustics are valid
    
    fprintf(LOG_FID,'\n\n Estimate of Room break frequencies (uses mean of above RT60''s = %8.4g s),',mean(RT60)); % Print to the log file
    fprintf(LOG_FID,'\n F1 = %6.0f Hz. Lowest room mode, i.e. below F1 no resonant support for sound in room', F1);
    fprintf(LOG_FID,'\n Between F1 and F2 room modes dominate'); % Print to the log file
    fprintf(LOG_FID,'\n F2 = %6.0f Hz. Approximate cutoff (crossover) frequency', F2);
    fprintf(LOG_FID,'\n Between F2 and F3 diffraction and diffusion dominate'); % Print to the log file
    fprintf(LOG_FID,'\n F3 = %6.0f Hz. Above F3 specular reflections and ray acoustics are valid', F3);
    
    %--------------------- Estimate order and/or impulse response length --------------------------------
    % and check so that user will get early warning of possible OUT OF MEMORY condition.
    [H_length, order]=check_length_order(Fs, c, H_length, order, RT60, delay_s, room_size, n_sources);
    
    %--------------- Alert user to possible long simulation time due to large array sizes ----------------
    % Use No of image sources (n_isources) as a measure of computational load to alert user.
    n_isources = 8.*(2.*order(1)).*(2.*order(2)).*(2.*order(3)); % Estimated number of image sources required by order.
    pract_n_isources = 64000; % Practical number of image sources, Approximately equivalent to order 10.
    if n_isources > pract_n_isources, % check and warn of possible long simulation time, and allow change of impulse response length.
        [H_length, order]=check_simulation_time(Fs, c, H_length, order, room_size);
    end; 
    
end;% of H_length and Order calculation and checks

% Print impulse response length and order value to the log file
fprintf(LOG_FID,'\n\n Impulse response length = %i samples', H_length);
fprintf(LOG_FID,'\n\n order_x = %i', order(1)); 
fprintf(LOG_FID,'\n order_y = %i', order(2));
fprintf(LOG_FID,'\n order_z = %i', order(3));   

fprintf(LOG_FID,'\n\n Receiver =  %s',receiver); % Print receiver type to the log file

switch receiver % ---------- Record receiver directionality in the log file ---------------------
    case {'one_mic'}
        % Unpack sensor directionality and print to log file
        fprintf(LOG_FID,'\n azim_off = %6.2f deg',sensor_off(1));
        fprintf(LOG_FID,'\n elev_off = %6.2f deg',sensor_off(2));
        fprintf(LOG_FID,'\n roll_off = %6.2f deg',sensor_off(3));
        fprintf(LOG_FID,'\n Receiver offsets are forced to zero for single sensor case');
        
    case {'two_mic'}
        fprintf(LOG_FID,'\n sensor spacing = %6.2f m',sensor_space);
        % Unpack sensor directionality and print to log file
        fprintf(LOG_FID,'\n Sensor offsets');
        fprintf(LOG_FID,'\n azim_off = [ %6.2f %6.2f ] deg',sensor_off(1,1),sensor_off(1,2));
        fprintf(LOG_FID,'\n elev_off = [ %6.2f %6.2f ] deg',sensor_off(2,1),sensor_off(2,2));
        fprintf(LOG_FID,'\n roll_off = [ %6.2f %6.2f ] deg',sensor_off(3,1),sensor_off(3,2));
        fprintf(LOG_FID,'\n Receiver offsets');
        fprintf(LOG_FID,'\n Yaw = %6.2f deg',rad2deg.*receiver_off(1));
        fprintf(LOG_FID,'\n Pitch = %6.2f deg',rad2deg.*receiver_off(2));
        fprintf(LOG_FID,'\n Roll = %6.2f deg',rad2deg.*receiver_off(3));
        
    case {'cipicir'}
        fprintf(LOG_FID,'\n CIPIC Subject No =  %s',S_No); % Print CIPIC Subject No to the log file
end;

%Run the frequency dependent absorption model of the room with the parameter values as set above.
[len_source,p_isource,HRTF,n_sources] = roomsim_core(c,humidity,Fs,room_size,source_xyz,receiver_xyz...
    ,receiver_off,receiver,sensor_xyz,sensor_off,F_abs,B,air_F,smooth_F,Fc_HP,dist_F,order,H_length,H_filename);

if size(sensor_xyz,2)==1, % tests for single channel
    channels = 1; % Set number of channels for single sensor receiver
else,
    channels = 2; % Set number of channels for two sensor receivers i.e. two_mic, mithrir, cipicir
end;
H = zeros(H_length, channels, n_sources); % Allocate array for single or L&R impulse responses from each source

save_path=pwd; % Save pathname to present directory (folder)                       
cd('Impulse_response'); % Change directory to the Impulse_response directory (folder)
for ps=1:n_sources % For each parent source
    imp_file_name=[H_filename '_S' num2str(ps)]; % Compose the impulse response filename for primary source ps
    load(imp_file_name,'Fs','data'); % Load the sampling frequency and an impulse response.
    H(:,1:channels,ps)=data; % Pack up the impulse responses to send to the plotting routines.
end; % of ps counter loop for number of parent sources
cd(save_path); % Restore the previous directory (folder) path                  

source = zeros(3,max(len_source),n_sources); % Allocate array for image source co-ordinates
for ps=1:n_sources % For each parent source
    file_spec = ['Image_S' num2str(ps) '.mat']; % Form filename for file Image_S?.mat
    load(file_spec,'isource_xyz'); % Load an image source co-ordinates file saved by roomsim_core
    source(:,1:len_source(ps),ps) = isource_xyz(:,:); % Save image source co-ordinates in array source for plotting
    delete(file_spec); % This image source co-ordinates file not now needed so delete it.
end; % of ps counter loop for number of parent sources
clear isource_xyz; % Free up memory (NB This won't help Unix systems)

run_once=true; % Successful data acquisition, check and simulation run.

%------------------------------- Display the plots -----------------------------------

roomplot_imp(Fs,H,receiver); % Plot the impulse responses to each sensor

roomplot_magf(Fs,H,HRTF,receiver); % Plot the magnitude vs frequency responses to each sensor

%--------- 2/3D Plot of slice plane through the room and the image rooms ---------------
if plot_F2 % Display the receiver, source, image sources and image rooms as a 2D plan.
    roomplot_2D(c,Fs,room_size,source_xyz,receiver_xyz,receiver,sensor_xyz,H_length,source,p_isource);
end;

%--------- 3D Plot of the room and the image sources---------------
if plot_F3 % Display the receiver, source, image sources and image rooms in 3D
    roomplot_3D(room_size,source_xyz,receiver_xyz,receiver,sensor_xyz,source,p_isource);
end;
% drawnow; %Force completion of all previous figure drawing before continuing

%----------------- Save data for plotting to a MATLAB loadable file-----------------
file_spec='plot_*.mat';
title=[prefix 'Save data as a MAT file for later plotting'];
repeat=true;
while repeat,
    repeat=false; % Do once if correct filename and ext given
    beep;    
    save_path=pwd; % Save pathname to present directory (folder)                       
    cd('Plot_data'); % Change directory to the Plot_data directory (folder)
    [name path] = uiputfile(file_spec, title); %Display the dialogue box    
    cd(save_path); % Restore the previous directory (folder) path                  
    if ~any(name), % File select was cancelled, exit the while loop.
        fprintf(LOG_FID,'\n\n roomsim_run: Plot data has not been saved'); % Print to log file (avoids wait for user response)
        break; % Alternate return for cancel operation. No data saved to file. 
    end;
    filename = [path name]; % Form path+filename
    [pathstr,name,ext,versn] = fileparts(filename);
    if ~strcmp(lower(ext),'.mat'),
        h=errordlg('You must specify a *.mat extension',error_title);
        beep;
        uiwait(h);
        repeat=true; % Force resubmit of filename
    else,
        switch lower(ext),
            case '.mat'
                % Save relevant plot variables to a ".mat" file using the functional form of SAVE (NB Non-EVAL code for compilation)
                save(filename, 'c','Fs','room_size','source_xyz','receiver_xyz','receiver_off','receiver','sensor_xyz'...
                             ,'H_length','H_filename','source','p_isource','H','HRTF','head_width','alph');
                fprintf(LOG_FID,'\n\n roomsim_run: Plot data has been saved to %s', [path name]); % Print to log file (avoids wait for user response)
            otherwise,
                h=errordlg('Data file extension not recognised, exiting',[prefix 'save error']);
                beep;
                uiwait(h);
                return;
        end;
    end;
end; % of while loop to trap missing .mat extension
%------------------------------ End of roomsim_run.m ------------------------------
