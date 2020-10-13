function [xyz]=rotate(xyz,yaw,pitch,roll);
%Usage: [x,y,z]=rotate(xyz,yaw,pitch,roll);
%Apply a rotation in yaw, pitch & roll to a position vector [x;y;z]
% i.e. Rotational axes transformation
%----------------------------------------------------------------------------- 
% 
% Copyright (C) 2003  Douglas R Campbell
% 
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
%-----------------------------------------------------------------------------------
%Functions called:

deg2rad=pi/180;

% Psi is azimuth (yaw), Theta is elevation (pitch), Phi is roll
psi=yaw.*deg2rad; % Azimuth offset of sensor body
theta=-pitch.*deg2rad;% Elevation offset of sensor body NB -ve sign adjusts for rotational conventions
phi=roll.*deg2rad;% Roll offset of sensor body

% Compute cos and sin here for efficiency
c_psi=cos(psi); 
s_psi=sin(psi);
c_theta=cos(theta);
s_theta=sin(theta);
c_phi=cos(phi);
s_phi=sin(phi);

%Room axis to sensor body axis transformation matrix tm, general version.
tm=[c_theta.*c_psi                      c_theta.*s_psi                      -s_theta...
   ;s_phi.*s_theta.*c_psi-c_phi.*s_psi  s_phi.*s_theta.*s_psi+c_phi.*c_psi  s_phi.*c_theta...
   ;c_phi.*s_theta.*c_psi+s_phi.*s_psi  c_phi.*s_theta.*s_psi-s_phi.*c_psi  c_phi.*c_theta];

xyz=tm'*xyz; % Rotate
