function [imp_resp]=make_sensor_ir(elev,azim,H,F);

% Build a sensor impulse response
deg2rad=pi/180;
N=128; %Required order of FIR filter modelling impulse response of sensor
if length(H)==1,
    h=H;
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
%Compute angle dependent magnitude modification
% 
% % This is an omni-directional sensor with frequency response H
% imp_resp=h;
% 
% % This is a directional sensor with frequency response H
imp_resp=abs(cos(elev)).*abs(cos(azim)).*h;
%
% This is a directional sensor with a gain of h over the solid angle +/-elev and +/-azim
% if abs(elev)<= 30.*deg2rad & abs(azim)<= 10.*deg2rad,
%     imp_resp= h;
% else,
%     imp_resp= 0;
% end;
