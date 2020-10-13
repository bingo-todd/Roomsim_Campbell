function [len_source,p_isource,HRTF,n_sources]=roomsim_core(c,humidity,Fs,room_size,source_xyz,receiver_xyz,receiver_off,receiver,sensor_xyz,sensor_off...
    ,F_abs,B,air_F,smooth_F,Fc_HP,dist_F,order,H_length,H_filename);
% Usage: [len_source,p_isource,HRTF,n_sources]=roomsim_core(c,humidity,Fs,room_size,source_xyz,receiver_xyz,receiver,sensor_xyz,sensor_off...
%   ,F_abs,B,air_F,smooth_F,Fc_HP,dist_F,order,H_length,H_filename);
% roomsim_core.m is a MATLAB m-code implementation of a mirror image model of the impulse response from an 
%   omni-directional source to a receiver (sensor, two sensors or two ears of a head) in a "shoebox" room.
% It incorporates frequency dependent absorption at the reflective surfaces and in the airspace of the room.
% The simulation of the head utilises Head Related Transfer Function (HRTF) data
%   actually Head Related Impulse Response (HRIR) data provided from measurements made either;
%   1)on a Kemar mannequin at MIT. (http://xenia.media.mit.edu/~kdm/hrtf.html ,Dec 2002)
%   or
%   2)on real subjects and a Kemar at University of California, Davis. (http://interface.cipic.ucdavis.edu ,Dec 2002).
% The kernel of the image method in Roomsim is derived from the Fortran program reported by Allen and Berkley,1979 [A6]).
% -------------------------------------------------------------------------
% Copyright (C) 2003  Douglas R Campbell and Kalle J Palomaki
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
%-------------------------------------------------------------
% The original version of this MATLAB implementation was provided by Kalle Palomaki 
%   (Helsinki University of Technology, Finland), and his colleagues
%   working on the EC TMR SPHEAR project at the University of Sheffield.
%   The code was subsequently modified and incorporated into this menu driven program by Douglas R. Campbell 
%   (University of Paisley, Scotland, UK) during Sept2002/Mar 2003.
%--------------------------------------------------------------------------------------------------------------
% References for image method program code:
% (A5) P M Peterson, "Simulating the response of multiple microphones to a single acoustic source in a reverberant room", JASA 80(5),1986, 1527-1529.
% (A6) J B Allen and D A Berkley, "Image method for efficiently simulating small-room acoustics", JASA 65(4), 1979, 943-950.
%-----------------------------------------------------------------------------------------------------------------

% Functions called: getSENSORpulse.m, getNearestMITpulse.m,
% getNearestUCDpulse.m, freq_to_imp.m

%*** Global Declarations ***
global deg2rad; % Conversion factor degrees to radians
global rad2deg; % Conversion factor radians to degrees

global LOG_FID; % Identifier of logfile. Defined in roomsim.m
global S3D_L S3D_R; % SENSOR impulse response data for Left (or single) and Right sensor. Loaded in roomsim_setup.m
global hrir_l hrir_r;% CIPIC impulse responses left and right. Loaded in roomsim_setup.m
global H3D; % MIT impulse response data. Loaded in roomsim_setup.m
global SPEED_FACTOR; % Used to estimate time to compute n_images. Defined in speed_estimator.m called in roomsim.m, updated here.
%***************************

% Declare and initialise rotational transform matrices
tm_room_receiver=eye(3);
tm_receiver_sensor(:,:,1)=eye(3);
tm_receiver_sensor(:,:,2)=eye(3);

% Common message texts for roomsim_core 
prefix='roomsim_core: ';
terminate_msg=[prefix 'Program terminating']; % Termination title for error dialogue box
error_title=[prefix 'Error'];

%Initialise constants
Two_pi=2*pi; % Compute here for efficiency
T=1/Fs; % Sampling Period
nyquist=Fs/2; % Half sampling frequency
Fs_c = Fs/c; % Samples per metre
F_abs=[0 F_abs nyquist]'; % Extend F_abs to include the 0 and Fs/2 Hz values and transpose to a column vector

%Unpack the six surface reflectances
bx1=B(:,1); bx2=B(:,2); by1=B(:,3); by2=B(:,4); bz1=B(:,5); bz2=B(:,6);

%Unpack order
order_x = order(1); order_y = order(2); order_z = order(3);

% Unpack Receiver (two_mic, mithrir or cipicir) orientation in room axes system
yaw_rad=receiver_off(1); pitch_rad=receiver_off(2); roll_rad=receiver_off(3);

% Set up inertial (room) axes to body (receiver) axes transformation matrix
[tm_room_receiver]=tm3DR(yaw_rad,-pitch_rad,roll_rad);

%------------- Specific setups for each receiver case -------------------------------
switch receiver %  Identify receiver system
    case {'one_mic','two_mic'}
        % Unpack sensor directionality
        azim_off=deg2rad.*sensor_off(1,:); %Sensor elevation offset from receiver axes system
        elev_off=deg2rad.*sensor_off(2,:); %Sensor azimuth offset from receiver axes system
        roll_off=deg2rad.*sensor_off(3,:); %Sensor roll offset from receiver axes system
        
        if strcmp(receiver,'one_mic'),
            Channels=1;
            % Compute matrix to transform source coordinates from receiver to sensor axes   
            % NB -ve sign for elev_off (pitch) adjusts for MATLAB rotational conventions                          
            [tm_receiver_sensor(:,:,Channels)]=tm3DR(azim_off(Channels),-elev_off(Channels),roll_off(Channels));
            
        else, % 'two_mic'
            Channels=2; % Loop parts of the one_mic code twice to handle two sensors.
            for sensor_No = 1:Channels, % For each of up to two possible receiver sensors
                % Compute matrix to transform source coordinates from receiver to sensor axes   
                % NB -ve sign for elev_off (pitch) adjusts for MATLAB rotational conventions                          
                [tm_receiver_sensor(:,:,sensor_No)]=tm3DR(azim_off(sensor_No),-elev_off(sensor_No),roll_off(sensor_No));
            end;
        end;
        
    case {'mithrir','cipicir'}, 
        % Set head "blind" region for the dummy or real head data from CIPIC or MIT and convert to rads
        if strcmp(receiver,'mithrir'),
            min_elev_sensor=-40.*deg2rad;
            max_elev_sensor=-140.*deg2rad;
        else, % 'cipicir'
            min_elev_sensor=-45.*deg2rad;
            max_elev_sensor=-129.375.*deg2rad;
        end;
        % Unpack sensor directionalities 
        sensor_xyz=receiver_xyz; % Sensor reference point for HRTFs is receiver reference point
        Channels=1; % Because MIT and CIPIC code sections don't need to loop for each ear.
    otherwise,
        h_err=errordlg([error_title 'Unknown receiver set up.'],terminate_msg);
        beep;
        uiwait(h_err);
        return
end;%of setups for each receiver case

%------------------------- Initialise Air attenuation model ------------
% Partial calculation of attenuation of pressure wave (part due to air absorption)
% done here for efficiency, then used within CASE selection of receiver type.
if air_F  % Include the absorption due to air
    % Estimate the frequency dependent pressure absorption coeff for air, m= 2*alpha (neper/m)
    m_air = 5.5E-4*(50/humidity)*(F_abs.*1E-3).^(1.7);
    % Compute the column vector of frequency dependent attenuation factors for one metre travelled in air
    atten_air= exp(-0.5*m_air); 
end;

%------------------------- Set up Interpolation/Smoothing Filter ------------
% For use when HRTF is not present (Ref A5) to take account of impulses not centered on a sampling instant
Fc = 0.9*nyquist; %Smoothing Filter Cutoff marginally below Fs/2, >40dB attenuation close to Fs/2.
N_smooth = 32; % Order of FIR smoothing filter
Fc_Fs=Fc.*T; % Compute here for efficiency
Two_Fc=2.*Fc; % Compute here for efficiency
Tw = N_smooth*T; % Window duration (seconds)
Two_pi_Tw=Two_pi./Tw; % Compute here for efficiency
t=[-Tw/2:T:Tw/2]'; % Filter time window NB column vector of length (N_smooth+1) symmetrical about t=0
pad_smooth = zeros(N_smooth,1); % Column vector of zero values for post-padding in smoother convolution

%------------------------- Set up High-pass Filter ------------
%Used in Allen & Berkley (and probably CoolEdit/Adobe Audition).This appears to be an attempt to overcome an 
%accumulating DC offset due (I guess) to absence of pressure equalisation (i.e. leakage) in the "ideal" room.
%Probably not necessary if the sampling frequency is sufficently high e.g. Fs=10*fh
if Fc_HP > 0, % Compute coefficients of the Allen & Berkley 2nd order high-pass filter
    [b_HP,a_HP] = hi_pass2(Fc_HP,Fs);
    
    %IF active these 3 lines of code use the 4th order Butterworth High-pass filter of the utilities suite.
    %   load HP_coeffs;
    %   b_HP=B;
    %   a_HP=A;
end;

%------------------ Set up the image model ------------------
%Compute these values here for efficiency 
Two_Lx=2*room_size(1); % Twice Length (Depth)
Two_Ly=2*room_size(2); % Twice Width
Two_Lz=2*room_size(3); % Twice Height

% isource_ident (8 by 3 array) codes the eight permutations of x+/-xp,y+/-yp,z+/-zp (the source to receiver vector components)
% where [-1 -1 -1] identifies the parent source.
isource_ident=[-1 -1 -1; -1 -1 1; -1 1 -1; -1 1 1; 1 -1 -1; 1 -1 1; 1 1 -1; 1 1 1];
surface_coeff=[0 0 0; 0 0 1; 0 1 0; 0 1 1; 1 0 0; 1 0 1; 1 1 0; 1 1 1]; % Includes/excludes bx,by,bz depending on 0/1 state.

%Allocate power indice modifiers here for efficiency
qq=surface_coeff(:,1); %  for bx1
jj=surface_coeff(:,2); %  for by1
kk=surface_coeff(:,3); %  for bz1

%Dimension and allocate arrays
n_sources = size(source_xyz,2); % Number of parent sources (size finds number of columns ie sources)
n_isources = (2.*order_x+1).*(2.*order_y+1).*(2.*order_z+1).*8; %Maximum number of image sources
p_isource = zeros(n_isources,n_sources,2); % Allocate array for image source maximum pressure value, one per sensor (DIM(3)=1 is L).
HRTF=[]; %Declare array HRTF

% Compute parameters for converting surface frequency response to impulse response (here for efficiency)
F_abs_N=F_abs./nyquist; % Normalise the standard absorption frequency range for surfaces, (0 to 1) = (0 to Fs/2)
N_refl=512; % Required length of FIR filter modelling impulse response of surface(+air)
Half_I=fix(N_refl./2); % Half length of FIR filter model
Half_I_plusone = Half_I+1; % Half length shift required for FIR filter model of surface impulse response
h_refl = zeros(N_refl+1,1); % Declare impulse response column vector of length N_refl+1 samples
pad_refl = zeros(N_refl,2); %  Two column vector of zero values for post-padding in reflection convolution with hrir
RR=length(F_abs_N); % Number of data values submitted
delta_X=(F_abs_N(RR)-F_abs_N(1))./Half_I; % Grid points for local interpolation
% interp_x=[0: 1./Half_I :1].'; % Generate a column vector of interpolation grid points
window = 0.5.*(1 - cos(2*pi*(0:N_refl).'./N_refl)); % Compute the (N_refl+1) point column vector Hann window

%-------- Calculate the impulse responses from each primary source location ---------------
% Keep the user informed about progress.
msg_title=[prefix 'Generating Images'];
wait_msg_img = ['of ' num2str(n_sources) ' primary source(s), please wait...'];
beep;
h_parent = waitbar(0.1,wait_msg_img,'name',msg_title); % Increment the waitbar a little to show its started

for ps=1:n_sources, %Compute image locations and impulse responses for each parent source
    
    isource_xyz = zeros(3,n_isources); % Allocate array for image source co-ordinates
    refl = zeros(6,n_isources); % Allocate array for surface reflection impulse amplitude (MEMORY CRITICAL POINT)
    
    %---------- Compute these values here for efficiency ---------------
    xx=isource_ident(:,1)*source_xyz(1,ps); % partial x coord of image.
    yy=isource_ident(:,2)*source_xyz(2,ps); % partial y coord of image.
    zz=isource_ident(:,3)*source_xyz(3,ps); % partial z coord of image. 
    xx_yy_zz=[xx yy zz]';
    
    wait_msg_img = ['Source ' num2str(ps) ' of ' num2str(n_sources) ' Primary Source(s). Please wait...'];
    waitbar(ps/n_sources,h_parent,wait_msg_img,'name',msg_title); % Increment the waitbar to indicate on slow machines that we're calculating
    
    tic;  % Start TIMER.
    
    n_images=0; %Clear n_images, used to count the number of significant images of each parent source

    %------------- Calculate the amplitude and location of each of the image sources ------------------   
    % Computes the frequency dependent surface reflection and coordinates and distance for each image
    % Overall surface reflection in each octave band (1:6), coordinates, and distance for each image source n_images
    % computed using refl(:,n_images)=bx1(:)^abs(n-q)*bx2(:)^abs(n)*by1(:)^abs(l-j)*by2(:)^abs(l)*bz1(:)^abs(m-k)*bz2(:)^abs(m)
    % with partials of this expression pre-computed for efficiency.   
    for n=-order_x:order_x,
        bx2_abs_n=bx2.^abs(n); % Compute here for efficiency
        Two_n_Lx=n*Two_Lx; % Compute here for efficiency
        for l=-order_y:order_y,
            bx2y2_abs_nl=bx2_abs_n.*(by2.^abs(l)); % Compute here for efficiency
            Two_l_Ly=l*Two_Ly; % Compute here for efficiency
            for m=-order_z:order_z,
                bx2y2z2_abs_nlm=bx2y2_abs_nl.*(bz2.^abs(m)); % Compute here for efficiency
                Two_m_Lz=m*Two_Lz; % Compute here for efficiency
                Two_nlm_Lxyz = [Two_n_Lx; Two_l_Ly; Two_m_Lz]; % Concatenate here for efficiency

                for permu=1:8,
                    n_images=n_images+1; %Accumulate count of the image sources
                    % calculate xyz coordinates of image source n_images of parent source ps
                    isource_xyz(:,n_images)=Two_nlm_Lxyz - xx_yy_zz(:,permu);
                    % Calculate the delay in samples, using 3D Pythagoras, from the receiver origin to each parent and image source.
                    % NB Used only for checking delay <= H_length, hence can use receiver origin rather than sensor coordinates.
                    delay = Fs_c.*norm((isource_xyz(:,n_images)-receiver_xyz(:)),2); % delay in samples = (Samples per metre)*Distance
                    if delay <= H_length, % compute only for image sources within impulse response length
                        refl(:,n_images)=bx1.^abs(n-qq(permu)).*by1.^abs(l-jj(permu)).*bz1.^abs(m-kk(permu)).*bx2y2z2_abs_nlm;                    
                        if sum(refl(:,n_images)) < 1E-6, % (NB refl always +ve for air to surface, otherwise need abs here)
                            n_images=n_images-1; % Delete image sources with a sum of reflection coeffs below 1*10^-6 i.e. -120dB
                        end;
                    else,
                        n_images=n_images-1; % Delete image sources with a delay > impulse response length H_length
                    end; % of decimation of low level and distant sources
                end; % of permu counter loop
                
            end; % of m counter loop
        end; %of l counter loop
    end; % of n counter loop and generation of n_images image source(s)
    
    %---------- Compute the complete impulse response, Primary source(s) to Sensor ---------------
    isource_xyz = isource_xyz(:,1:n_images); % Re-Allocate array for image source co-ordinates (discard trailing zero values)
    refl = refl(:,1:n_images); % Re-Allocate array for surface reflection impulse amplitude (discard trailing zero values)
    hrir=[]; % Declare array for MIT & CIPIC HRTF impulse responses 
    sensor_ir=[]; % Declare array for Sensor impulse responses
    
    % Allocate array "data" (one or two channel (column) format for audio files)
    % make it long enough to hold impulse response length H_length.
    if strcmp(receiver,'one_mic'),
        data = zeros(H_length,1); % Allocate for one channel receiver
    else,
        data = zeros(H_length,2); % Allocate for two channel receiver
    end;
    
    % Keep the user informed about progress. Increment the waitbar a little to show it has started
    msg_title=[prefix 'Generating'];
    wait_msg_imp = ['Impulse Response for Source ' num2str(ps) ': May take ' num2str(ceil(SPEED_FACTOR.*n_images)) ' seconds. Please wait ...'];
    h_wbar = waitbar(0.1,wait_msg_imp,'name',msg_title);
    inv_n_images = 1/n_images; % Compute here for efficiency
    step = ceil(n_images/5); % Waitbar step size, 5 steps displayed
    
    for is = 1:n_images, % for each of the n_images image sources
        if mod(is,step)==0, % Update the waitbar in steps of size step
            waitbar(is*inv_n_images,h_wbar); % Increment the waitbar
        end;    
        
        for sensor_No = 1:Channels, % For each of up to two possible receiver sensors
            % Pad column vector b_refl to same length as F_abs_N by estimating the 0 and Fs/2 Hz values
            b_refl = [refl(1,is); refl(:,is); refl(6,is)]; % NB reloaded for each sensor sensor_No loop
            
            xyz=isource_xyz(:,is)-sensor_xyz(:,sensor_No); % Position vector from sensor_No to source(is)                      
            dist = norm(xyz,2); % Distance (m) between image source(is) and sensor_No
            
            % Pressure wave amplitude at sensor (Ps) dist metres from image-source (Po) created by surface 
            % with reflection coefficient refl is Ps = Po*(refl/dist)*exp(0.5*m*dist)
            if dist_F & dist >1, % Include effect of distance (ie. 1/R) attenuation.
                b_refl = b_refl./dist; % Apply distance effect
                % No attenuation is applied to sources within 1 metre of receiver i.e. Avoids amplification when 0<dist<1.
                % and avoids divide by zero when dist=0 i.e. source coincident with receiver
            end;
            
            % Include the absorption due to air and complete Ps = Po*(refl/dist)*exp(0.5*m*dist) = Po*b_refl*atten_air.^dist
            if air_F & dist >1, % Compute a set of distance dependent pressure reflection coefficients for air
                b_refl=b_refl.*(atten_air.^dist);
            end;
            
            %------------ Replacement for fir2 ----------------------------
            % Avoids requiring users to install SIGNAL toolbox (also faster since no checking)
            % Estimate the values of reflection coefficient at the linear interpolated grid points using local interpolator
            % F_abs_N and b_refl must be column vectors of equal length
%             b_refl = interp1q(F_abs_N,b_refl,interp_x); % Replaced by faster local code

            %------ Local linear interpolation to a uniform grid ----------
            %b_refl and F_abs_N are same length, elements of F_abs_N must be monotonic ascending
            % but may be non-uniformly spaced.
            r=1;
            nn=1;
            ndx=nn.*delta_X;
            while r<RR,
                while ndx < F_abs_N(r+1),
                    yy(nn)= b_refl(r)+(ndx-F_abs_N(r)).*(b_refl(r+1)-b_refl(r))./(F_abs_N(r+1)-F_abs_N(r));
                    nn=nn+1;
                    ndx=nn.*delta_X;
                end;
                r=r+1;
            end;
            b_refl=[b_refl(1); yy(:); b_refl(RR)];
            %-- End of Local interpolation code --------

            % Half spectrum of data b_refl is now made conjugate-symmetric about Nyquist frequency,
            % and last data point discarded to make periodic spectrum corresponding to a real data sequence.
            b_refl = [b_refl; conj(b_refl(Half_I:-1:2))]; 
            % Transform surface data from frequency response to impulse response.
            h_refl = real(ifft(b_refl,N_refl)); % IFFT to calculate impulse response column vector of length N_refl samples
            % Make the impulse realisable (half length shift) and Hann window it 
            h_refl = window.*[h_refl(Half_I_plusone:N_refl); h_refl(1:Half_I_plusone)];
            %---------- End of replacement for FIR2 ----------
            
            % Check audibility at the receiver of each image source 
            audible=false;
            if (n_images==1) | max(abs(h_refl(1:Half_I_plusone))) >= 1E-5,
                % For primary sources, and image sources with impulse response peak magnitudes >= -100dB (1/100000)
                % This provides some deletion of low level sources but allows for superimposed low level sources
                % to exceed the 60 dB threshold (eg 10 @ -80dB arriving together)
                
                if dist < eps, % Source is coincident with sensor and angles are irrelevant
                    hrir = 1;
                    sensor_ir = 1;
                else,% Calculate the bearing of the image source from sensor sensor_No
                    % Calculate position vector from the receiver to an image source 
                    % in a "body fixed" axes system (NB MATLAB conventions apply)
                    [xyz]=tm_room_receiver*xyz;% Rotational axes transformation, room to receiver axes
 
                    switch receiver, % Select receiver system
                        
                        case {'one_mic','two_mic'}, % Single sensor and sensor pair only
                            % Calculate position vector from each sensor location to each image source 
                            % in sensor axes system (NB MATLAB convention)
                            [xyz]=tm_receiver_sensor(:,:,sensor_No)*xyz;% Rotational axes transformation, receiver to sensor axes coords
                            
                            % Calculate bearing of source(az,el) in Sensor body axes
                            hyp = sqrt(xyz(1)^2+xyz(2)^2); % Distance (m) between sensor_No and proj of image source(is) on xy plane 
                            elevation = atan(xyz(3)./(hyp+eps)); % Calculate -pi/2 <= elevation <= +pi/2 rads
                            azimuth = atan2(xyz(2),xyz(1)); % Calculate -pi <= azimuth <= +pi rad
                            
                            audible=true; % source (image) is audible
                            % Get the impulse response (time runs down the column vector) for this azimuth and elevation from a cell array
                            if sensor_No==1, % Get the left sensor impulse response
                                [sensor_ir]=getSENSORpulse(azimuth,elevation,S3D_L);
                            elseif sensor_No==2, % sensor_No=2 so Get the right sensor impulse response
                                [sensor_ir]=getSENSORpulse(azimuth,elevation,S3D_R);
                            else,
                                h=errordlg('Only one or two sensors supported','roomsim_core: sensor error');
                                beep;
                                uiwait(h);
                                return;
                            end;
                            
                        case 'mithrir', % MIT Kemar only
                            % Calculate elevation and azimuth from the MIT Kemar location to an image source 
                            % in a "head fixed" axes system (NB MATLAB conventions apply)
                            
                            % Calculate bearing of source(az,el) in MIT receiver axes
                            hyp = sqrt(xyz(1)^2+xyz(2)^2); % Distance (m) between sensor_No and proj of image source(is) on xy plane 
                            elevation = atan2(xyz(3),hyp); % -pi <= elevation <= +pi rads, NB for checking audibility only
                            
                            % MIT: no data for sources -140 <elevation < -40 deg, they are assumed zero
                            if (elevation >= min_elev_sensor)|(elevation <=max_elev_sensor), 
                                audible=true; % source (image) is audible
                                elevation = atan(xyz(3)./(hyp+eps)); % -pi/2 <= elevation <= +pi/2 rads
                                azimuth = atan2(xyz(2),xyz(1)); % Calculate -pi <= azimuth <= +pi rad
                                % Quantise the elevations and azimuths to nearest angle in the MIT set
                                % (-pi <= azimuth <= +pi rads, -40*pi/180 <= elevation <= +pi/2 rads)
                                % and get the HRIR for this i'th image source
                                % NB azimuth for Kemar measurements was +ve CW so invert sign.
                                % NB MIT HRIR starts with an ~3 sample offset at elevation=0 azimuth=+/-pi/2 rads
                                [hrir] = getNearestMITpulse(elevation,-azimuth,H3D); 
                            end;
                            
                        case 'cipicir', % CIPIC head only
                            % Calculate elevation and azimuth of each primary source in CIPIC "head fixed" co-ordinate system

                            % Calculate bearing of source(az,el) in CIPIC receiver axes
                            hyp = sqrt(xyz(1)^2+xyz(2)^2); % Distance (m) between sensor_No and proj of image source(is) on xy plane 
                            elevation = atan2(xyz(3),hyp); % Calculate -pi <= elevation <= +pi rad
                            
                            % CIPIC: no data for sources -129.375 <elevation < -45 deg, they are assumed zero
                            if (elevation >= min_elev_sensor)|(elevation <=max_elev_sensor),
                                audible=true; % source (image) is "audible"
                                azimuth = atan(xyz(2)./(xyz(1)+eps)); % -pi/2 <= azimuth <= +pi/2 rads
                                
                                % Quantise the elevations and azimuths to nearest angle in the CIPIC set
                                % (-pi/2 <= azimuth <= +pi/2 rads, -pi/4 <= elevation <= +230*pi/180 rads)
                                % and get the HRIR for this i'th image source
                                % NB azimuth for CIPIC measurements was +ve CW so invert sign.
                                % NB CIPIC HRIR starts with an 12~30 sample offset
                                [hrir(:,1)] = getNearestUCDpulse(-azimuth,elevation,hrir_l);
                                [hrir(:,2)] = getNearestUCDpulse(-azimuth,elevation,hrir_r);
                            end;
                    end; %--------- End of Receiver system (Switch Case) select -------------------------------
                end; % Of test audibility and get impulse responses for audible images
                
                if audible==true, % Image source is audible to this sensor so include in complete impulse response                      
                    delay = Fs_c*dist; % delay in samples = (Samples per metre)*Distance
                    rdelay=round(delay); % Extract integer delay (concatenated later with impulse response)
                    
                    switch receiver, % Select receiver system
                        case {'one_mic','two_mic'}, % Single sensor and sensor pair only
                            % This routine will be entered twice for the two_mic case
                            if smooth_F, % Include smoothing filter
                                t_Td=t-(delay-rdelay).*T; % Take account of fractional delay  -0.5 < D < +0.5 sample period
                                hsf=Fc_Fs*(1+cos(Two_pi_Tw.*(t_Td))).*sinc(Two_Fc*(t_Td)); % Compute delayed filter impulse response for sensor
                                
                                %----- Do the convolutions using the FILTER primitive for speed, shortest sequence is first parameter.
                                h_refl=[h_refl; pad_smooth]; % Append filter_length-1 zeros so convolution length is data_length+impulse_length-1
                                h = filter(hsf, 1, h_refl); % Convolve channel signals
                            else, % No smoothing
                                h = h_refl;
                            end;
                            
                            len_h=length(h); % length of impulse response modelling image source response
                            adjust_delay = rdelay - ceil(len_h./2); % Half length shift to remove delay due to impulse response
                            
                            sensor_ext=[sensor_ir; zeros(len_h,1)]; % Append filter_length-1 zeros so convolution length is data_length+impulse_length-1
                            h=filter(h,1,sensor_ext);
                            
                            len_h=length(h);
                            
                            % adjust_delay = rdelay - ceil(len_h./2); % Half length shift to remove delay due to impulse response
                            
                            %--- Accumulate the impulse responses from each image source within an array of length H_length ---
                            if adjust_delay < 0,
                                start_index_Hp = max(adjust_delay+1,1);
                                stop_index_Hp = min(adjust_delay+1+len_h,H_length);
                                start_index_h = max(-adjust_delay,1);
                                stop_index_h = start_index_h + (stop_index_Hp - start_index_Hp);                             
                            else,
                                start_index_Hp = max(adjust_delay+2,1);
                                stop_index_Hp = min(adjust_delay+len_h+1,H_length);
                                start_index_h = max(-adjust_delay,1);
                                stop_index_h = start_index_h + (stop_index_Hp - start_index_Hp);
                            end;
                            %Add whole or part of impulse response
                            data(start_index_Hp:stop_index_Hp, sensor_No)= data(start_index_Hp:stop_index_Hp, sensor_No) + h(start_index_h:stop_index_h);
                            
                            p_isource(is,ps,sensor_No)=max(abs(h)); % Maximum of impulse response in channel(s) (used for plotting image source strength)
                            
                        case {'mithrir','cipicir'}, % For the dummy or real head data from MIT or CIPIC                   
                            adjust_delay = rdelay - Half_I_plusone; % Half length shift of surface impulse response                           
                            hrir_ext=[hrir; pad_refl]; % Append filter_length-1 zeros so convolution length is data_length+impulse_length-1
                            for ear_No=1:2, % For both ears (ear_No=1 is left, ear_No=2 is right)
                                % Convolve the reflection and head related impulse responses (hrir) using the FILTER primitive for speed.
                                h(:,ear_No)=filter(h_refl,1,hrir_ext(:,ear_No)); % Convolve
                                
                                %--- Accumulate the impulse responses at each ear from each image source within an array of length H_length ---                       
                                len_h=length(h(:,ear_No)); %
                                if adjust_delay < 0,
                                    start_index_Hp = max(adjust_delay+1,1);
                                    stop_index_Hp = min(adjust_delay+1+len_h,H_length);
                                    start_index_h = max(-adjust_delay,1);
                                    stop_index_h = start_index_h + (stop_index_Hp - start_index_Hp);
                                else,
                                    start_index_Hp = max(adjust_delay+2,1);
                                    stop_index_Hp = min(adjust_delay+len_h+1,H_length);
                                    start_index_h = max(-adjust_delay,1);
                                    stop_index_h = start_index_h + (stop_index_Hp - start_index_Hp);
                                end;
                                %Add whole or part of the impulse response
                                data(start_index_Hp:stop_index_Hp,ear_No)= data(start_index_Hp:stop_index_Hp,ear_No) + h(start_index_h:stop_index_h,ear_No);
                                
                            end; % of ear_No loop                            
                            p_isource(is,ps,:)=max(abs(h),[],1); % Max's of impulse response in L & R channels (used for plotting image source strength)
                            
                    end;%-------------------- End of Receiver system (Switch Case) select -------------------------------
                    
                end; % of Check audibility etc
                
            end; % of trap low amplitude image sources
            
        end; % of sensor_No loop
        
    end; % of is counter loop for number of image sources
    
    tim_core=toc; % Stop TIMER.
        
    close(h_wbar); % Close the current waitbar displaying progress through the image sources
    
    SPEED_FACTOR = tim_core./n_images; % Update the SPEED_FACTOR for estimating run time for core process
    fprintf(LOG_FID,'\n\n Number of Images = %i for Source %i . Time taken was %6.2f seconds',n_images,ps,tim_core); % Print No. of images for each parent source to the logfile
    
    len_source(ps) = size(isource_xyz,2); % Keep track of length of the impulse response for each primary source
    
    if Fc_HP > 0, % ARMA High-pass filter the left channel impulse response (Allen and Berkley used Fc_HP=100 Hz)
        data(:,1) = filter(b_HP,a_HP,data(:,1));
        if ~strcmp(receiver,'one_mic'), % for two-sensor cases
            data(:,2) = filter(b_HP,a_HP,data(:,2)); % Do the right channel also.
        end;
    end;
    
    % Save the sampling frequency and one mono or L&R pair of impulse responses per parent source
    % in folder Impulse_response as a Roomsim audio format MAT file named H_filename_S1, H_filename_S2, etc.
    imp_file_name=[H_filename '_S' num2str(ps)]; % Compose the impulse response filename for primary source ps
    save_path=pwd; % Save pathname to present directory (folder)                       
    cd('Impulse_response'); % Change directory to the Impulse_response directory (folder)
    save(imp_file_name,'Fs','data'); % NB Explicit naming and non-eval code for compilation as stand-alone exe
    cd(save_path); % Restore the previous directory (folder) path                  
    
    % Print name of impulse response file of each parent source to the logfile
    fprintf(LOG_FID,'\n\n Impulse response saved to file %s ',imp_file_name);
    
    % Save image source co-ordinates for plotting in a MAT file named Image_S1, Image_S2, etc.
    save(['Image_S' num2str(ps)],'isource_xyz'); % Doing this to reduce large array memory requirements
    
    % Get the hrir from each parent source to each sensor
    % Used for comparison plots of the magnitude of the room frequency response at a sensor
    %  cf. frequency response or HRTF at that sensor corresponding to each parent source location.
    switch receiver, % Select receiver system
        case {'one_mic','two_mic'},
            %Sensor is present so calculate elevation and azimuth of each primary source in MATLAB co-ordinate system
            for sensor_No = 1:Channels, % For each of up to two possible receiver sensors
                xyz=source_xyz(:,ps)-sensor_xyz(:,sensor_No); % Position vector from sensor_No to source(is)                      
                [xyz]=tm_room_receiver*xyz; % Rotational axes transformation room to receiver axes
                
                % Adjust for offset angles of sensor_No
                [xyz]=tm_receiver_sensor(:,:,sensor_No)*xyz; % Rotational axes transformation receiver to sensor axes coords
                
                % Convert to angular coordinates of source(az,el) in Sensor body axes
                hyp = sqrt(xyz(1)^2+xyz(2)^2); % Distance (m) between sensor_No and proj of image source(is) on xy plane 
                elevation=atan(xyz(3)./(hyp+eps)); % Calculate -pi/2 <= elevation <= +pi/2 rads
                azimuth = atan2(xyz(2),xyz(1)); % Calculate -pi <= azimuth <= +pi rad
                
                % Quantise the elevations and azimuths to nearest angle in the sensor set 
                %   and get the Impulse Response for this i'th image source
                if sensor_No==1, % Get the left sensor impulse response
                    [hrir(:,1)]=getSENSORpulse(azimuth,elevation,S3D_L);
                elseif sensor_No==2, % sensor_No=2 so Get the right sensor impulse response
                    [hrir(:,2)]=getSENSORpulse(azimuth,elevation,S3D_R);
                end;
            end; % of sensor_No loop
            
        case 'mithrir', % Calculate elevation and azimuth of each primary source in MIT co-ordinate system
            xyz=source_xyz(:,ps)-sensor_xyz(:,sensor_No); % Position vector from sensor_No to source(is)                      
            [xyz]=tm_room_receiver*xyz;% Rotational axes transformation, room to receiver axes
            
            % Convert to angular coordinates of source(az,el) in MIT receiver axes
            hyp = sqrt(xyz(1)^2+xyz(2)^2); % Distance (m) between sensor_No and proj of image source(is) on xy plane 
            elevation = atan2(xyz(3),hyp); % -pi <= elevation <= +pi rads, NB for checking audibility only
            
            % MIT no data for sources -140 <elevation < -40 deg, they are assumed zero
            if (elevation >= min_elev_sensor)|(elevation <=max_elev_sensor), 
                audible = true; % source (image) is audible
                elevation = atan(xyz(3)./(hyp+eps)); % -pi/2 <= elevation <= +pi/2 rads
                azimuth = atan2(xyz(2),xyz(1)); % Calculate -pi <= azimuth <= +pi rad
                
                % Quantise the elevations and azimuths to nearest angle in the MIT set
                % (-40*pi/180 <= elevation <= +pi/2 rads, -pi <= azimuth <= +pi rads)
                % and get the HRIR for this i'th image source
                % NB azimuth for Kemar measurements was +ve CW so invert sign.
                % NB MIT HRIR starts with an ~3 sample offset at elevation=0 azimuth=+/-pi/2 rads
                [hrir] = getNearestMITpulse(elevation,-azimuth,H3D); 
            end;
            
        case 'cipicir', % Calculate elevation and azimuth of each primary source in CIPIC "head fixed" co-ordinate system                                
            xyz=source_xyz(:,ps)-sensor_xyz(:,sensor_No); % Position vector from sensor_No to source(is)                      
            [xyz]=tm_room_receiver*xyz;% Rotational axes transformation, room to receiver axes
            
            % Convert to angular coordinates of source(az,el) in CIPIC receiver axes
            hyp = sqrt(xyz(1)^2+xyz(2)^2); % Distance (m) between sensor_No and proj of image source(is) on xy plane 
            elevation = atan2(xyz(3),hyp); % Calculate -pi <= elevation <= +pi rad
            
            % CIPIC no data for sources -129.375 <elevation < -45 deg, they are assumed zero
            if (elevation >= min_elev_sensor)|(elevation <=max_elev_sensor),
                audible=true; % source (image) is audible
                azimuth = atan(xyz(2)./(xyz(1)+eps)); % -pi/2 <= azimuth <= +pi/2 rads
                
                % Quantise the elevations and azimuths to nearest angle in the CIPIC set
                % (-pi/4 <= elevation <= +230*pi/180 rads, -pi/2 <= azimuth <= +pi/2 rads)
                % and get the HRIR for this i'th image source
                % NB azimuth for CIPIC measurements was +ve CW so invert sign.
                % NB CIPIC HRIR starts with an 12~30 sample offset
                [hrir(:,1)] = getNearestUCDpulse(-azimuth,elevation,hrir_l);
                [hrir(:,2)] = getNearestUCDpulse(-azimuth,elevation,hrir_r);
            end;
    end; % of select MIT or CIPIC HRIR data    
    HRTF(:,:,ps)=hrir(:,:); %Save Impulse Response (hrir) for each parent source direction in HRTF for plotting, or leave as empty
    
end;% of ps counter loop for number of parent sources
close(h_parent); % Close the current waitbar box displaying progress through parent sources

%------------ Trim large arrays to remove trailing zeros and reduce dimensionality ------------------
trim_length = max(len_source);
p_isource = p_isource(1:trim_length,:,:);
%--------------------------------------------------------------------------
% Free up memory used by Globals (NB This won't help Unix systems)
clear S3D_L S3D_R H3D hrir_l hrir_r;
%---------------------------------- End of roomsim_core.m --------------------------------------------
