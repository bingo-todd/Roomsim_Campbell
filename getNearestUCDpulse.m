function [hrir_L_R] = getNearestUCDpulse(azimuth,elevation,h3D);
%Usage: [hrir_L_R, azerr, elerr] = getNearestUCDpulse(azimuth,elevation,h3D);
%Retrieves the left or right ear impulse response from h3D that is closest to the
%specified azimuth and elevation (in degrees) NB. converted from radians on entry
%-----------------------------------------------------------------------
% Acknowledgement: This function is a modification of code
% published by CIPIC in their "hrir_data_documentation.pdf"
%----------------------------------------------------------------------
% Functions called: pvaldeg.m

%*** Global Declarations ***
global rad2deg; % Conversion factor radians to degrees
%***************************

if nargin < 3
    fprintf('Format: [hrir_L_R, azerr,elerr] = getNearestUCDpulse(azimuth,elevation,h3D)\n');
    return;
end

azimuth = pvaldeg(rad2deg.*azimuth); % Convert to degrees and take principal value
elevation = pvaldeg(rad2deg.*elevation);

if (azimuth < -90) | (azimuth > 90)
    error('Invalid azimuth in getNearestUCDpulse.m');
end;
azimuths = [-80 -65 -55 -45:5:45 55 65 80];
[azerr, az] = min(abs(pvaldeg(abs(azimuths - azimuth)))); % Error and Index for required azimuth

elmax = 50;
elindices = 1:elmax;
elevations = -45 + 5.625*(elindices-1);
el = round((elevation+45)/5.625 + 1);
el = max(el,1);
el = min(el,elmax); %Index for required elevation

hrir_L_R = squeeze(h3D(az,el,:));
%--------------- End of getNearestUCDpulse.m --------------------------------------------
