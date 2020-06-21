function [imp_resp]=make_sensor_ir(elev,azim,H,F);

%Usage: [imp_resp]=make_sensor_ir(elev,azim,H,F);
% Build an N point impulse response for a sensor.
% H is the desired magnitude response at the frequencies F.
% Frequency values have a range 0 to 1 (0 Hz to Nyquist) and
% need not be evenly spaced. The H values are interpolated to
% N/2 points prior to an IFFT to form the impulse response.
%
% N.B. Uncomment the  code for the desired microphone/sensor type (below) before running make_directivity_table.m
% 
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

deg2rad=pi/180;
elev=elev.*deg2rad;
azim=azim.*deg2rad;

N=128; %Required order of FIR filter modelling impulse response of sensor
if length(H)==1, % No variation with frequency
    h=H; % set sensor gain
else,
    % Compute parameters for converting sensor frequency response to impulse response
    Half_I=fix(N./2); % Half length of FIR filter model
    Half_I_plusone = Half_I+1; % Half length shift required for FIR filter model of sensor impulse response
    interp_x=[0: 1./Half_I :1].'; % Generate a column vector of interpolation grid points
    window = 0.5.*(1 - cos(2*pi*(0:N).'./N)); % Compute the (N+1) point column vector Hann window
    
    if length(H)<Half_I_plusone,
        H = interp1(F,H,interp_x); % Interpolate to estimate the (N/2+1) frequency samples H(F) at the interpolation grid points
    else,
        H=H(1:Half_I_plusone); % Truncate frequency response to (N/2+1) points
    end;
    
    %---------------- Transform sensor data from frequency response H(F) to impulse response h(N) --------------------           
    % Replacement for fir2 to avoid requiring users to install SIGNAL toolbox (also faster)
    % Half spectrum of data H is now made conjugate-symmetric about Nyquist frequency,
    % and last data point discarded to make periodic spectrum corresponding to a real data sequence.
    H = [H; conj(flipud(H(2:(Half_I))))]; 
    h = real(ifft(H,N)); % IFFT to calculate impulse response column vector of length N samples
    h = window.*[h(Half_I_plusone:N); h(1:Half_I_plusone)]; % Make the impulse realisable (half length shift) and Hann window it 
    %---------------------------------------------------------------------------------------------
end;
%---------------------------------------------------------------------
% TEST code to diplay impulse response and frequency response.
% N.B. Only run in single step debug mode or MATLAB may run out of memory and crash
% figure;
% subplot(2,1,1);
% ImpResp_title=['Impule Response vs Sample Number'];
% plot(h);
% axis tight;
% title(ImpResp_title);
% 
% subplot(2,1,2);
% MagFreq_title=['Magnitude vs Normalised Frequency (1 = Fs)' num2str(N) ' points'];
% nf=[0:1:N-1]/N;
% plot(nf,abs(fft(h,N))); %Plot the magnitude vs frequency response to be used by the sensor
% title(MagFreq_title);
%--------------------------------------------------------------------------

% Sensor code. Uncomment one of these
%Compute angle dependent magnitude modification (i.e. Directivity Gain)
% -----------    STANDARD MICROPHONE TYPES     ------------
%-------------------------------------------------------- 
% This is an omni-directional sensor with frequency response H

% imp_resp=h;
%--------------------------------------------------------
% This is a dipole (Figure of 8) sensor with frequency response H

% imp_resp=abs(0.0 + 1.0*cos(elev).*cos(azim)).*h;
%--------------------------------------------------------
% This is a SubCardoid sensor with frequency response H

% imp_resp=abs(0.7 + 0.3*cos(elev).*cos(azim)).*h;
%--------------------------------------------------------
% This is a Cardoid sensor with frequency response H

imp_resp=abs(0.5 + 0.5*cos(elev).*cos(azim)).*h;
%--------------------------------------------------------
% This is a SuperCardoid sensor with frequency response H.
% Spatial nulls at +/- 126 deg.

% imp_resp=abs(0.37 + 0.63*cos(elev).*cos(azim)).*h;
%--------------------------------------------------------
% This is a HyperCardoid sensor with frequency response H

% imp_resp=abs(0.25 + 0.75*cos(elev).*cos(azim)).*h;
%--------------------------------------------------------

% -----------    NON-STANDARD SENSOR TYPES     ------------
%----------------------------------------------------------------------
% This is a hemispherical directional sensor with frequency response H

% if abs(elev)<= 90.*deg2rad & abs(azim)<= 90.*deg2rad,
%     imp_resp= h;
% else,
%     imp_resp= 0;
% end;
%----------------------------------------------------------
% This is a Bi-directional sensor with a gain of h over the rectilinear solid angle (beam angle)
% +/-elev_beam and +/-azim_beam

% elev_beam=30.*deg2rad;
% azim_beam=10.*deg2rad;
% if (abs(elev)<= elev_beam & (abs(azim)<= azim_beam | (azim<= -pi+azim_beam | azim>= pi-azim_beam))),
% % if (abs(elev)<= elev_beam & abs(azim)<= azim_beam) | (abs(abs(azim)-pi)<=azim_beam & abs(abs(elev)-pi)<= elev_beam ),
%     imp_resp= h;
% else,
%     imp_resp= 0;
% end;
%-------------------------------------------------------- 
% This is a Uni-directional sensor with a gain of h over the rectilinear solid angle (beam angle)
% +/-elev_beam and +/-azim_beam

% elev_beam=30.*deg2rad;
% azim_beam=10.*deg2rad;
% if abs(elev)<= elev_beam & abs(azim)<= azim_beam,
%     imp_resp= h;
% else,
%     imp_resp= 0;
% end;
%--------------------------------------------------------

% End of make_sensor_ir.m
