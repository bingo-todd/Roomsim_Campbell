function roomsim_accumulate;
%Usage: roomsim_accumulate;   Accumulate stereo files (of type .wav, .mat or .au),
% plot them, and the result, then save the result to a file, and displays spectrograms.
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
% Functions called: read_audio.m, save_audio.m, tri_plot.m, bi_spectrogram.m, sound_out.m

%*** Global Declarations ***
global LOG_FID; % Identifier of logfile. Loaded in roomsim.m
global MACHINE % User machine identifier. Loaded in roomsim.m

prefix='roomsim_accumulate: ';
error_title=[prefix 'error'];
fprintf(LOG_FID,'\n\n In roomsim_accumulate'); % Print to log file

%------------------ Get the first file ----------------------------------

file_spec={'*.mat;*.wav;*.au;','Roomsim Audio Files (*.mat,*.wav,*.au)';'*.*', 'All Files (*.*)'}; %
banner='Choose the first file for accumulation (*.wav, *.mat or *.au)'; %
[Fs1, accum, a_rows, a_columns, filename] = read_audio(file_spec, banner); % Get the first file data into the accumulator
if isempty(Fs1)|isempty(accum), % Error has already been flagged in read_audio
    return; %to calling function
end;

%--------------- Repeat loop to get additional data to accumulate starts here -------------------------------------
acc_file=true;
while acc_file, % Loop until user stops it (acc_file=False)
    file_spec={'*.mat;*.wav;*.au;','Roomsim Audio Files (*.mat,*.wav,*.au)';'*.*', 'All Files (*.*)'}; %
    banner='Choose the next file to accumulate (*.wav, *.mat or *.au)';
    [Fs2, data, d_rows, d_columns, filename2] = read_audio(file_spec, banner); % Get the data to be added to the accumulator contents
    if isempty(Fs2)|isempty(data), % Error has already been flagged in read_audio
        return; %to calling function
    end;
    
    %--------------------------- Check the data pair -------------------------------
    
    if abs(Fs1-Fs2) > eps,     
        message=strvcat('Sampling frequencies are not equal','Accumulation cancelled');
        h=errordlg(message,error_title);
        beep;
        uiwait(h);
        return; % *** Alternate return
    end;
    
    if d_columns ~= a_columns, % Offer to make single-channel data (mono) into two-channel (diotic).
        banner=[prefix 'One channel + two channel is illegal'];
        message='Make the one channel file into two identical channels?';
        button=[];
        beep;
        button = questdlg(message,banner,'Yes','Cancel','Yes');
        if strcmp(button,'Yes') % 
            if a_columns==1,% Make the accumulator data two channel diotic
                accum(:,1) = accum;
                accum(:,2) = accum(:,1);
            else, % % Make the new data two channel diotic
                data(:,1) = data;
                data(:,2) = data(:,1);
            end;
        else % Cancel or Close Window button pressed
            h=warndlg('Display of audio data cancelled',prefix);
            beep;
            pause(1);
            try,
                close(h); % Destroy the advisory notice if user has not cancelled
            catch,
            end;
            return; % Cancelled operation, no plot produced.
        end;   
    end; % of Check the new data
    
    %---------------- Start the accumulation -----------------
    [a_rows, a_columns] = size(accum);
    [d_rows, d_columns] = size(data);
    
    if d_rows > a_rows, % then append zeros to accumulator
        accum=[accum; zeros(d_rows-a_rows,a_columns)]; % Append zeros to equalise lengths
    elseif a_rows > d_rows, % then append zeros to data
        data=[data; zeros(a_rows-d_rows,a_columns)]; % Append zeros to equalise lengths
    end;
    
    old_accum=accum; % Save past accumulator data for plotting before overwriting
    accum=accum+data; % Add the two data arrays and overwrite current accumulator data
    
    sound_play=true; % Channels and Fs are compatible so set flag to allow playing of audio data
    
    %Set up the requested x axis scale,   
    message='Select time or sample number for display x-axis';
    button=[];
    beep;
    button = questdlg(message,prefix,'Time','Sample','Time');
    if strcmp(button,'Time') % time axis
        Fs=Fs1;
        T=1/Fs; % Sampling period
        xscale=[0:size(accum,1)-1].'.*T;
        xtext=['Time (s)'];
    elseif strcmp(button,'Sample') %
        Fs=1;
        xscale=[0:size(accum,1)-1].'; 
        xtext=['Sample Index Number'];
    else
        h=warndlg('Display and save operations cancelled',prefix);
        beep;
        pause(1);
        try,
            close(h); % Destroy the advisory notice if user has not cancelled
        catch,
        end;
        fprintf(LOG_FID,'\n\n roomsim_accumulate: data was not saved'); % Print to log file       
        return; % Close dialogue box button operation, no plot produced.
    end;
    
    %------ Plot the old data from the accumulator, the additional file, and the result of the new accumulation for each channel ----
    filename=[filename '+' filename2]; % Identify the input files NB filename updates each time round the accumulation loop
    ytext='Amplitude';
    legend_1='One Channel (black)';
    legend_2='Left Channel (blue), Right Channel (red)';
    title_1='Previous accumulator data';
    title_2='New audio data';
    title_3='Accumulation result';
    multi_plot(filename, old_accum, data, accum, title_1, title_2, title_3, xscale, xtext, ytext, legend_1, legend_2);
    
    %---------------- Display spectrogram page --------------------------
    ytext='Frequency (Hz)';
    title_1='New Audio Data';
    title_2='Accumulation result';
    title_L=' L';
    title_R=' R';
    multi_spectrogram(filename, Fs, data, accum, [], title_1, title_2, [], xtext, ytext, title_L, title_R);
   
    drawnow; %Force completion of all previous figure drawing before continuing
    
    % Offer sound out to PCWin users only
    if strcmp(MACHINE,'PCWIN') & sound_play; % Allow sound playing if PCWin detected at startup and both files had same Fs.
        sound_out(Fs1, accum);
    end;
    
    %------- Loop for additional data or stop and save the result -----------
    button=[];
    button = questdlg('Accumulate another file',prefix,'Yes','Save & Exit','Save & Exit');
    if strcmp(button,'Yes')
        % Continue to accumulate another file
    elseif strcmp(button,'Save & Exit') % Save result chosen
        banner='Save as *.wav or *.au to use your media player to hear the result';
        file_spec={'*.wav','Windows PCM (*.wav)';'*.mat','MAT-files (*.mat)';'*.au','NeXT/SUN (*.au)';'*.*','All Files (*.*)'}; % wav first as more likely
        save_audio(file_spec,Fs1,accum,banner); % Allow save of .wav, .mat or .au file types
        break; % Exit the while loop
    else
        h=warndlg('Accumulate and save cancelled',prefix);
        beep;
        pause(1);
        try,
            close(h); % Destroy the advisory notice if user has not cancelled
        catch,
        end;
        fprintf(LOG_FID,'\n\n roomsim_accumulate: data was not saved'); % Print to log file
        return; % Close dialogue box button operation, no plot produced.
    end;
end; % of while loop

%-------------------------- End of roomsim_accumulate.m --------------------------
