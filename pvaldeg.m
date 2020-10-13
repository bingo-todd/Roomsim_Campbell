function pangle = pvaldeg(theta)
%Usage: pangle = pvaldeg(theta); Maps angle theta (in degrees) into the range (-90, 270)
%----------------------------------------------------------------------
% Ackowledgement: This function is only marginally changed from that
% published by CIPIC in their "hrir_data_documentation.pdf"
%-----------------------------------------------------------------------
% Functions called: 

%*** Global Declarations ***
global deg2rad; % Conversion factor degrees to radians
global rad2deg; % Conversion factor radians to degrees
%***************************
if nargin < 1
    fprintf('Format: pangle = pvaldeg(theta)\n');
    return
end

theta_rad=theta*deg2rad;
pangle = atan2(sin(theta_rad),cos(theta_rad))*rad2deg;

if pangle < -90
    pangle = pangle + 360;
end
%---------------------- End of pvaldeg.m -------------------------