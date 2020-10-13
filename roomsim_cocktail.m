function roomsim_cocktail(n_sources);
%Usage: roomsim_cocktail(n_sources);   
% Convolves impulse response(s) and signal(s) and their accumulation result, and saves them as files.
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
% Functions called: read_audio.m, save_audio.m.

%*** Global Declarations ***
global LOG_FID; % Identifier of logfile. Loaded in roomsim.m
global MACHINE % User machine identifier. Loaded in roomsim.m
global CONV_FACTOR; % Used for estimating convolution times. Loaded in speed_estimator.m
global CONV_FACTOR_2; % Used for estimating convolution times by block scheme. Loaded in speed_estimator.m
global H_filename; % Identifier for current impulse response file. Declared in roomsim_run.
%***************************

prefix='roomsim_cocktail: ';
error_title= [prefix 'error'];
fprintf(LOG_FID,'\n\n In roomsim_cocktail'); % Print to log file (avoids wait for user response)

save_path=pwd; % Save pathname to present directory (folder)                       
cd('Impulse_response'); % Change directory to the Impulse_response directory (folder)
for ps=1:n_sources % For each parent source get the impulse responses
    imp_file_name=[H_filename '_S' num2str(ps)]; % Compose the impulse response filename for primary source ps
    load(imp_file_name,'Fs','data'); % Load the sampling frequency and an impulse response.
    H(:,:,ps)=data; % Copy impulse response data(1:H_length,1:channels) into array H(1:H_length,1:channels,1:n_sources).
end; % of ps counter loop for number of parent sources
cd(save_path); % Restore the previous directory (folder) path                  
H_length=size(H,1); % Length of impulse responses in samples
channels=size(H,2); % Number of channels

signal=cell(1,n_sources); % Initialise the array for saving the signals
filenames=cell(1,n_sources); % Initialise the array for saving the signal filenames
for ps=1:n_sources % For each parent source get a signal file
    repeat=true;
    while repeat,
        repeat=false;
        file_spec={'*.mat;*.wav;*.au;','Roomsim Audio Files (*.mat,*.wav,*.au)';'*.*', 'All Files (*.*)'}; %
        banner=['Choose the signal file (*.wav, *.mat or *au) for source ' num2str(ps)];
        [Fs_data, data, d_rows_temp, d_columns, filename] = read_audio(file_spec, banner); % Get the signal to be convolved with the impulse response
        %--------------------------- Check the data file -------------------------------
        if isempty(Fs_data)|isempty(data), % Cancelled read or error has already been flagged in read_audio
            return; % *** Alternate return to calling function
        end;
        d_rows(ps)=d_rows_temp; % Record the number of rows for each source audio file
        filenames{ps}=filename; % Store each source audio filename in a cell array
        
        banner = [prefix 'Error'];
        if abs(Fs-Fs_data) > eps,     
            message='Sampling frequencies are not equal';
            beep;
            button = questdlg(message,banner,'Cancel','Reselect signal file','Cancel');
            if strcmp(button,'Cancel'),
                return; % *** Alternate return to calling function
            else,
                repeat=true; % Force loop back to reselect signal file
            end;
        elseif d_columns ~= 1, % check for single column (channel)
            message='Signal source must be single channel';
            beep;
            button = questdlg(message,banner,'Cancel','Reselect signal file','Cancel');
            if strcmp(button,'Cancel'),
                return; % *** Alternate return to calling function
            else,
                repeat=true; % Force loop back to reselect signal file
            end;
        end; % of sampling frequency and single channel check
    end; % of while loop allowing file reselection
    
    rms_source(ps)=norm(data)./sqrt(length(data)); %Compute root mean square value of the signal at source ps

    signal{ps}=data; % Copy the data into a cell array 
    
end; % of loop to get a signal file for each parent source

if n_sources >1, % Offer pre-mix scaling facility
    message='Set source intensities relative to source_1';
    answer={};
    banner = [prefix message];
    for ps=2:n_sources,
        prompt{ps-1}=['Enter relative intensity in dB of source ' num2str(ps) ' :'];
        def{ps-1}='0'; %Default values for making all sources of equal intensity
    end;
    lines = 1;
    beep;
    answer = inputdlg(prompt,banner,lines,def,'on');
    if isempty(answer),
        h=warndlg('Set relative intensities cancelled',prefix);
        beep;
        pause(1);
        try,
            close(h); % Destroy the advisory notice if user has not cancelled
        catch,
        end;
        return; % Close dialogue box button operation, no cocktail party produced.
    end;
    
    NdB(1)=0;
    for ps=2:n_sources % Scale each parent source by NdB relative to source_1
        NdB(ps)=str2num(answer{ps-1});
        ScaleFactor(ps)=(rms_source(1)./rms_source(ps)).*10.^(NdB(ps)/20);
        signal{ps}=signal{ps}.*ScaleFactor(ps);
    end;
end;

    %-------------- Convolutions -------------------------
for ps=1:n_sources % For each parent source do the convolution and accumulation
    data=[]; % Declare variable and clear past values (ensuring no problems when re-used in loop)
    temp=signal{ps};
    
    N=H_length+length(temp)-1;
    FFT_length=2^nextpow2(N);
    time_est=ceil(channels.*FFT_length.*log2(FFT_length)./CONV_FACTOR_2); % Convolution time estimate for frame_conv
    
    colordef white; % Force waitbar backgrounds to white
    wait_msg_con = [' This may take ' num2str(time_est) ' seconds. Please wait ...'];
    ident=[' Convolving source ' num2str(ps)]; % Identify source by number
    h_conv = waitbar(0.1,wait_msg_con,'name',[prefix ident]); % Let the user know something is happening
    
    [data_1, data_2] = check_swap(H(:,1,ps),temp); % Find shorter data sequence making it data_1, swap if necessary   
    % Do the convolutions using the overlap-add block filtering scheme. H is impulse response , data is audio file.
    data(:,1) = frame_conv(data_1,data_2); % Convolve single or Left channel impulse response with signal from source ps
    
    clear data_1 data_2; % Free up PC memory
    waitbar(0.5,h_conv); % Let the user know something is happening
    
    if channels==2,
        [data_1, data_2] = check_swap(H(:,2,ps),temp); % Find shorter data sequence making it data_1, swap if necessary
        % Do the convolutions using the overlap-add block filtering scheme. H is impulse response , data is audio file.
        data(:,2) = frame_conv(data_1,data_2); % Convolve Right channel impulse response with signal from source ps
        
        clear data_1 data_2 temp; % Free up PC memory
        waitbar(0.9,h_conv); % Let the user know something is happening
    end;
    
    close(h_conv);
    
    clear temp; % Free up memory
    
    % Save the sampling frequency and one single or two channel pair of convolution results per parent source
    % in a Roomsim audio format MAT file named Convolved_S1, Convolved_S2, etc.
    save_path=pwd; % Save pathname to present directory (folder)                       
    cd('Cocktail_data'); % Change directory to the Cocktail_data directory (folder)
    conv_file_name=['Convolved_S' num2str(ps)]; % Compose the convolution result filename for primary source ps
    save(conv_file_name,'Fs','data'); % Save to file. NB Explicit naming for compilation as stand-alone exe
    cd(save_path); % Restore the previous directory (folder) path
    
    fprintf(LOG_FID,'\n\n roomsim_cocktail: convolution result data using %s has been saved to %s',filenames{ps}, conv_file_name); % Print to log file
    signal_len(ps)=size(data,1); % Store the length of the convolution result for this source
    clear data; % Free up memory
end; % of ps counter loop for number of parent sources

%---------------------- Mixer ----------------------
% Put the convolution results into an array for playing, also mix (accumulate) them as a "cocktail party"
max_len=max(signal_len); % Find length of longest convolution result
all_convs=zeros(max_len,channels,n_sources); % Declare array large enough to hold all convolutions
accum=zeros(max_len,channels); % Declare array for accumulating all convolved results
rms_signal=zeros(n_sources,channels); % declare array for rms value of signals received at the sensor(s)

save_path=pwd; % Save pathname to present directory (folder)                       
cd('Cocktail_data'); % Change directory to the Cocktail_data directory (folder)
for ps=1:n_sources % For each parent source
    conv_file_name=['Convolved_S' num2str(ps)]; % Compose the convolution result filename for primary source ps
    load(conv_file_name,'Fs','data'); % Load the sampling frequency and a convolution result.
    all_convs(1:signal_len(ps),:,ps)=data; % Put the convolution result in its page in the holding array
    accum(1:signal_len(ps),:)=accum(1:signal_len(ps),:)+data; % Accumulate the convolution results (Cocktail party)

    rms_signal(ps,1)=norm(data(:,1))./sqrt(signal_len(ps)); %Compute rms value, at the single or L sensors, of the signal from source ps
    if channels==2,
        rms_signal(ps,2)=norm(data(:,2))./sqrt(signal_len(ps)); %Compute rms value, at the R sensor, of the signal from source ps
    end;
end; % of ps counter loop for number of parent sources
cd(save_path); % Restore the previous directory (folder) path                  
clear data; % Free up memory

NdB=zeros(n_sources,channels);
if channels==1,
    fprintf(LOG_FID,'\n\n roomsim_cocktail: rms value of signal from source 1 at single sensor = %6.2f', rms_signal(1,1)); % Print to log file
else, % two channels
   fprintf(LOG_FID,'\n\n roomsim_cocktail: rms value of signal from source 1 at sensor [L R] = [ %6.2f %6.2f ]', rms_signal(1,:)); % Print to log file
end; 
for ps=2:n_sources % Get the value of the signal from each parent source in dB relative to source 1
    NdB(ps,:)=20.*log10(rms_signal(ps,:)./rms_signal(1,:));
    if channels==1,
        fprintf(LOG_FID,'\n\n roomsim_cocktail: source %i to source 1 ratio at single sensor = %6.2f dB',ps, NdB(ps,1)); % Print to log file
    else, % two channels
        fprintf(LOG_FID,'\n\n roomsim_cocktail: source %i to source 1 ratio at sensor [L R] = [ %6.2f %6.2f ] dB',ps, NdB(ps,:)); % Print to log file
    end;
end;

if strcmp(MACHINE,'PCWIN'); % Allow sound playing if PCWin detected at startup.   
    %---------------------- Provide sound output ----------------------
    max_data = max(max(max(abs(all_convs)))); % Find max of all sources and channels
    max_accum = max(max(abs(accum))); % Find max of accumulator data
    scale_factor = max([max_accum max_data]); % Find global scale factor so that sounds are all scaled in proportion
    
    n_sources_txt=num2str(n_sources); % Number of sources as text string
    beep; % Alert user
    repeat=true; % Initialise while loop
    while repeat, 
        answer={};
        banner = ['There are ' n_sources_txt ' sources(s)'];
        prompt = {strvcat('To play the accumulation of sources, enter 0',['To play a single source, enter its number 1 to ' n_sources_txt])};
        lines = 1;
        def = {'0'}; %Default value
        answer = inputdlg(prompt,banner,lines,def,'on');
        if isempty(answer),
            break;
        elseif answer{1} > n_sources_txt,
            answer={}; % Force re-entry of legal source number
        end;
        ps=str2num(answer{1});
        if ps==0,
            data=accum./scale_factor;  %Scale accumulator channels into a range +/- < 1
        else,
            data=all_convs(1:signal_len(ps),:,ps)./scale_factor;  %Scale convolved source signal into a range +/- < 1
        end;
        wavplay(data,Fs,'sync'); % Windows PC user can listen to data contents now
    end;% of sound play
end;

%----------------------- Save the accumulation result ------------------------
banner='Save accumulation result (*.wav/*.au allows media player to play it)';
file_spec={'*.wav','Windows PCM (*.wav)';'*.mat','MAT-files (*.mat)';'*.au','NeXT/SUN (*.au)';'*.*','All Files (*.*)'}; % wav first as more likely
save_audio(file_spec,Fs,accum,banner); % Save the result of the accumulation

%-------------------------- End of roomsim_cocktail.m --------------------------
