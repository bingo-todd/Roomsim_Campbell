 function [Y] = roomsim_filter;
% Usage: [Y] = roomsim_filter; The filter coefficients are obtained 
% by selecting a filter coefficient file e.g. LP_coeffs_20k.mat or 
% HP_coeffs_100.mat, containing the numerator/denominator (B/A)
% and filter type as B A type, where type is a string variable 
% e.g. 'Low pass' or 'High pass' used for labelling plots.
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
% Functions called: read_audio.m, save_audio.m, sound_out.m

global LOG_FID; % Identifier of logfile. Loaded in roomsim.m
global MACHINE % User machine identifier. Loaded in roomsim.m
global CONV_FACTOR; % Used for estimating convolution times. Loaded in speed_estimator.m

prefix='roomsim_filter: ';
error_title=[prefix 'error'];
fprintf(LOG_FID,'\n\n In roomsim_filter'); % Print to log file

%------------------ Get the file to filter ----------------------------------
file_spec={'*.mat;*.wav;*.au;','Roomsim Audio Files (*.mat,*.wav,*.au)';'*.*', 'All Files (*.*)'}; %
banner='Choose the file to filter (*.wav, *.mat or *.au)';
[Fs, X, x_rows, x_columns, filename1] = read_audio(file_spec, banner); % Get the file to convert
if isempty(Fs)|isempty(X), % Error has already been flagged in read_audio
    return; %to calling function
end;

%------------------ Get the filter coefficients B(z)/A(z)----------------------------------
file_spec={'*.mat','MAT-files (*.mat)'}; % mat only
banner='Choose the filter coefficients file (*.mat)';
repeat=true;
while repeat,
    repeat=false; % Do once if correct filename and ext given
    beep;
    [name path] = uigetfile(file_spec, banner); %Display the dialogue box
    if ~any(name), 
        return; % **Alternate return for cancel operation. No data read from file.
    end;
    filename = [path name]; % Form full filename as path+name
    [pathstr,name,ext,versn] = fileparts(filename);
    if ~strcmpi(lower(ext),'.mat'),
        h=errordlg('You must specify a .mat extension ',error_title);
        beep;
        uiwait(h);
        repeat=true;
    end;
end; % of while loop to trap non .mat files

switch lower(ext), % Force case statements to match against lower-case extension
    case '.mat',
        try,
            load(filename ,'B','A','type'); % Load a ".mat" file containing the Numerator & Denominator coefficients [B,A].
        catch,
            message=strvcat('File is not Roomsim filter coefficients format','File does not contain B/A type','Exiting');
            h=errordlg(message,error_title);
            beep;
            uiwait(h);
            return;
        end;
end;

time_est=ceil(x_columns.*(length(B)+length(A)).*(length(B)+length(A)+x_rows)./CONV_FACTOR); % Filtering time estimate

colordef white; % Force waitbar backgrounds to white
wait_msg_con = [type ' filtering the data may take ' num2str(time_est) ' seconds. Please wait ...'];
h_filt = waitbar(0.1,wait_msg_con,'name',prefix ); % Let the user know something is happening

% Filter the one or two channel data X
Y(:,1) = filter(B,A,X(:,1)); % Filter left (or single) channel
waitbar(0.5,h_filt); % Let the user know something is happening

if x_columns==2,
    Y(:,2) = filter(B,A,X(:,2)); % Filter right channel
    waitbar(0.9,h_filt); % Let the user know something is happening
end;
close(h_filt);

%Set up the requested x axis scale,
message='Select time or sample number for display';
button=[];
beep;
button = questdlg(message,prefix,'Time','Sample','Time');
if strcmp(button,'Time') % time axis
    Fs_disp=Fs;
    T=1/Fs_disp; % Sampling period
    xscale=[0:size(Y,1)-1].'.*T;
    xtext=['Time (s)'];
elseif strcmp(button,'Sample') % sample number axis
    Fs_disp=1;
    xscale=[0:size(Y,1)-1].'; 
    xtext=['Sample Index Number'];
else
    h=warndlg('Filter operation cancelled',prefix);
    beep;
    pause(1);
    try,
        close(h); % Destroy the advisory notice if user has not cancelled
    catch,
    end;
    fprintf(LOG_FID,'\n\n roomsim_filter: data was not saved'); % Print to log file
    return; % Close dialogue box button operation, no plot produced.
end;

filename=[filename1 '*' name]; % Identify the input files
ytext='Amplitude';
legend_1='One Channel (black)';
legend_2='Left Channel (blue), Right Channel (red)';
title_1='Original data';
title_2=[type ' filtered result'];
multi_plot(filename, X, Y, [], title_1, title_2, [], xscale, xtext, ytext, legend_1, legend_2);

%---------------- Display spectrogram page --------------------------
ytext='Frequency (Hz)';
title_1='Original data';
title_2=[type ' filtered result'];
title_L=' L';
title_R=' R';
multi_spectrogram(filename, Fs_disp, X, Y, [], title_1, title_2, [], xtext, ytext, title_L, title_R);

drawnow; %Force completion of all previous figure drawing before continuing

sound_play=true; % Set flag to allow playing of audio data
% Offer sound out to PCWin users only
if strcmp(MACHINE,'PCWIN') & sound_play; % Allow sound playing if PCWin detected at startup and both files had same Fs.
    sound_out(Fs, Y);
end;

% Save the converted one or two channel data result
banner='Save filtered file as *.wav, *.mat or *au';
file_spec={'*.wav','Windows PCM (*.wav)';'*.mat','MAT-files (*.mat)';'*.au','NeXT/SUN (*.au)';'*.*','All Files (*.*)'}; % wav first as more likely
save_audio(file_spec,Fs,Y,banner); % Allow save of .wav, .mat or .au file types

%---------- End of roomsim_filter.m -----------------------------