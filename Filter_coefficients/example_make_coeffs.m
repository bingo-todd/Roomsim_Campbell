function example_make_coeffs;
% Usage: example_make_coeffs;
% This example function calculates filter coefficients are obtained
% using the Signal Processing Toolbox function butter();
% The magnitude (dB) of the frequency response is plotted.
% A roomsim filter coefficients file can be saved. It must be named
%  *_coeffs_*.mat e.g. HP_coeffs_100.mat, and contains the numerator/denominator (B/A)
% and filter type as B A type, where type is a string variable 
% e.g. 'Low pass' or 'High pass' used for labelling roomsim plots.
%-------------------------------------------------------
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
%------------------------------------------------------------
% Functions called: butter.m

Fs=44100;
nyquist=Fs/2;
points=512;

%Example filter specifications comment/uncomment to try
band_pass=[100/nyquist 3400/nyquist]; % Band-pass 100 Hz to 3.4kHz, Fs=44100.
% low_pass=20000/nyquist; % Low-pass 20 kHz, Fs=44100.
% high_pass=50/nyquist,'high'; % High-pass 50 Hz, Fs=44100.

%NB. Signal Processing Toolbox is required for the butter(order,type); function
[B,A]=butter(4,band_pass); % Calculate the coefficients B/A 

data=filter(B,A,[1 zeros(1,points-1)]); % Convolve filter with impulse for impulse response
data=20*log10(abs(fft(data))+eps); % Compute magnitude (dB) of frequency response

plot([1:points/2]*Fs/points,data(1:points/2),'b-'); %Plot the frequency response 0 to nyquist
V=axis;
axis([0 V(2) V(3) V(4)]);
title('Frequency Response Magnitude');
xlabel('Frequency Hz');
ylabel('Magnitude dB');
drawnow; %Force completion of all previous figure drawing before continuing

prefix='example_make_coeffs';
error_title=[prefix ' error'];

answer={};
while isempty(answer),% Disable inappropriate CANCEL button operation
    banner = [prefix ': Enter a name for this filter type'];
    prompt = {'Type: '};
    lines = 1;
    def = {'*_pass'}; %Default values
    beep;
    answer = inputdlg(prompt,banner,lines,def);
end; % of while loop to disable inappropriate CANCEL button operation
type=answer{1};

% Save the filter coefficient data
file_spec={'*.mat'}; % mat only
banner='Name the filter coefficients file (*.mat)';repeat=true;
while repeat,
    repeat=false; % Do once if correct filename and ext given
    beep;
    [name path] = uiputfile(file_spec, banner); %Display the dialogue box
    if ~any(name), 
        return; % **Alternate return for cancel operation. No data saved to file.
    end;
    filename = [path name]; % Form full filename as path+name
    [pathstr,name,ext,versn] = fileparts(filename);
    if ~strcmpi(lower(ext),'.mat'),
        h=errordlg('You must specify a .mat extension',error_title);
        beep;
        uiwait(h);
        repeat=true;
    end;
end; % of while loop to trap missing .extension    
save(filename, 'B','A', 'type'); % Save as a Roomsim filter coefficient data ".mat" file
%---------------------- End of example_make_coeffs.m ----------------------