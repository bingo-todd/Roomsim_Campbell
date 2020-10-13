function roomsim
%Usage: roomsim;   This Dispatcher charecterises the platform,
% and presents the welcome notice and the master menu for selecting Roomsim operations.
%
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
%
% Functions called: roomsim_welcome, roomsim_info.m, roomsim_run.m,
% roomsim_utils.m, roomsim_disp.m, speed_estimator.m

%*** Fresh Start ***
%(Comment next two lines out to enable breakpoints during debug)
close all; clear all;	%Clear graphics, clear workspace.
warning off; % Suppress warnings

%*** Global Declarations ***
global deg2rad; % Conversion factor degrees to radians
global rad2deg; % Conversion factor radians to degrees

global LOG_FID; % Identifier of logfile
global MAXSIZE; % largest number of elements allowed in an array on this machine
global MACHINE % Users machine identifier
global FIG_LOC; % Location for plots

global year_zero; % The most recent licence acceptance year

global SPEED_FACTOR; % To be used for estimating roomsim_core.m execution time
global CONV_FACTOR; % To be used for estimating convolution times for routines using conv.m (not in use)
global CONV_FACTOR_2; % To be used for estimating convolution times for roomsim_convolve.m, roomsim_cocktail.m
%***************************

%-----------------------------------------------------
% Installation data capture
first_time;% Display Welcome Screen and test acceptance of conditions of use, once per calendar year

%--------------------------------------------------------
% We're going to run so do the initialisation

% Initial equates
prefix='roomsim: ';
FIG_LEFT=100; % Set the left and bottom reference coordinates for the figure plots
FIG_BOTTOM=100;
FIG_LOC=[FIG_LEFT FIG_BOTTOM 450 350]; % Location for plots
%-----------------------------------------------

% Set up the log file
if ~exist([pwd '\Roomsim.log'],'file'),
    LOG_FID =fopen('Roomsim.log','wt'); % Open a new logfile for writing text and get an identifier
else,    
    M_banner=[prefix 'Overwrite or Append log file?'];
    Button1='Overwrite existing log file';
    Button2='Append to existing log file';
    beep;
    choice_m0=menu(M_banner,Button1,Button2);
    switch choice_m0,
        case 0, % Close window button pressed. Return to Matlab leaving "dirty" screen
            return;
            
        case 1, % *** Overwrite or open new log file if non-existing ***
            LOG_FID =fopen('Roomsim.log','wt'); % Open the logfile for writing text and get an identifier
            
        case 2,	% *** Append or open new log file if non-existing ***
            LOG_FID =fopen('Roomsim.log','at'); % Open the logfile for appending text and get an identifier
            
    end;%of menu0 choices
end; % of create or set up logfile
fprintf(LOG_FID,['\n\nRoomsim opened   ' datestr(now) '\n\n']); % Stamp the date and time of opening on the log file

%--------- Characterise platform -----------------------

% Identify a Windows PC machine, Matlab PC installation and the maximum array size.
[MACHINE,MAXSIZE]=computer; % Get machine type and max array size

% Check for Windows or Unix/Linux platform and record the system type in the logfile
if strcmp(MACHINE,'PCWIN'), 
    PCWIN=true; % Flag a Microsoft Windows PC
    fprintf(LOG_FID,'\n\nComputer is a Windows PC'); % Write to the logfile
else, % Non-PCWIN so
    PCWIN=false;
    fprintf(LOG_FID,'\n\nComputer is not a Windows PC, assuming a Unix/Linux machine with no access to Excel');
end;

if ispc, % Check for Windows or Unix/Linux MATLAB
    fprintf(LOG_FID,'\nMATLAB is a PC version');
elseif isunix,
    fprintf(LOG_FID,'\nMATLAB is a Unix/Linux version');
else,
    fprintf(LOG_FID,'\nMATLAB is not present (i.e. running roomsim.exe version)');
%     SPEED_FACTOR = SPEED_FACTOR/20; % Correct SPEED_FACTOR for compiled version. I don't know why but CONV_FACTOR doesn't need this.
end;
fprintf(LOG_FID,'\nMax number of array elements is %E \n', MAXSIZE);

%-------------- End of characterise platform and identify Excel user -------------------

%*** Now we start ***
deg2rad=pi/180; % GLOBAL Conversion factor degrees to radians
rad2deg=180/pi; % and radians to degrees

run_once=false;

M_banner=[prefix 'Main Menu'];
Button1='Exit to MATLAB (NB Clears windows)';
Button2='About Roomsim';
Button3='Roomsim Licence';
Button4='Set-up and Run the Room Simulation';
Button5='Build a "cocktail party"';
Button6='Display Utilities';
Button7='Audio Utilities';
Button8='Vacancy';
choice_m1 = 0;
while choice_m1 ~= 1,
    beep;
    choice_m1=menu(M_banner,Button1,Button2,Button3,Button4,Button5,Button6,Button7,Button8);
    switch choice_m1
        case 0, % Close window button pressed. Return to Matlab leaving "dirty" screen
            return;
            
        case 1, %*** Clean up and shut down ***
            fprintf(LOG_FID,['\n\nClosing Roomsim   ' datestr(now) '\n\n']); % Stamp the date and time of closing on the log file
            fclose(LOG_FID); % Close the log file
            close all; % Shut down all the windows

        case 2, % *** Display programme info ***
            roomsim_info;
            
        case 3,	 % *** Display licence info ***
            roomsim_licence;
            
        case 4,	% *** Set-up and run the room simulation ***
            [run_once, n_sources]=roomsim_run(run_once); % Return the number of parent sources and update run_once
            
        case 5,%*** Convolve impulse response(s) with signal(s) and accumulate ***
            if ~run_once,
                h=msgbox('You must run a room simulation first',prefix);
                beep;
                uiwait(h);% Wait for user to acknowledge
            elseif n_sources<2,
                h=msgbox('You must have two or more sources',prefix);
                beep;
                uiwait(h);% Wait for user to acknowledge
            else,
                roomsim_cocktail(n_sources);
            end;
            
        case 6,%*** Display Options ***
            roomsim_disp;

        case 7,%*** Utilities ***
            roomsim_utils;
            
        case 8, %*** Expansion space ***
            h=msgbox('This item has been left vacant for future expansion',prefix);
            beep;
            pause(1);
            try,
                close(h); % Destroy the advisory notice if user has not cancelled
            catch,
            end;
            
    end;%of menu1 choices
end; % of menu1 while loop

save roomsim_pp.mat year_zero SPEED_FACTOR CONV_FACTOR CONV_FACTOR_2; % update the passport file

clear all; % Clear the workspace
%-------------------- End of roomsim.m ------------------------------
