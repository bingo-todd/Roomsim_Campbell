function roomplot_imp(Fs,H,receiver);
% Usage: roomplot_imp(Fs,H,receiver);
% Plot the impulse response or energy decay to each sensor
%------------------------------------------------------------------------------ 
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
%----------------------------------------------------------------------------------
% Functions called: 

%*** Global Declarations ***
global FIG_LOC; % Location for plots. Loaded in roomsim_run.m
global H_filename; % Identifier for current impulse response file. Declared in roomsim_run.

%--------------------------- Initialisation ----------------------------
T=1/Fs; % Sampling period
n_plots=size(H,3); % Size finds number of pages ie sources (ps)

%Display the visualisation menu
prefix='Roomplot_imp: ';
B_menu_title=[prefix 'Choose plot type'];
B1_text='Impulse response amplitude';
B2_text='Impulse response 10*log10((amplitude)^2)';
B3_text='Relative energy decay (by Schroeder method)';
beep;
M_IRLcase=0;
M_IRLcase = menu(B_menu_title,B1_text,B2_text,B3_text);
switch M_IRLcase  % Set up the requested plot type.
    case 0
        h=warndlg('Impulse response plot cancelled',prefix);
        beep;
        pause(1);
        try,
            close(h); % Destroy the advisory notice if user has not cancelled
        catch,
        end;
        return; % Close dialogue box button operation, no plot produced.
        
    case 1 % Set up time scale for plot of impulse response
        PH=H;
        
    case 2 % Set up sample number scale for plot of impulse response 
        PH=10*log10(eps+H.^2); % Convert impulse response (amplitude)^2 to dB
        
    case 3 % Set up time scale for plot of impulse response (dB)
        PH=10*log10(eps+flipdim(T*cumtrapz(flipdim(H.^2,1)),1)); % Schroeder backward integration of impulse response (amplitude)^2
        PH=PH-max(max(max(PH))); % Find largest value and normalise to 0 dB maximum for relative energy decay plot
end;

C_menu_title=[prefix 'Choose ordinate units'];
C1_text='Time (seconds)';
C2_text='Sample number';
beep;
M_ax_case=0;
M_ax_case = menu(C_menu_title,C1_text,C2_text); % Set up the requested x axis scales: sample number or time.
switch M_ax_case % Select scales for plot
    case 0
        h=warndlg('Impulse response plot cancelled',prefix);
        beep;
        pause(1);
        try,
            close(h); % Destroy the advisory notice if user has not cancelled
        catch,
        end;
        return; % Close dialogue box button operation, no plot produced.
        
    case 1 % Set up time scale for plot
        xscale=[0:size(PH,1)-1]*T; % Time scale
        
    case 2 % Set up sample number scale for plot 
        xscale=[0:size(PH,1)-1]; % Sample number scale
end;

curr_fig=get(0,'CurrentFigure'); %Get handle of current figure
if isempty(curr_fig),
    figh=figure(1); %Start first figure
else,
    figh=figure();%(curr_fig+1); %Start new figure
end;
set(figh,'Name',H_filename,'position',FIG_LOC); % Identify the figure and place it at FIG_LOC

clf; % Make sure it's a clean sheet
colordef white; % Force plot backgrounds to white

for ps=1:n_plots %Plot the impulse responses for each original source
    subplot(n_plots,1,ps);
    hold on;
    if ps==1
        if (M_IRLcase==1),
            title(B1_text);
        elseif (M_IRLcase==2),
            title(B2_text);
        elseif (M_IRLcase==3),
            title(B3_text);
        end;
    end;
    switch receiver % ---------- Identify receiver system---------------------
        case 'one_mic'
            plot(xscale,PH(:,1,ps),'k-'); %Plot the impulse response to one sensor
            legend('Single Channel (black)');
        case {'two_mic','mithrir','cipicir'}  % Two sensor array or Head
            plot(xscale,PH(:,1,ps),'b-',xscale,PH(:,2,ps),'r:'); %Plot the impulse response to both channels
            switch receiver % ---------- Select receiver system---------------------
                case 'two_mic'
                    legend('Left Channel (blue)','Right Channel (red)');
                case {'mithrir','cipicir'}
                    legend('Left Ear (blue)','Right Ear (red)');
            end
        otherwise
            disp('Unknown receiver set up at impulse response plot');
            return
    end;
    
    V=axis;
    if (M_IRLcase==2)|(M_IRLcase==3),
        ytext=['Source ' num2str(ps) ' (dB)']; % Use a dB scale
        axis([V(1) V(2) -60 10]); % restrict dB scale, +10dB to -60dB range
    else
        ytext=['Source ' num2str(ps)]; % Plot linear amplitude of impulse response
        axis([V(1) V(2) V(3) V(4)]);
    end;
    if (M_ax_case==1), % Plot impulse response against time
        xtext=['Time (s)'];
    else
        xtext=['Sample Index Number']; % Plot impulse response against sample number
    end;
    xlabel(xtext); ylabel(ytext);

    hold off;
end;
%------------------- End of roomplot_imp.m ------------------------------------
