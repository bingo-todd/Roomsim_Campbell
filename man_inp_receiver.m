function [answer,receiver_xyz]=man_inp_receiver(room_size);
% Usage: [answer,receiver_xyz]=man_inp_receiver(room_size);
% Prompted manual input for Receiver reference location
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
%--------------------------------------------------------------------------------------
% Functions called: 

% Declare and clear receiver coordinates
receiver_xyz =[];

Lx=room_size(1); Ly=room_size(2); Lz=room_size(3);

% ---------------------------- Receiver location ----------------------
banner = 'Enter Receiver reference position [xp,yp,zp](m)';
prompt = {'Receiver x co-ordinate (m) (Default is room_length/4) :'...
        ,'Receiver y co-ordinate (m) (Default is room_width/2) :'...
        ,'Receiver z co-ordinate (m) (Default is typical seated ear height) :'};
lines=1;
def = {num2str(Lx/4),num2str(Ly/2),'1.1'}; %Default values
beep;
answer={};
answer = inputdlg(prompt,banner,lines,def,'on');
if isempty(answer),% Trap CANCEL or close window button operation
    return % Return to calling program
end;
xp=str2num(answer{1});
yp=str2num(answer{2});
zp=str2num(answer{3});
receiver_xyz=[xp;yp;zp]; % Pack up receiver (listener's head) coordinates into column vector.

%------------- End of man_inp_receiver.m -------------------------
