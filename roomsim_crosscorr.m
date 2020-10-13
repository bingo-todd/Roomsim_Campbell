function roomsim_crosscorr;
%Usage: roomsim_crosscorr; 
% Cross-correlate the two channels of a Roomsim audio file (of type .mat, .wav or .au),
% plot the two channels and the result, and then save the result to a file. .
% Frequency domain correlation performed by: real(ifft(fft(data(:,1))*conj(fft(data(:,2))))) = conv(data(:,1),data(:,2))
% Written to process ONLY two channel (equal length e.g stereo) datafiles. 
%------------------------------------------------------------------ 
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
%-------------------------------------------------------------------------
% Functions called: read_audio.m, save_audio.m, multi_plot.m

%*** Global Declarations ***
global LOG_FID; % Identifier of logfile. Loaded in roomsim.m
global MACHINE % User machine identifier. Loaded in roomsim.m
global CONV_FACTOR_2; % Used for estimating correlation times. Loaded in speed_estimator.m

prefix='roomsim_crosscorr: ';
error_title= [prefix 'error'];
fprintf(LOG_FID,'\n\n In roomsim_crosscorr'); % Print to log file

%------------------ Get the first data set ----------------------------------
file_spec={'*.mat;*.wav;*.au;','Roomsim Audio Files (*.mat,*.wav,*.au)';'*.*', 'All Files (*.*)'}; %
banner='Choose the two channel data file (*.mat, *.wav or *.au)';
[Fs1, data, d_rows, d_columns, filename] = read_audio(file_spec, banner); % Get file_1
if isempty(Fs1)|isempty(data), % Error has already been flagged in read_audio
    return; %to calling function
elseif d_columns ~= 2, % Check for 2 channel data file
    message=strvcat('File is not two channel','Returning to previous menu');
    h=errordlg(message,error_title);
    beep;
    uiwait(h);
    return; %to calling function
end;

FFT_length=2^nextpow2(2.*d_rows-1); % Calculate suitable length for cross-correlation by FFT method.
time_est=ceil(2.*log2(FFT_length)./CONV_FACTOR_2); % Cross-correlation time estimate
colordef white; % Force waitbar backgrounds to white
wait_msg_con = ['This may take ' num2str(time_est) ' seconds. Please wait ...'];
h_xcorr = waitbar(0.1,wait_msg_con,'name',[prefix ' Cross-correlating']); % Let the user know something is happening

% Compute cross-correlation using FFT's
temp = fft(data,FFT_length); % The fft function will zero pad the data with FFT_length-d_rows zeros prior to transforming
result = real(ifft(temp(:,1).*conj(temp(:,2)))); % Compute the x-correlation and force real data
result = [result(FFT_length-d_rows+2:FFT_length,1); result(1:d_rows,1)];  % Centre the zero shift point and trim the result

waitbar(0.5,h_xcorr); % Let the user know something is happening
close(h_xcorr);
clear temp;

% Normalise the cross-correlation
max_data = max(abs(result)); % Find max of result data
result=result/max_data; % Scale into range +/- < 1

%-----------------------Display the original data and Cross-correlation result for each channel---------------
%Set up the requested x axis scale,
message='Select time or sample number for line Plots'' x-axis';
button=[];
beep;
button = questdlg(message,prefix,'Time','Sample','Time');
if strcmp(button,'Time') % time axis
    Fs_disp=Fs1;
    T=1/Fs1; % Sampling period
    xscale_r=[-((size(result,1)+1)/2-1):(size(result,1)+1)/2-1].'.*T;
    xscale=[0:size(data,1)-1].'.*T;
    xtext=['Time (s)'];
elseif strcmp(button,'Sample') % sample number axis
    Fs_disp=1;
    xscale_r=[-((size(result,1)+1)/2-1):(size(result,1)+1)/2-1].';
    xscale=[0:size(data,1)-1].';
    xtext=['Sample Index Number'];
else
    h=warndlg('Display and save operations cancelled',prefix);
    beep;
    pause(1);
    try,
        close(h); % Destroy the advisory notice if user has not cancelled
    catch,
    end;
    fprintf(LOG_FID,'\n\n roomsim_crosscorr: data was not saved'); % Print to log file
    return; % Close dialogue box button operation, no plot or saved data produced.
end;

%------ Plot the time histories and the result of the Cross-correlation ----
ytext=['Amplitude'];
title_1='Time History of Left Channel';
title_2='Time History of Right Channel';
multi_plot(filename, data(:,1), data(:,2), [], title_1, title_2, [], xscale, xtext, ytext, [], []);

title_3='Normalised Cross-correlation result Left*Right';
multi_plot(filename, result, [], [], title_3, [], [], xscale_r, xtext, ytext, [], []);

%------- Save the result -----------
banner='Save Cross-correlation result';
file_spec={'*.wav','Windows PCM (*.wav)';'*.mat','MAT-files (*.mat)';'*.au','NeXT/SUN (*.au)';'*.*','All Files (*.*)'}; % wav first as more likely
save_audio(file_spec,Fs1,result, banner); % Allow save of .wav, .mat or .au file types
%-------------------------- End of roomsim_crosscorr.m --------------------------
