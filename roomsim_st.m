function roomsim_st(param_file_path,BRIRs_dir,fig_path)

global deg2rad
global rad2deg
global LOG_FID

log_path = fullfile(BRIRs_dir,'log.txt');
LOG_FID = fopen(log_path,'w');

head_width=0.145; % Value is CIPIC average head width rounded to nearest mm.

%read setting text files
[Fs,humidity,temperature,order,H_length,H_filename,air_F,smooth_F,Fc_HP,plot_F2,plot_F3,dist_F,alpha_F...
 ,c,room_size,receiver_xyz,receiver_off,receiver,sensor_space,sensor_off,S_No,source_polar,F_abs,A]...
    =text_setup(param_file_path);

n_source = size(source_polar,2);

T=1/Fs; % Sampling period
nyquist=Fs/2;
Fs_c = Fs/c; % Samples per metre

deg2rad=pi/180; % GLOBAL Conversion factor degrees to radians
rad2deg=180/pi; % and radians to degrees
% Create inertial axes to body axis transformation matrix 
receiver_off=deg2rad.*receiver_off;
[tm]=tm3DR(receiver_off(1),-receiver_off(2),receiver_off(3)); % NB -ve sign for pitch adjusts for MATLAB rotational conventions


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


sensor_space = head_width; % Separation of sensor pair is head_width metres.
sensor_xyzp(:,1) = [0;+sensor_space/2;0]; % Coordinates of Left sensor in receiver axes.
sensor_xyzp(:,2) = [0;-sensor_space/2;0]; % Coordinates of Right sensor in receiver axes.

% Rotate the receiver axes to align with room axes (body to room axes transformation)
sensor_xyzp=tm'*sensor_xyzp; % Body axes to inertial axes transformation
sensor_xyz(:,1) = receiver_xyz + sensor_xyzp(:,1); % Add L sensor coordinates and receiver origin to give room coords of L sensor
sensor_xyz(:,2) = receiver_xyz + sensor_xyzp(:,2); % Add R sensor coordinates and receiver origin to give room coords of R sensor         

B=realsqrt(1-A); % Calculate the frequency dependent pressure reflection coefficients (NB +ve for air to hard surface interface)

RT60_estimator = 'Norris_Eyring'; %The Norris_Eyring RT60 estimator
                                  %gives a shorter estimate than
                                  %the Sabine ones.
m_air = 5.5E-4*(50/humidity)*(F_abs/1000).^(1.7); % Valid Ranges
                                                  % are: relative
                                                  % humidity 20%< h
                                                  % <70%, 1500<
                                                  % F_abs <10000
                                                  % Hz.
delay_s = zeros(2,2);         
for source_i = 1:n_source
    dist_s(1) = norm(source_xyz(:,source_i)-sensor_xyz(:,1),2); %Distance (m) between primary source and receiver left sensor
    dist_s(2) = norm(source_xyz(:,source_i)-sensor_xyz(:,2),2); %Distance (m) between primary source and receiver right sensor    delay_s(source_i,:) = Fs_c*dist_s; % L & R delays in samples
                                % = (Samples per
                                % metre)*Distance
end

[RT60 MFP]= reverberation_time(c,room_size,A,F_abs,m_air,RT60_estimator); % Estimate a room reverberation time RT60 WITH air absorption
[H_length, order]=check_length_order(Fs, c, H_length, order, RT60, delay_s, room_size, 1);

alph=floor(mean(64*B,1)');
roomplot_st(room_size,source_xyz,receiver_xyz,receiver_off,receiver,sensor_xyz,head_width,alph,H_filename);
savefig(fig_path);
[len_source,p_isource,HRTF,n_sources] = roomsim_core_st(c,humidity,Fs,room_size,source_xyz,receiver_xyz...
                                                  ,receiver_off,receiver,sensor_xyz,sensor_off,F_abs,B,air_F,smooth_F,Fc_HP,dist_F,order,H_length,H_filename,BRIRs_dir);
end