function multi_spectrogram(filename, Fs, data_1, data_2, data_3, title_1, title_2, title_3, xtext, ytext, title_L, title_R);
% Usage: multi_spectrogram(filename, Fs, data_1, data_2, data_3, title_1, title_2, title_3, xtext, ytext, title_L, title_R);
% Display three (one or two channel) ordinate aligned spectrograms on the one sheet.
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
% Functions called: specgram
% (N.B. specgram is a Matlab Signal Processing Toolbox function.
% If the function is not detected the operation is cancelled)
if  exist('specgram') == 0  % specgram does not exist or Sig Proc Toolbox absent 
    return; %so exit without displaying spectrogram plots 
else % Display spectrogram plots

    % GLOBALS
    global FIG_LOC; % Location for plots. Loaded in roomsim.m

    inv_max_DD1=[]; inv_max_DD2=[]; inv_max_DD3=[]; inv_max_DD4=[]; inv_max_DD5=[]; inv_max_DD6=[];% Declarations

    %---------------- Display tri-spectrogram page --------------------------

    % Normalise data_1, data_2 and data_3 for the spectrogram displays (removes any relative constant gain factor)
    n_plots=1;
    d1_columns=size(data_1,2);
    display_columns=max([d1_columns]);
    [DD1,F1,Tf1] = specgram(data_1(:,1),[],Fs,[],[]); % Display data_1 for spectrogram1
    inv_max_DD1 = 1/max(max(abs(DD1)));
    if d1_columns == 2, % Additional setup for two channel data
        [DD2,F2,Tf2] = specgram(data_1(:,2),[],Fs,[],[]); % Display data_1 for spectrogram2
        inv_max_DD2 = 1/max(max(abs(DD2)));
    end;
    % Compute an appropriate global scale factor and scale the data
    inv_max_DD=min([inv_max_DD1 inv_max_DD2]);
    dB_DD1=20*log10(abs(DD1).*inv_max_DD+eps); % Convert to dB below 0dB
    if ~ isempty(inv_max_DD2),
        dB_DD2=20*log10(abs(DD2).*inv_max_DD+eps);
    end;

    if ~isempty(data_2),
        n_plots=2;
        d2_columns=size(data_2,2);
        display_columns=max([d1_columns d2_columns]);
        [DD3,F3,Tf3] = specgram(data_2(:,1),[],Fs,[],[]); % Display data_2 for spectrogram3
        inv_max_DD3 = 1/max(max(abs(DD3)));
        if d2_columns == 2, % Additional setup for two channel data
            [DD4,F4,Tf4] = specgram(data_2(:,2),[],Fs,[],[]); % Display data_2 for spectrogram4
            inv_max_DD4 = 1/max(max(abs(DD4)));
        end;
        % Compute an appropriate global scale factor and scale the data
        inv_max_DD=min([inv_max_DD1 inv_max_DD2 inv_max_DD3 inv_max_DD4]);
        dB_DD1=20*log10(abs(DD1).*inv_max_DD+eps); % Convert to dB below 0dB
        dB_DD3=20*log10(abs(DD3).*inv_max_DD+eps);
        if ~ isempty(inv_max_DD2),
            dB_DD2=20*log10(abs(DD2).*inv_max_DD+eps);
        end;
        if ~ isempty(inv_max_DD4),
            dB_DD4=20*log10(abs(DD4).*inv_max_DD+eps);
        end;
    end;

    if ~isempty(data_3),
        n_plots=3;
        d3_columns=size(data_3,2);
        display_columns=max([d1_columns d2_columns d3_columns]);
        [DD5,F5,Tf5] = specgram(data_3(:,1),[],Fs,[],[]); % Display data_3 for spectrogram5
        inv_max_DD5 = 1/max(max(abs(DD5)));
        if d3_columns == 2, % Additional setup for two channel data
            [DD6,F6,Tf6] = specgram(data_3(:,2),[],Fs,[],[]); % Display data_3 for spectrogram4
            inv_max_DD6 = 1/max(max(abs(DD6)));
        end;
        % Compute an appropriate global scale factor and scale the data
        inv_max_DD=min([inv_max_DD1 inv_max_DD2 inv_max_DD3 inv_max_DD4 inv_max_DD5 inv_max_DD6]);
        dB_DD1=20*log10(abs(DD1).*inv_max_DD+eps); % Convert to dB below 0dB
        dB_DD3=20*log10(abs(DD3).*inv_max_DD+eps);
        dB_DD5=20*log10(abs(DD5).*inv_max_DD+eps);
        if ~ isempty(inv_max_DD2),
            dB_DD2=20*log10(abs(DD2).*inv_max_DD+eps);
        end;
        if ~ isempty(inv_max_DD4),
            dB_DD4=20*log10(abs(DD4).*inv_max_DD+eps);
        end;
        if ~ isempty(inv_max_DD6),
            dB_DD6=20*log10(abs(DD6).*inv_max_DD+eps);
        end;
    end;

    curr_fig=get(0,'CurrentFigure'); %Get handle of current figure
    if isempty(curr_fig),
        figure(1); %Start first figure
    else,
        figure(curr_fig+1); % Start new figure
    end;
    set(gcf,'Name',filename,'position',FIG_LOC); % Identify the figure and place it at FIG_LOC

    clf ; %make sure it's a clean sheet
    colormap jet;
    clims=[-90 0]; % Set dB limits for spectrogram colormap

    subplot(n_plots,display_columns,1);
    imagesc(Tf1,F1,dB_DD1,clims);
    axis xy;
    V=axis; % Get axis scaling for all spectrogram plots
    axis([0 V(2) 0 V(4)]);
    if d1_columns == 1,
        title(title_1);
    else,
        title([title_1 title_L]);
    end;
    if isempty(data_2),
        xlabel([xtext]);
    end;
    ylabel(ytext);
    if d1_columns == 2,% Display the right hand column
        subplot(n_plots,display_columns,2);
        imagesc(Tf2,F2,dB_DD2,clims);
        axis xy;
        axis([0 V(2) 0 V(4)]);
        title([title_1 title_R]);
        if isempty(data_2),
            xlabel([xtext]);
        end;
    end;
    colorbar;

    if ~isempty(data_2),
        subplot(n_plots,display_columns,display_columns+1);
        imagesc(Tf3,F3,dB_DD3,clims);
        axis xy;
        axis([0 V(2) 0 V(4)]);
        if d2_columns == 1,
            title(title_2);
        else,
            title([title_2 title_L]);
        end;
        if isempty(data_3),
            xlabel([xtext]);
        end;
        ylabel(ytext);
        if d2_columns == 2,% Display the right hand column
            subplot(n_plots,display_columns,display_columns+2);
            imagesc(Tf4,F4,dB_DD4,clims);
            axis xy;
            axis([0 V(2) 0 V(4)]);
            title([title_2 title_R]);
            if isempty(data_3),
                xlabel([xtext]);
            end;
        end;
        colorbar;
    end;

    if ~isempty(data_3),
        subplot(n_plots,display_columns,2.*display_columns+1);
        imagesc(Tf5,F5,dB_DD5,clims);
        axis xy;
        axis([0 V(2) 0 V(4)]);
        if d3_columns == 1,
            title(title_3);
        else,
            title([title_3 title_L]);
        end;
        xlabel([xtext]);
        ylabel(ytext);
        if d3_columns == 2,% Display the right hand column
            subplot(n_plots,display_columns,2.*display_columns+2);
            imagesc(Tf6,F6,dB_DD6,clims);
            axis xy;
            axis([0 V(2) 0 V(4)]);
            title([title_3 title_R]);
            xlabel([xtext]);
        end;
        colorbar;
    end;

end;
%-----------------End of multi_spectrogram.m ----------------------------
