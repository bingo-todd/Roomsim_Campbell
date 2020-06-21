function roomsim_show;
%Usage: roomsim_show;  Reads an audio file (of type .mat, .wav or .au),
%plots it, displays the spectrogram, and allows sound output to PCWIN machines.
%------------------------------------------------------------------ 
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
%-------------------------------------------------------------------------
% Functions called: read_audio.m, multi_plot.m, multi_spectrogram.m, sound_out.m

%*** Global Declarations ***
global LOG_FID; % Identifier of logfile. Loaded in roomsim.m
global MACHINE % User machine identifier. Loaded in roomsim.m

prefix='roomsim_show: ';
error_title= [prefix 'error'];

%------------------ Get the file ----------------------------------
file_spec={'*.mat;*.wav;*.au;','Roomsim Audio Files (*.mat,*.wav,*.au)';'*.*', 'All Files (*.*)'}; %
banner='Choose a roomsim audio file (*.wav, *.mat or *au)';
[Fs, data, d_rows, d_columns, filename] = read_audio(file_spec, banner);
if isempty(Fs)|isempty(data), % Error has already been flagged in read_audio
    return; %to calling function
end; 

%-----------------------Display the data for each channel---------------
%Set up the requested x axis scale,
banner='roomsim_show';
message='Select time or sample number for line Plots'' x-axis';
button=[];
beep;
button = questdlg(message,banner,'Time','Sample','Time');
if strcmp(button,'Time') % time axis
    Fs_disp=Fs;
    T=1/Fs; % Sampling period
    xscale=[0:(size(data,1)-1)].'.*T;
    xtext=['Time (s)'];
elseif strcmp(button,'Sample')% sample number axis
    Fs_disp=1;
    xscale=[0:(size(data,1)-1)].'; 
    xtext=['Sample Index Number'];
else
    h=warndlg('Display of audio data cancelled',prefix);
    beep;
    pause(1);
    try,
        close(h); % Destroy the advisory notice if user has not cancelled
    catch,
    end;
    fprintf(LOG_FID,'\n\n roomsim_show: data was not saved'); % Print to log file
    return; % Close dialogue box button operation, no plot produced.
end;

%------------ Plot the time history ---------------------
ytext='Amplitude';
legend_1='One Channel (black)';
legend_2='Left Channel (blue), Right Channel (red)';
titletext='Time History Display';
multi_plot(filename, data, [], [], titletext, [], [], xscale, xtext, ytext, legend_1, legend_2);

%---------------- Display spectrogram page --------------
ytext='Frequency (Hz)';
title_1='Spectrogram Display';
title_L=' L';
title_R=' R';
multi_spectrogram(filename, Fs_disp, data, [], [], title_1, [], [], xtext, ytext, title_L, title_R);

drawnow; %Force completion of all previous figure drawing before continuing

%----------- Display sound ------------------------------
sound_play=true; % Set flag to allow playing of audio data
% Offer sound out to PCWin users only
if strcmp(MACHINE,'PCWIN') & sound_play; % Allow sound playing if PCWin detected at startup and both files had same Fs.
    sound_out(Fs, data);
end;

%------------ End of roomsim_show.m ----------------------