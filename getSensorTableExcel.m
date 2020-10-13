function [S_type]=getSensorTableExcel(S);
% Usage: [S_type]=getSensorTableExcel(S); This function extracts the sensor types
% from the Excel workbook sensor_table.XLS, sheet name SENSOR TABLE, for use in the room simulation ROOMSIM.M.
% It prompts the user to select a choice for the sensor S from a list of sensors using a list dialogue box 
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

[sensor_table_num, sensor_table_text] = getExcelSetup('sensor_table.xls','sensor table'); % Get the data from the setup Excel spreadsheet
limit=size(sensor_table_text,1); %Get the number of rows in the sheet (allows user to add surfaces)

for k=1:limit-15, % Move by row, the table starts at Excel row 15
    sensor_list{k}=sensor_table_text{k+15,1}; % Read the sensor name (Col 1)
end;

[selection,v] = listdlg('PromptString',['Select a sensor type for ' S]...
                ,'SelectionMode','single','ListSize',[200 200],'ListString',sensor_list);
            
S_type=[];% If sensor name not found, return empty            
if v
    S_type = sensor_list{selection};% Return sensor type as text string.
end
%----------------------------- End of getSensorTableExcel.m ----------------------------------------
