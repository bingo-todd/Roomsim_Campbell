function [answer,room_size,F_abs,A]=man_inp_room_surfaces;
% Usage: [answer,room_size,F_abs,A]=man_inp_room_surfaces;
% Prompted manual input of room dimensions and surface reflectance data
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
% Functions called: man_inp_surfaces.m .

% Declare and clear room dimensions
Lx =[]; Ly =[]; Lz =[]; room_size=[];
% Declare and clear absorption coefficient vectors
F_abs=[]; A=[];

% Room dimensions
Lz=1.25; % Basis length (m) for default values 
def_Lx=num2str(5*Lz);
def_Ly=num2str(3*Lz);
def_Lz=num2str(2*Lz);
def_vol=num2str(round(5*3*2*Lz^3)); % Compute volume of default room

banner = ['Room size (Default is ' def_vol 'm^3 room, Volkmann 5:3:2 ratio)'];
prompt = {'Enter Length (Depth) (Lx) of room in meters (m) :'...
        ,'Enter Width (Ly) of room in meters (m) :'...
        ,'Enter Height (Lz) of room in meters (m) :'};
lines=1;
def = {def_Lx,def_Ly,def_Lz}; %Default values (Volkmann 2:3:5 ratio 'living room/3 Person office dimensions')
beep;
answer={};
answer = inputdlg(prompt,banner,lines,def,'on');
if ~isempty(answer),% Trap CANCEL button operation
    Lx=str2num(answer{1});
    Ly=str2num(answer{2});
    Lz=str2num(answer{3});
    room_size=[Lx;Ly;Lz]; % Pack up room dimensions into column vector.
    
    answer={}; % Clear the answer flag
    [answer,F_abs,A]=man_inp_surfaces; % Get the surface reflectances
end;

%------------- End of man_inp_room_surfaces.m -------------------------
