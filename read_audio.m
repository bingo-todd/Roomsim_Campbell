function [Fs, data, d_rows, d_columns, name] = read_audio(file_spec, title);
%Usage: [Fs, data] = read_audio(file_spec, title); 
%Read audio data from filename.mat (or .wav or .au) and place it in the array 'data'.
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
% along with this program in the MATLAB file roomsim_licence.m ; if not,
% 
% You should have received a copy of the GNU General Public License
%  write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
%----------------------------------------------------------------------
% Functions called:

%*** Global Declarations ***
global LOG_FID; % Identifier of logfile. Loaded in roomsim.m

prefix='read_audio: ';
error_title='read_audio error';

Fs=[]; data=[]; d_rows=[]; d_columns=[]; name=[]; % Declare the named variables

repeat=true;
while repeat,
    repeat=false; % Do once if correct filename and ext given
    beep;
    [name path] = uigetfile(file_spec, title); %Display the dialogue box
    if ~any(name),
        Fs=[]; data=[]; d_rows=[]; d_columns=[]; name=[]; % Clear the named variables
        return; % **Alternate return for cancel operation. No data read from file.
    end;
    filename = [path name]; % Form full filename as path+name
    [pathstr,name,ext,versn] = fileparts(filename);
    if ~strcmpi(lower(ext),'.wav') & ~strcmpi(lower(ext),'.mat') & ~strcmpi(lower(ext),'.au'),
        h=errordlg('You must specify a .wav, .mat or .au extension ',error_title);
        beep;
        uiwait(h);
        repeat=true;
    end;
end; % of while loop to trap non .mat, .wav or .au files

switch lower(ext), % Force case statements to match against lower-case extension
    case '.wav'
        [data, Fs, bits] = wavread(filename); % Read a ".wav" file and load the sampling frequency
        
    case '.au'    
        [data, Fs, bits] = auread(filename); % Read a ".au" file and load the sampling frequency
        
    case '.mat'
        try,
            load(filename ,'Fs','data'); % Load a ".mat" file and keep the current sampling frequency
        catch,
            message=strvcat('File is not Roomsim audio format','File does not contain audio variables','Exiting');
            h=errordlg(message,error_title);
            beep;
            uiwait(h);
            return;
        end;
end;

% Further checks
[d_rows, d_columns] = size(data); % Check for one or two-channel roomsim audio datafile
if isempty(data)|d_columns>2,
    message = 'Cancelled read, or File is not Roomsim audio format';
    h=errordlg(message,error_title);
    beep;
    uiwait(h);
    return; % *** Alternate return
elseif isempty(Fs)|Fs==1,
    answer={};
    banner = 'Sampling frequency not specified in file';
    prompt = {'Enter Sampling frequency (Hz): '};
    lines = 1;
    def = {'44100'}; %Default value
    answer = inputdlg(prompt,banner,lines,def,'on');
    if isempty(answer),
        message = 'Dialogue cancelled ';
        h=warndlg(message,prefix);
        beep;
        pause(1);
        try,
            close(h); % Destroy the advisory notice if user has not cancelled
        catch,
        end;
        return; % *** Alternate return
    end; %of loop to trap dialogue box close button
    Fs=str2num(answer{1});
end;
fprintf(LOG_FID,'\n\n read_audio: File read was %s', filename); % Print to log file

%---------------------------- End of read_audio.m ----------------------------------------
