function multi_plot(filename, data_1, data_2, data_3, title_1, title_2, title_3, xscale, xtext, ytext, legend_1, legend_2);
% Usage: multi_plot(filename, data_1, data_2, data_3, title_1, title_2, title_3, xscale, xtext, ytext, legend_1, legend_2);
% Plot one to three sets of ordinate aligned data with a common vertical
% scaling, one above the other on the one page.
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
global FIG_LOC; % Location for plots. Loaded in roomsim.m

% Get number of plots and sizes for control of one or two channel plotting
if nargin>=8,
    n_plots=1;
    d1_columns=size(data_1,2);
    y_max_data_1 = max(max(abs(data_1))); % largest amplitude in data_1
    y_max = max([y_max_data_1]); % largest amplitude for vertical scaling of plots
end;
if nargin>=10 & ~isempty(data_2),
    n_plots=2;  
    d2_columns=size(data_2,2);
    y_max_data_2 = max(max(abs(data_2))); % largest amplitude in data_2
    y_max = max([y_max_data_1 y_max_data_2]); % largest amplitude for common vertical scaling of plots
end;
if nargin==12 & ~isempty(data_3),
    n_plots=3;
    d3_columns=size(data_3,2);
    y_max_data_3 = max(max(abs(data_3))); % largest amplitude in data_3
    y_max = max([y_max_data_1 y_max_data_2 y_max_data_3]); % largest amplitude for common vertical scaling of plots
end;

x_max=max(xscale);
x_min=min(xscale);

curr_fig=get(0,'CurrentFigure'); %Get handle of current figure
if isempty(curr_fig),
    figure(1); %Start first figure
else,
    figure(curr_fig+1); %Start new figure
end;
set(gcf,'Name',filename,'position',FIG_LOC); % Identify the figure and place it at FIG_LOC

clf ; %make sure it's a clean sheet
colordef white; % Force plot backgrounds to white

subplot(n_plots,1,1);
if d1_columns == 1, % Plot the previous accumulator data, mono
    plot(xscale,data_1(:,1),'k-'); 
    if ~isempty(legend_1),
        legend(legend_1);
    end;
else, % Plot the previous accumulator data, both channels L blue, R red
    plot(xscale,data_1(:,1),'b-',xscale,data_1(:,2),'r:');
    if ~isempty(legend_2),
        legend(legend_2);
    end;
end;
axis([x_min x_max -y_max y_max]);
title(title_1);
ylabel(ytext);

if ~isempty(data_2),
    subplot(n_plots,1,2);
    if d2_columns == 1, % Plot the data, mono
        plot(xscale,data_2(:,1),'k-');
    else, % Plot the data_2, both channels L blue, R red
        plot(xscale,data_2(:,1),'b-',xscale,data_2(:,2),'r:'); %Plot the data_2 for both channels
    end;
    ylabel(ytext);
    axis([x_min x_max -y_max y_max]);
    title(title_2);
end;

if ~isempty(data_3),
    subplot(n_plots,1,3);
    if d3_columns == 1, % Plot the accumulator data, mono
        plot(xscale,data_3(:,1),'k-'); 
    else, % Plot the accumulator data for both channels, L blue, R red
        plot(xscale,data_3(:,1),'b-',xscale,data_3(:,2),'r:');
    end;
    ylabel(ytext);
    axis([x_min x_max -y_max y_max]);
    title(title_3);
end;
xlabel(xtext);
%------------- End of multi_plot.m ----------------------------