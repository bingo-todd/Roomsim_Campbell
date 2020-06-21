function [data, F_abs]=getAbsTableExcel(S)
% Usage: [data, F_abs]=getAbsTableExcel(S); This function extracts the surface absorption data
% from the Excel workbook absorption_table.XLS, sheet name ABSORPTION TABLE, for use in the room simulation roomsim.m.
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

% Compose pathname to absorption data file
abs_root ='Excel_setups';
abs_filename ='absorption_table.xls';
abs_file = fullfile(abs_root,abs_filename); %Form pathname to absorption data file
sheet_name = 'absorption table'; % Name of the Excel spreadsheet holding the absorption data

[abs_table_num, abs_table_text] = getExcelSetup(abs_file,sheet_name); % Get the data from the Excel spreadsheet
limit=size(abs_table_text,1); %Get the number of rows in the sheet (allows user to add surfaces)
for n=1:6, % Move by column
    F_abs(n)=abs_table_num(15,n+1); % Read the frequency values
end;
for k=1:limit-15, % Move by row, the table starts at Excel row 15
    surface_list{k}=abs_table_text{k+15,1}; % Read the surface name (Col 1)
    for n=1:6 % Move by column
        surface_data(k,n)=abs_table_num(k+15,n+1); % Read the absorption values (Cols 2 to 7)
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
%----------------------------- End of getAbsTableExcel.m ----------------------------------------
