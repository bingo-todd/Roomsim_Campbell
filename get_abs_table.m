function [data, F_abs]=get_abs_table(S)
% Usage: [data, F_abs]=get_abs_table(S); This function extracts the surface absorption data from the Excel workbook SETUP.XLS,
% sheet name ABSORPTION TABLE, for use in the room simulation ROOMSIM.M.
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
% Functions called: getExcelSetup.m

[absorption_table] = getExcelSetup('setup.xls','absorption table'); % Get the data from the setup Excel spreadsheet
limit=size(absorption_table,1); %Get the number of rows in the sheet (allows user to add surfaces)
for n=1:6, % Move by column
    F_abs(n)=str2num(absorption_table{15,n+1}); % Read the frequency values
end;
for k=1:limit-15, % Move by row, the table starts at Excel row 15
    surface_list{k}=absorption_table{k+15,1}; % Read the surface name (Col 1)
    for n=1:6 % Move by column
        surface_data(k,n)=str2num(absorption_table{k+15,n+1}); % Read the absorption values (Cols 2 to 7)
    end;
end;

[selection,v] = listdlg('PromptString',['Select a surface type for ' S]...
                ,'SelectionMode','single'...
                ,'ListSize',[200 400]...
                ,'ListString',surface_list);
            
data=[];% If surface name not found, return empty            
if v
    data = surface_data(selection,:)';% Return surface absorption values as Column vectors.
end
%----------------------------- End of get_abs)table.m ----------------------------------------
