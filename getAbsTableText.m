function [surface_data, F_abs]=getAbsTableText(S);
% Usage: [surface_data, F_abs]=getAbsTableText(S); This function extracts the surface absorption data
% from the text file absorption_table.txt for use in the room simulation roomsim.m.
% It prompts the user to select a choice for the surface S from a list of surfaces using a list dialogue box 
% allowing one item to be selected per entry to the function.
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
% Functions called:

% Compose pathname to absorption data file
abs_root ='Text_setups';
abs_filename ='absorption_table.txt';
abs_file = fullfile(abs_root,abs_filename); %Form pathname to absorption data file

[name, F_abs(1), F_abs(2), F_abs(3), F_abs(4), F_abs(5), F_abs(6)] = textread(abs_file,'%s %d %d %d %d %d %d',1,'headerlines',14,'commentstyle','matlab');
% Find out the length of the surface list. This approach allows user to add surfaces.
[surface_list]=textread(abs_file,'%s%*[^\n]','headerlines',15,'commentstyle','matlab');   
LL=size(surface_list,1); % Get the number of rows in the sheet 
[surface_list(1:LL),data(1:LL,1),data(1:LL,2),data(1:LL,3),data(1:LL,4),data(1:LL,5),data(1:LL,6)] = textread(abs_file,'%s %f %f %f %f %f %f','headerlines',15,'commentstyle','matlab');

[selection,v] = listdlg('PromptString',['Select a surface type for ' S]...
                ,'SelectionMode','single'...
                ,'ListSize',[200 400]...
                ,'ListString',surface_list);
            
surface_data=[];% If surface name not found, return empty            
if v
    surface_data = data(selection,:)';% Return surface absorption values as Column vectors.
end
%----------------------------- End of getAbsTableText.m ----------------------------------------