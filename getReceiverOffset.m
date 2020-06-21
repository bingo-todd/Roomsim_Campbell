function [answer,receiver_off]=getReceiverOffset;
% Usage: [receiver_off]=getReceiverOffset;
% Get the receiver offsets and check they're sensible
% receiver_off(yaw, pitch, roll) is the rotational offset (degrees).
%------------------------------------------------------------------------------------ 
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
%--------------------------------------------------------------------------------------
%Functions called: 

receiver_off=zeros(3,1); % Declare and clear receiver Yaw, Pitch & Roll offsets

out_of_range = true;
while out_of_range, %Loop if sensor offset data is not sensible
    answer={};
    banner = 'Receiver offset angles from room axes system';
    prompt = {'Enter -180< yaw offset <180 deg:'...
            ,'Enter -90< pitch offset <90 deg:'...
            ,'Enter -180< roll offset <180 deg:'};
    lines = 1;
    def = {'0','0','0'}; %Default values for x axis look direction
    beep;
    answer = inputdlg(prompt,banner,lines,def,'on');
    if isempty(answer),% Trap Close window or CANCEL button operation
        return;% 
    end;
        receiver_off(1)=str2num(answer{1}); % Yaw offset
        receiver_off(2)=str2num(answer{2}); % Pitch offset
        receiver_off(3)=str2num(answer{3}); % Roll offset
        
        % Check values within range
        if receiver_off(1) < -180 || receiver_off(1) > 180,
            message='-180< Receiver yaw offset <180 deg';
        elseif receiver_off(2) < -90 || receiver_off(2) > 90,
            message='-90< Receiver pitch offset <90 deg';
        elseif receiver_off(3) < -180 || receiver_off(3) > 180,
            message='-180< Receiver roll offset <180 deg';
        else,
            out_of_range = false; % Input accepted
        end;
        
        if out_of_range,
            banner='Re-enter value';
            h=msgbox(message,banner,'warn');  %Warn & beep.
            beep;
            uiwait(h);% Wait for user to acknowledge
            answer={};
        end;
end; % of WHILE loop checking out of range
%------ End of getReceiverOffset.m ----------------
