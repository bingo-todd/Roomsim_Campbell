function [answer,F_abs,A]=man_inp_surfaces;
% Usage: [answer,F_abs,A]=man_inp_surfaces;
% Prompted manual input of the absorption coefficients for each surface
%-------------------------------------------------------------------------------- 
% Copyright (C) 2004  Douglas R Campbell
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
%--------------------------------------------------------------------------
% Functions called: getAbsTableText.m, getAbsTableExcel.m.

%*** Global Declarations ***
global LOG_FID; % Identifier of logfile. Loaded in roomsim.m
global MACHINE % Users machine identifier. Loaded in roomsim.m
%***************************

% Declare and clear absorption coefficient vectors
F_abs=[]; Abs=[]; Ax1=[]; Ax2=[]; Ay1=[]; Ay2=[]; Az1=[]; Az2=[]; A=[];

answer={1};

prefix='man_inp_surfaces: ';
error_title=[prefix ' Error'];

%--------------- Get the absorption coefficients for each surface (and check they exist) ---------
if strcmp(MACHINE,'PCWIN'); % If PCWin detected at startup, offer Excel or Text absorption table.
    msg_title=[prefix 'Excel Query for Windows PC'];
    message='Read absorption table data from the Excel spreadsheet or the Text file';
    beep;
    button_order=[];
    button_order = questdlg(message,msg_title,'Excel','Text','Text'); % Offer Excel or Text absorption table
    if isempty(button_order),% Trap CANCEL button operation
        answer={};
        return
    elseif strcmp(button_order,'Excel'),
        EXCEL= true; % Use Excel files for absorption table and setup
        fprintf(LOG_FID,'\n\nUsing Excel spreadsheet, absorption_table.xls');
    else,
        EXCEL= false; % Use Text files for absorption table and setup
        fprintf(LOG_FID,'\n\nUsing Text file, absorption_table.txt');
    end;
else,
    EXCEL= false; % Not PCWin so use Text files for absorption table and setup
    fprintf(LOG_FID,'\n\nUsing Text file, absorption_table.txt');
end;

surf_error=strvcat('Surface type selection cancelled, returning to Setup Menu');
button=[];
beep;
button = questdlg('All surfaces have identical absorption?','roomsim_setup:','Yes','No','Yes');
if isempty(button),% Trap CANCEL button operation
    answer={};
    return,
end;
switch button
    case 'Yes' % All surfaces identical
        if ~EXCEL; % Trap non-Excel user
            [Abs F_abs]=getAbsTableText('Abs');
        else, % Excel user
            [Abs F_abs]=getAbsTableExcel('Abs');
        end;
        if isempty(Abs),
            h=errordlg(surf_error,error_title);
            beep;
            uiwait(h);
            answer={};
            return
        end;
        Ax1=Abs; Ax2=Abs; Ay1=Abs; Ay2=Abs; Az1=Abs; Az2=Abs; 
    case 'No' % Non-identical absorption, get each one individually
        if ~EXCEL; % Trap non-Excel user
            [Ax1 F_abs]=getAbsTableText('Ax1');
        else, % Excel user
            [Ax1 F_abs]=getAbsTableExcel('Ax1');
        end;
        if isempty(Ax1), % Trap cancel button operation
            h=errordlg(surf_error,error_title);
            beep;
            uiwait(h);
            answer={};
            return
        end;
        if ~EXCEL; % Trap non-Excel user
            [Ax2 F_abs]=getAbsTableText('Ax2');
        else, % Excel user
            [Ax2 F_abs]=getAbsTableExcel('Ax2');
        end;
        if isempty(Ax2), % Trap cancel button operation
            h=errordlg(surf_error,error_title);
            beep;
            uiwait(h);
            answer={};
            return
        end;
        if ~EXCEL; % Trap non-Excel user
            [Ay1 F_abs]=getAbsTableText('Ay1');
        else, % Excel user
            [Ay1 F_abs]=getAbsTableExcel('Ay1');
        end;
        if isempty(Ay1), % Trap cancel button operation
            h=errordlg(surf_error,error_title);
            beep;
            uiwait(h);
            answer={};
            return
        end;
        if ~EXCEL; % Trap non-Excel user
            [Ay2 F_abs]=getAbsTableText('Ay2');
        else, % Excel user
            [Ay2 F_abs]=getAbsTableExcel('Ay2');
        end;
        if isempty(Ay2), % Trap cancel button operation
            h=errordlg(surf_error,error_title);
            beep;
            uiwait(h);
            answer={};
            return
        end;
        if ~EXCEL; % Trap non-Excel user
            [Az1 F_abs]=getAbsTableText('Az1');
        else, % Excel user
            [Az1 F_abs]=getAbsTableExcel('Az1');
        end;
        if isempty(Az1), % Trap cancel button operation
            h=errordlg(surf_error,error_title);
            beep;
            uiwait(h);
            answer={};
            return
        end;
        if ~EXCEL; % Trap non-Excel user
            [Az2 F_abs]=getAbsTableText('Az2');
        else, % Excel user
            [Az2 F_abs]=getAbsTableExcel('Az2');
        end;
        if isempty(Az2), % Trap cancel button operation
            h=errordlg(surf_error,error_title);
            beep;
            uiwait(h);
            answer={};
            return
        end;
end; % of switch case for surface selection
A=[Ax1 Ax2 Ay1 Ay2 Az1 Az2]; % Pack up column vectors of absorption coefficients in array A
%---------------- End of man_inp_surfaces.m surface absorption manual set up ---------------
