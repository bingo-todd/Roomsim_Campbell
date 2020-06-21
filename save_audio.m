function save_audio(file_spec, Fs, data, title);
%Usage: save_audio(file_spec, Fs, data, title);  Save the audio array 'data' to a file.
%This function detects the file type extension and writes the desired format
%MATLAB loadable files are written if a .mat extension is detected.
%NeXT/SUN *.au and MS *.wav files are written as 16 bit with Fs.
%User can choose that data are scaled into the range +/-1, prevents clipping of .wav and .au 
%(The MATLAB warning message about clipping during wavwrite (scaled) appears to be erroneous).
%------------------------------------------------------------------------------- 
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
%-----------------------------------------------------------------------------------
% Functions called: 

%GLOBALS
global LOG_FID; % Identifier of logfile

prefix='save_audio';
error_title=[prefix ' error'];

[rows, cols] = size(data);	%Initialisation
if cols >2
    h=errordlg('save_audio can only handle mono or stereo files at present',error_title);
    beep;
    uiwait(h);
    fprintf(LOG_FID,'\n\n save_audio: sound data was not saved'); % Print to log file
    return;
end

repeat=true;
while repeat,
    repeat=false; % Do once if correct filename and ext given
    beep;
    [name path] = uiputfile(file_spec, title); %Display the dialogue box
    if ~any(name),
        fprintf(LOG_FID,'\n\n save_audio: sound data was not saved'); % Print to log file
        return; % **Alternate return for cancel operation. No data saved to file.
    end;
    filename = [path name]; % Form full filename as path+name
    [pathstr,name,ext,versn] = fileparts(filename);
    if ~strcmpi(lower(ext),'.wav') & ~strcmpi(lower(ext),'.mat') & ~strcmpi(lower(ext),'.au'),
        h=errordlg('You must specify a .wav, .mat or .au extension',error_title);
        beep;
        uiwait(h);
        repeat=true;
    end;
end; % of while loop to trap missing .extension    

if isempty(Fs)|Fs==1,
    answer={};
    banner = 'Sampling frequency not specified';
    prompt = {'To save as a Roomsim audio format file, enter a sampling frequency (Hz): '};
    lines = 1;
    def = {'44100'}; %Default value
    beep;
    answer = inputdlg(prompt,banner,lines,def,'on');
    if isempty(answer),
        h=warndlg('Save of audio data cancelled',prefix);
        beep;
        pause(1);
        try,
            close(h); % Destroy the advisory notice if user has not cancelled
        catch,
        end;
        fprintf(LOG_FID,'\n\n save_audio: sound data was not saved'); % Print to log file
        return; % Close dialogue box button operation, no save performed.
    end;
    Fs=str2num(answer{1});
end;

% Allow user to scale the data or save it without scaling
message='Scale data into a range of +/- 1 ?';
button=[];
beep;
button = questdlg(message,prefix,'Yes','No','Yes');
if strcmp(button,'Yes'), % Scale the data
    max_data = max(max(abs(data))); % Find max of stereo data
    data=data/max_data; %Scale into range +/- < 1 (avoids clipping on .wav and .au write)
elseif strcmp(button,'No') % Data is not scaled
    fprintf(LOG_FID,'\n\n save_audio: sound data was not scaled'); % Print to log file
else
    h=warndlg('Save of audio data cancelled',prefix);
    beep;
    pause(1);
    try,
        close(h); % Destroy the advisory notice if user has not cancelled
    catch,
    end;
    fprintf(LOG_FID,'\n\n save_audio: sound data was not saved'); % Print to log file
    return; % Close dialogue box button operation, no save performed.
end;

switch lower(ext), % Force case statements to match against lower-case extension
    case '.wav'
        wavwrite(data, Fs, 16, filename); % Save as a ".wav" file, sampling frequency Fs, 16 bits
        
    case '.au'
        auwrite(data, Fs, 16, 'linear', filename); % Save as an ".au" file, sampling frequency Fs, 16 bits
        
    case '.mat'
        % Fs and data are the names that Roomsim's read_audio.m will look for when reading a Roomsim audio *.mat file
        % (Explicit naming avoids problem with stand-alone compiled version)
        save(filename, 'Fs','data'); % Save as a Roomsim audio data ".mat" file
end;
fprintf(LOG_FID,'\n\n save_audio: sound data has been saved to %s', filename); % Print to log file

%--------------------------------- End of save_audio.m --------------------------------------
