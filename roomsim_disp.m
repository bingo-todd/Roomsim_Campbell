function roomsim_disp
% Usage: roomsim_disp.m; This function allows user to plot saved roomsim data without re-running roomsim_core.
%--------------------------------------------------------------------------- 
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
%-------------------------------------------------------------------------------
%Functions called: roomplot_imp.m, roomplot_magf.m, roomplot_2D.m, roomplot_3D.m

%*** Global Declarations ***
global H_filename; % Identifier for current impulse response file.

%***************************

M_banner='Display Utilities Menu';
Button1='Exit from Display Utilities';
Button2='Close all currently open figure windows';
Button3='3D Plot of the room, receiver and primary source(s)';
Button4='Plot of the room impulse response or energy decay';
Button5='Plot of the room frequency response';
Button6='2D Plot of the room and the image rooms';
Button7='3D Plot of the room and the image sources';
Button8='Vacancy';

M_Inputcase =0;
while M_Inputcase ~= 1 % Get the data file and display the plotting menu
    beep;
    repeat=true;
    while repeat,
        repeat=false;
        M_Inputcase = menu(M_banner,Button1,Button2,Button3,Button4,Button5,Button6,Button7,Button8);
        if M_Inputcase ~=0 & M_Inputcase ~=1 & M_Inputcase ~=2 & M_Inputcase ~=8,
            save_path=pwd; % Save pathname to present directory (folder)                       
            cd('Plot_data'); % Change directory to the Plot_data directory (folder)
            [name path] = uigetfile('plot_*.mat', 'Select previously saved data for plotting'); %Display the dialogue box
            cd(save_path); % Restore the previous directory (folder) path                  
            if ~any(name), 
                repeat=true; % repeat the display menu as a response to cancel operation
            else,
                load([path name]); %Get the previously stored values into the workspace
            end;
        end;
    end; % of repeat while loop for filename
    switch M_Inputcase,
        case 0
            return; % Window close button selected
            
        case 1
            return;
            
        case 2 % Close all currently open figure windows
            close all; % Shut down all the windows
            
        case 3 % 3D Plot of the room, receiver and the primary source(s)
            roomplot(room_size,source_xyz,receiver_xyz,receiver_off,receiver,sensor_xyz,head_width,alph);
            
        case 4 % Plot the impulse responses to each sensor
            roomplot_imp(Fs,H,receiver);
            
        case 5 % Plot the frequency responses to each sensor
            roomplot_magf(Fs,H,HRTF,receiver);
            
        case 6 % 2D Plot of the room and the image rooms
            % Display the receiver, source, image sources and image rooms as a 2D plan.
            roomplot_2D(c,Fs,room_size,source_xyz,receiver_xyz,receiver,sensor_xyz,H_length,source,p_isource);
            
        case 7 % 3D Plot of the room and the image sources
            roomplot_3D(room_size,source_xyz,receiver_xyz,receiver,sensor_xyz,source,p_isource);
            
        case 8 % *** Expansion space ***
            h=msgbox('This item has been left vacant for future expansion','roomsim_disp');
            beep;
            pause(1);
            try,
                close(h); % Destroy the advisory notice if user has not cancelled
            catch,
            end;
            
    end; % of switch case menu choices
    
end; % of menu while loop

%----------------------------------------- End of roomsim_disp.m --------------------------------