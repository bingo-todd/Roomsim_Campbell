function roomsim_utils
%Usage: roomsim_utils;   This Dispatcher allows the user to select utility functions within Roomsim
%------------------------------------------------------------------
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
%-------------------------------------------------------------------------
% Functions called: roomsim_convolve.m, roomsim_accumulate, roomsim_convert, roomsim_filter.m;

%*** Global Declarations ***

%-------------------------------------------------------
M_banner='Audio Utilities Menu';
Button1='Exit from Audio Utilities';
Button2='Convolve two Roomsim audio files';
Button3='Accumulate Roomsim audio files';
Button4='Convert Roomsim audio files';
Button5='Display a Roomsim audio file';
Button6='Filter a Roomsim audio file';
Button7='Cross-correlate the channels (L & R) of a two channel audio file';
Button8='Vacancy';
choice_util = 0;
while choice_util ~= 1,
    beep;
    choice_util=menu(M_banner,Button1,Button2,Button3,Button4,Button5,Button6,Button7,Button8);
    
    switch choice_util
        case 0,
            return; % Menu window closed
            
        case 2, % *** Convolve two audio files ***
            roomsim_convolve;
            
        case 3,	% *** Accumulate audio files and plot the results ***
            roomsim_accumulate;
            
        case 4, % *** Convert from *.mat to *.wav or vice versa ***
            roomsim_convert;
            
        case 5, % *** Display the time history, spectrogram and sound of an audio data file ***
            roomsim_show;
            
        case 6, % *** Filter a Roomsim audio file using a user selected filter coefficient file ***
            roomsim_filter; 
            
        case 7, % *** Cross-correlate the channels of a two channel audio file ***
            roomsim_crosscorr;

        case 8, % *** Expansion space ***
            h=msgbox('This item has been left vacant for future expansion','roomsim_utils');
            beep;
            pause(1);
            try,
                close(h); % Destroy the advisory notice if user has not cancelled
            catch,
            end;
            
    end;%of menu_util choices
    
end; % of menu_util while loop
%------------ End of roomsim_utils.m--------------
