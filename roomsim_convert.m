function roomsim_convert;
%Usage: roomsim_convert;   Convert filename1.mat to filename2.wav or vice versa.
% Also allows conversion between one channel and two channel audio files.
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
%----------------------------------------------------------------------
% Functions called: read_audio.m, save_audio.m, bi_plot.m, sound_out.m

global LOG_FID; % Identifier of logfile. Loaded in roomsim.m
global MACHINE % User machine identifier. Loaded in roomsim.m

prefix='roomsim_convert: ';
error_title=[prefix ' error'];
fprintf(LOG_FID,'\n\n In roomsim_convert'); % Print to log file

file_spec={'*.mat;*.wav;*.au;','Roomsim Audio Files (*.mat,*.wav,*.au)';'*.*', 'All Files (*.*)'}; %
banner='Choose the file to convert (*.mat, *.wav or *.au)';
[Fs, data_1, d_rows, d_columns, filename] = read_audio(file_spec, banner); % Get the file to convert
if isempty(Fs)|isempty(data_1), % Error has already been flagged in read_audio
    return; %to calling function
end;
%-------------- Do the conversion -----------------------------------

if d_columns == 1,
    M1_Title=[prefix 'Convert channels ?'];
    B1_text='Convert one to two channel (diotic) audio file';
    B2_text='Keep channels as they are';
    beep;
    M_Chancase = menu(M1_Title,B1_text,B2_text);
    switch M_Chancase
        case 0,
            h=warndlg('Convert operation cancelled',banner);
            beep;
            pause(1);
            try,
                close(h); % Destroy the advisory notice if user has not cancelled
            catch,
            end;
            return; % Close window button operated
            
        case 1, % Make diotic
            data_2(:,1) = data_1; % Make the left channel
            data_2(:,2) = data_1; % Make the right channel
            
        case 2, % Keep present channels.
            data_2 = data_1;
    end;
elseif d_columns == 2,
    M1_Title=[prefix 'Convert channels ?'];
    B1_text='Convert two to one channel audio file';
    B2_text='Keep channels as they are';
    beep;
    M_Chancase = menu(M1_Title,B1_text,B2_text);
    switch M_Chancase
        case 0,
            h=warndlg('Convert operation cancelled',banner);
            beep;
            pause(1);
            try,
                close(h); % Destroy the advisory notice if user has not cancelled
            catch,
            end;
            return; % Close window button operated
            
        case 1, % Make two-channel (diotic or stereo) datafile into single-channel (mono).
            M2_Title=[prefix 'Select channel to make mono file'];
            B11_text='Left Channel';
            B22_text='Right Channel';
            beep;
            M_LRcase = menu(M2_Title,B11_text,B22_text);
            switch M_LRcase
                case 0,
                    h=warndlg('Convert operation cancelled',banner);
                    beep;
                    pause(1);
                    try,
                        close(h); % Destroy the advisory notice if user has not cancelled
                    catch,
                    end;
                    return; % Close window button operated
                    
                case 1, % Left channel selected
                    data_2 = data_1(:,1);
                    
                case 2, % % Right channel selected
                    data_2 = data_1(:,2);
            end;
            
        case 2, % Keep present channels.
            data_2 = data_1;
    end;
end;

sound_play=true; % Channels and Fs are compatible so set flag to allow playing of audio data

%Set up the requested x axis scale,
message='Select time or sample number for display x-axis';
button=[];
beep;
button = questdlg(message,prefix,'Time','Sample','Time');
if strcmp(button,'Time') % time axis
    Fs_disp=Fs;
    T=1/Fs_disp; % Sampling period
    xscale=[0:size(data_2,1)-1].'.*T;
    xtext=['Time (s)'];
elseif strcmp(button,'Sample') % sample number axis   
    Fs_disp=1;
    xscale=[0:size(data_2,1)-1].'; 
    xtext=['Sample Index Number']; 
else
    h=warndlg('Display and save operations cancelled',prefix);
    beep;
    pause(1);
    try,
        close(h); % Destroy the advisory notice if user has not cancelled
    catch,
    end;
    fprintf(LOG_FID,'\n\n roomsim_convert: data was not saved'); % Print to log file
    return; % Close dialogue box button operation, no plot produced.
end;

ytext='Amplitude';
legend_1='One Channel (black)';
legend_2='Left Channel (blue), Right Channel (red)';
title_1='Original Data';
title_2='Converted data';
multi_plot(filename, data_1, data_2, [], title_1, title_2, [], xscale, xtext, ytext, legend_1, legend_2);

drawnow; %Force completion of all previous figure drawing before continuing

% Offer sound out to PCWin users only
if strcmp(MACHINE,'PCWIN') & sound_play; % Allow sound playing if PCWin detected at startup and both files had same Fs.
    sound_out(Fs, data_2);
end;

% Save the converted one or two channel data result
banner='Save converted file as *.wav, *.mat or *au';
file_spec={'*.wav','Windows PCM (*.wav)';'*.mat','MAT-files (*.mat)';'*.au','NeXT/SUN (*.au)';'*.*','All Files (*.*)'}; % wav first as more likely
save_audio(file_spec,Fs,data_2,banner); % Allow save of .wav, .mat or .au file types
%-------------------------- End of roomsim_convert.m --------------------------
