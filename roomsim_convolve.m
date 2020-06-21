function roomsim_convolve;
%Usage: roomsim_convolve;   Convolve two stereo files (of type .mat, .wav or .au),plot them and the result,
%   display spectrograms, allow sound output to PCWIN machines and then save the result to a file.
% Frequency domain convolution performed by: real(ifft(fft(data_1)*fft(data_2))) = conv(data_1,data_2)
% The files may be of different lengths
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
% Functions called: read_audio.m, frame_conv.m, save_audio.m, multi_plot.m, multi_spectrogram.m, sound_out.m

%*** Global Declarations ***
global LOG_FID; % Identifier of logfile. Loaded in roomsim.m
global MACHINE % User machine identifier. Loaded in roomsim.m
global CONV_FACTOR_2; % Used for estimating convolution times. Loaded in speed_estimator.m

prefix='roomsim_convolve: ';
error_title= [prefix 'error'];
fprintf(LOG_FID,'\n\n In roomsim_convolve'); % Print to log file

%------------------ Get the first file ----------------------------------

file_spec={'*.mat;*.wav;*.au;','Roomsim Audio Files (*.mat,*.wav,*.au)';'*.*', 'All Files (*.*)'}; %
banner='Choose the first file (*.mat, *.wav or *.au)'; %
[Fs1, data_1, d1_rows, d1_columns, filename1] = read_audio(file_spec, banner); % Get file_1
if isempty(Fs1)|isempty(data_1), % Error has already been flagged in read_audio
    return; %to calling function
end;

%------------------ Get the second file ----------------------------------
file_spec={'*.mat;*.wav;*.au;','Roomsim Audio Files (*.mat,*.wav,*.au)';'*.*', 'All Files (*.*)'}; %
banner='Choose the second file (*.wav, *.mat or *au)';
[Fs2, data_2, d2_rows, d2_columns, filename2] = read_audio(file_spec, banner); % Get file_2 to be convolved with file_1
if isempty(Fs2)|isempty(data_2), % Error has already been flagged in read_audio
    return; %to calling function
end; 

%--------------------------- Check the data pair -------------------------------
if abs(Fs1-Fs2) > eps,     
    banner = [prefix 'Warning'];
    message='Sampling frequencies are not equal';
    beep;
    button = questdlg(message,banner,'Cancel','Continue','Cancel');
    if strcmp(button,'Continue'),
        message='Data will be plotted against sample index number';
        h=warndlg(message,banner);  %Warn & beep.
        beep;
        uiwait(h);% Wait for user to acknowledge
    else, % Cancel or close window button pressed so
        h=warndlg('Convolution cancelled',banner);
        beep;
        pause(1);
        try,
            close(h); % Destroy the advisory notice if user has not cancelled
        catch,
        end;
        return; % Quit the convolution
    end;
end;

if d2_columns ~= d1_columns, % Offer to make single-channel data (mono) into two-channel (diotic).
    banner=[prefix ' One channel*two channel is illegal'];
    message='Make the one channel file into two identical channels?';
    button=[];
    beep;
    button = questdlg(message,banner,'Yes','Cancel','Yes');
    if strcmp(button,'Yes') % 
        if d1_columns==1,% Make the first data two channel diotic
            data_1(:,1) = data_1;
            data_1(:,2) = data_1(:,1);
        else, % % Make the second data two channel diotic
            data_2(:,1) = data_2;
            data_2(:,2) = data_2(:,1);
        end;
    else, % Cancel or close window button pressed so 
        return; % Quit the convolution
    end;   
end; % of Check the data, data_1 and data_2 now have the same number of columns (channels)

[data_1, data_2] = check_swap(data_1,data_2); % Find shorter data sequence making it data_1

% Do the convolutions.
[d1_rows, d1_columns] = size(data_1); % Update sizes of arrays in case swapped
[d2_rows, d2_columns] = size(data_2);
N=d1_rows+d2_rows-1;
FFT_length=2^nextpow2(N);
time_est=ceil(d1_columns.*FFT_length*log2(FFT_length)./CONV_FACTOR_2); % Convolution time estimate
colordef white; % Force waitbar backgrounds to white
wait_msg_con = ['This may take ' num2str(time_est) ' seconds. Please wait ...'];
h_conv = waitbar(0.1,wait_msg_con,'name',[prefix ' Convolving']); % Let the user know something is happening

%Alternative methods of calculating the convolution, (1), (2), (3):
% (1) The following two lines of code do the convolution using the MATLAB function conv (very slow!)
% result=zeros(d1_rows+d2_rows-1,d1_columns);
% result(:,1)=conv(data_1(:,1),data_2(:,1)); % Convolve single or Left channel signals using conv

% (2) The following four lines of code do the convolution using the full length FFT approach (memory intensive!)
% X = fft(data_1(:,1),FFT_length); % The fft function will zero pad the data with FFT_length-d_rows zeros prior to transforming
% Y = fft(data_2(:,1),FFT_length);
% temp = real(ifft(X.*Y));
% result(:,1) = temp(1:N);  % Frequency domain convolution of single or Left channel signals
% clear temp;

% (3) The following line of code does the convolution using the Block over-lap add or full FFT approach
result(:,1) = frame_conv(data_1(:,1),data_2(:,1));

waitbar(0.5,h_conv); % Let the user know something is happening
if d1_columns==2,
% Convolution using the Block over-lap add or full FFT approach
    result(:,2) = frame_conv(data_1(:,2),data_2(:,2));
    waitbar(0.9,h_conv); % Let the user know something is happening
end;

close(h_conv);

%-----------------------Display the original data and convolution result for each channel---------------
data_1=[data_1; zeros(size(result,1)-size(data_1,1),d1_columns)]; % Extend file_1 data to same length as convolution result
data_2=[data_2; zeros(size(result,1)-size(data_2,1),d1_columns)]; % Extend file_2 data to same length as convolution result

%Set up the requested x axis scale,
if abs(Fs1-Fs2) <= eps,% Fs1=Fs2, offer choice of time or sample number axis
    sound_play=true; % Set flag to allow playing of audio data
    message='Select time or sample number for line Plots'' x-axis';
    button=[];
    beep;
    button = questdlg(message,prefix,'Time','Sample','Time');
    if strcmp(button,'Time') % time axis
        Fs_disp=Fs1;
        T=1/Fs1; % Sampling period
        xscale=[0:(size(result,1)-1)].'.*T;
        xtext=['Time (s)'];
    elseif strcmp(button,'Sample') % sample number axis
        Fs_disp=1;
        xscale=[0:(size(result,1)-1)].'; 
        xtext=['Sample Index Number'];
    else
        h=warndlg('Display and save operations cancelled',prefix);
        beep;
        pause(1);
        try,
            close(h); % Destroy the advisory notice if user has not cancelled
        catch,
        end;
        fprintf(LOG_FID,'\n\n roomsim_convolve: data was not saved'); % Print to log file
        return; % Close dialogue box button operation, no plot or saved data produced.
    end;
else, % sample number axis
    sound_play=false; % No legal sampling frequency so prevent playing of audio data
    Fs_disp=1;
    xscale=[0:(size(result,1)-1)].'; 
    xtext=['Sample Index Number'];
end;

%------ Plot the time histories (File_1), (File_2), and the result of the convolution for each channel ----
filename=[filename1 '*' filename2]; % Identify the input files
ytext=['Amplitude'];
legend_1='One Channel (black)';
legend_2='Left Channel (blue), Right Channel (red)';
title_1='Time History of File 1';
title_2='Time History of File 2';
title_3='Convolution result';
multi_plot(filename, data_1, data_2, result, title_1, title_2, title_3, xscale, xtext, ytext, legend_1, legend_2);

%---------------- Display spectrogram page --------------------------
ytext='Frequency (Hz)';
title_1='Spectrogram of File 1';
title_2='Spectrogram of File 2';
title_3='Convolution result';
title_L=' L';
title_R=' R';
multi_spectrogram(filename, Fs_disp, data_1, data_2, result, title_1, title_2, title_3, xtext, ytext, title_L, title_R);

drawnow; %Force completion of all previous figure drawing before continuing

% Offer sound out to PCWin users only
if strcmp(MACHINE,'PCWIN') & sound_play; % Allow sound playing if PCWin detected at startup and both files had same Fs.
    sound_out(Fs1, result);
end;

%------- Save the result -----------
banner='Save convolution result (*.wav/*.au allows media player to play it)';
file_spec={'*.wav','Windows PCM (*.wav)';'*.mat','MAT-files (*.mat)';'*.au','NeXT/SUN (*.au)';'*.*','All Files (*.*)'}; % wav first as more likely
save_audio(file_spec,Fs1,result, banner); % Allow save of .wav, .mat or .au file types
%-------------------------- End of roomsim_convolve.m --------------------------
