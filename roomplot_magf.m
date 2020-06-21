function roomplot_magf(Fs,H,HRTF,receiver);
%Usage: roomplot_magf(Fs,H,HRTF,receiver);
% Plot the magitude vs frequency response for each sensor and superimpose the MIT or CIPIC HRTF if selected
%-------------------------------------------------------------------------- 
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

%*** Global Declarations ***
global FIG_LOC; % Location for plots. Loaded in roomsim_run.m
global H_filename; % Identifier for current impulse response file. Declared in roomsim_run.
%****************************

%--------------------------- Initialisation ----------------------------
HRTF_text=[]; % Declare text array for plotting
LL=[]; RR=[]; % Declare loop counters used for finding index of first non-zero value of impulse response
H_LEN_MAX = 8192; % This gives a resolution of 5.38 Hz at Fs=44.1 kHz.
H_LEN_MIN = 128; % This gives a resolution of 344.5 Hz at Fs=44.1 kHz and 62.5 Hz at Fs=8 kHz.
H_LEN = min([H_LEN_MAX max([size(H,1) size(HRTF,1)])]); % Use the longer of (the impulse response or the HRTF) if less than H_LEN_MAX
H_LEN_PV = pow2(nextpow2(H_LEN)); % Present value of longest data sensible for FFT (next power of two above H_LEN)
H_LEN_PV = max([H_LEN_PV H_LEN_MIN]); % Use the longer of H_LEN_MIN and H_LEN_PV

%Display a menu for adjusting FFT length (Spectral resolution)
prefix='Roomplot_magf: ';
msg_title=[prefix 'Select FFT length for Magnitude Spectrum'];
B1_text=['Use present value of ' num2str(H_LEN_PV) '. Resolution is ' num2str(Fs/H_LEN_PV) ' Hz'];
B2_text='Set a length (NB shorter will truncate the impulse response)';
beep;
M_FFTLcase=0;
M_FFTLcase = menu(msg_title,B1_text,B2_text);
switch M_FFTLcase
    case 0
        h=warndlg('Mag vs Freq plot cancelled',prefix);
        beep;
        pause(1);
        try,
            close(h); % Destroy the advisory notice if user has not cancelled
        catch,
        end;
        return; % Menu window closed no plot produced.
        
    case 1
        H_LEN = H_LEN_PV; % Keep present length
        
    case 2
        illegal=true;
        while illegal,
            answer={};
            msg_title = [prefix 'Set frequency resolution'];
            prompt = {['Enter FFT length in samples ' num2str(H_LEN_MIN) ' < ? < ' num2str(H_LEN_MAX) ':']};
            lines = 1;
            def = {num2str(pow2(nextpow2(Fs/5)-1))}; %Default value gives approx 5 Hz resolution
            beep;
            answer = inputdlg(prompt,msg_title,lines,def,'on');   
            if isempty(answer),
                h=warndlg('Mag vs Freq plot cancelled',prefix);
                beep;
                pause(1);
                try,
                    close(h); % Destroy the advisory notice if user has not cancelled
                catch,
                end;
                return; % Close dialogue box button operation, no plot produced.
            else,                
                H_LEN=str2num(answer{1});
                if H_LEN < H_LEN_MIN,
                    illegal=true;
                elseif H_LEN <= H_LEN_MAX,
                    illegal = false;
                end;
            end;
        end;
end;

curr_fig=get(0,'CurrentFigure'); %Get handle of current figure
if isempty(curr_fig),
    figh=figure(1); %Start first figure
else
    figh=figure();%(curr_fig+1); %Start new figure
end
set(figh,'Name',H_filename,'position',FIG_LOC); % Identify the figure and place it at FIG_LOC

clf; % Make sure it's a clean sheet
colordef white; % Force plot backgrounds to white

n_plots=size(H,3); % Size finds number of pages ie sources (ps)
threshold=1/1000; % Only a value above this threshold (-60dB) will be considered as the start of the impulse response
for ps=1:n_plots %Plot the frequency responses for each original source
    
    LL=1; % Initialise while loop for Left channel
    while LL<size(H(:,1,ps),1) & abs(H(LL,1,ps))< threshold, % Find index of first non-zero value in Left channel
        LL=LL+1;
    end;
    LL=LL-1; %Remove one sample offset due to incrementer
    start_index_L = max(1,LL); % Prevent Left indice being <1 and use it as start of FFT data
    stop_index_L = min([start_index_L+H_LEN-1 size(H,1)]); % Avoid running off the end of the data file
    % Apply an FFT of length H_LEN to the Left column of the impulse response array H
    TF_H(:,1) = fft(H(start_index_L:stop_index_L,1,ps),H_LEN,1); % Do an FFT of length H_LEN (will zero pad if needed)
    
    if ~strcmp(receiver,'one_mic'), % If no second channel for single sensor receiver
        RR=1; % Initialise while loop for Right channel
        while RR<size(H(:,2,ps),1) & abs(H(RR,2,ps))< threshold, % Find index of first non-zero value in Right channel
            RR=RR+1;
        end;
        RR=RR-1; %Remove one sample offset due to incrementer    
        start_index_R = max(1,RR); % Prevent Right indice being <1 and use it as start of FFT data
        stop_index_R = min([start_index_R+H_LEN-1 size(H,1)]); % Avoid running off the end of the data file
        % Apply an FFT of length H_LEN to the Right column of the impulse response array H
        TF_H(:,2) = fft(H(start_index_R:stop_index_R,2,ps),H_LEN,1); % Do an FFT of length H_LEN (will zero pad if needed)
    end;
    
    MTF_H = 20*log10(abs(TF_H(1:H_LEN/2,:))+eps); % Truncate to first half of spectrum and convert to magnitude dB 
    
    decim = fix(max([16 (H_LEN/2)/16])); % Step size for markers on hrir
    freq = (1:H_LEN/2)'*Fs/H_LEN; % Column vector of frequency values for plot axis
    freq_decim=freq(1:decim:fix(H_LEN/2));
    
    subplot(n_plots,1,ps);
    hold on;

    switch receiver % ---------- Identify receiver system---------------------
        case 'one_mic'
            plot(freq,MTF_H(:,1),'k-');
            legend('One Microphone (black)',3); 
            title_text=[num2str(H_LEN) ' point FFT Magnitude Spectrum at mono sensor']; % Text for title
            
        case 'two_mic', % Two sensor array
            plot(freq,MTF_H(:,1),'b-',freq,MTF_H(:,2),'r:');
            legend('Left Channel (blue)','Right Channel (red)',3);
            title_text=[num2str(H_LEN) ' point FFT Magnitude Spectrum at left and right sensors']; % Text for title
            
        case {'mithrir','cipicir'} % Check for MIT Kemar or CIPIC head
            hrir(:,:) = HRTF(:,:,ps); % Get hrir's for each parent source direction
            % Apply an FFT of length H_LEN down each of the columns of the impulse response array hrir
            TF_h = fft(hrir,H_LEN,1);
            % Compute log magnitude (dB) spectrum (0 to Fs/2) of impulse response array hrir
            MTF_h = 20*log10(abs(TF_h(1:H_LEN/2,:))+eps); 
            MTF_h_decim = MTF_h(1:decim:(H_LEN/2),:); % Decimate the transfer function for plotting marker points
            %Plot the HRTF for comparison if mithrir or cipicir was selected
            plot(freq,MTF_H(:,1),'b-',freq,MTF_H(:,2),'r:',freq_decim,MTF_h_decim(:,1),'b+',freq_decim,MTF_h_decim(:,2),'rs');
            legend('Left Ear (blue)','Right Ear (red)','Left HRTF','Right HRTF');
            plot(freq,MTF_h(:,1),'b--',freq,MTF_h(:,2),'r-.');
            title_text=[num2str(H_LEN) ' point FFT Magnitude Spectrum at left and right ears cf HRTF']; % Text for title
            
        otherwise
            disp('Unknown receiver set up at freq response plot');
            return;
    end;
    
    ytext=['Magnitude (dB) Source ' num2str(ps)];
    xlabel('Frequency (Hz)'); ylabel(ytext);
    if ps==1,
        title(title_text);
    end;
    axis([0 Fs/2 -60 20]);
    hold off;
end;
%-------------------------- End of roomplot_magf.m ----------------------