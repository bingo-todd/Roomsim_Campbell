function [param, abs, dir, source]=getTextSetup(filename);
%Usage: [param, abs, dir, source]=getTextSetup(filename);
% Read setup data from a text file.
%---------------------------------------------------------------------------- 
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
%---------------------------------------------------------------------------------
% get the single value parameters
header_L=1; % Number of header lines to skip
DL=33; % The number of data lines in this section of the text file 
[param_names,param(1:DL,1)] = textread(filename,'%s %s',DL,'headerlines',header_L,'commentstyle','matlab');

% get the surface absorptions for the room
header_L=DL+header_L+2; % Update Number of header lines to skip
DL=7; % The number of data lines in this section of the text file 
[abs_names(1:DL,1),abs(1:DL,1),abs(1:DL,2),abs(1:DL,3),abs(1:DL,4),abs(1:DL,5),abs(1:DL,6)] = textread(filename,'%s %s %s %s %s %s %s',DL,'headerlines',header_L,'commentstyle','matlab');

% get the sensor directionality
header_L=DL+header_L+2; % Update Number of header lines to skip
DL=6; % The number of data lines in this section of the text file 
[dir_names(1:DL,1),dir(1:DL,1),dir(1:DL,2)] = textread(filename,'%s %s %s',DL,'headerlines',header_L,'commentstyle','matlab');

% get the sources data
header_L=DL+header_L+2; % Update Number of header lines to skip
[name_list]=textread(filename,'%s%*[^\n]','headerlines',header_L,'commentstyle','matlab');
DL=size(name_list,1); % Get the number of rows in the sheet. This allows the number of sources to grow. 
[source_name(1:DL,1),source(1:DL,1),source(1:DL,2),source(1:DL,3)] = textread(filename,'%s %s %s %s','headerlines',header_L,'commentstyle','matlab');

%----------------------------- End of getTextSetup.m ----------------------------------------
