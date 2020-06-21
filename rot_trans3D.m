function [xyz]=rot_trans3D(sense,xyz,psi_rad,theta_rad,phi_rad);
%Usage: [xyz]=rot_trans3D(sense,xyz,psi_rad,theta_rad,phi_rad); %  Rotational axes transformation
%Apply a rotation in yaw, pitch & roll to a 3D position vector xyz=[x;y;z]
%sense=0 converts position vectors specified in "earth fixed" axes to "rotating body" axes.
%sense=1 converts position vectors specified in "rotating body" axes to "earth fixed" axes.
% In terms of the rotating body axes (+ve z up, +ve x forward, +ve y to left) i.e. MATLAB convention
% +ve psi_rad is the yaw angle in the xy plane anti-clockwise from the positive x axis (slew left).
% +ve theta_rad is the pitch angle from the xy plane (nose up).
% +ve phi_rad is roll clockwise about the +ve x axis (right wing dips).
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

sense=logical(sense);

% Compute cos and sin here for efficiency
c_psi=cos(psi_rad); 
s_psi=sin(psi_rad);
c_theta=cos(theta_rad);
s_theta=sin(theta_rad);
c_phi=cos(phi_rad);
s_phi=sin(phi_rad);

%Room axis to sensor body axis transformation matrix tm.
tm=[c_theta.*c_psi                      c_theta.*s_psi                      -s_theta...
   ;s_phi.*s_theta.*c_psi-c_phi.*s_psi  s_phi.*s_theta.*s_psi+c_phi.*c_psi  s_phi.*c_theta...
   ;c_phi.*s_theta.*c_psi+s_phi.*s_psi  c_phi.*s_theta.*s_psi-s_phi.*c_psi  c_phi.*c_theta];

if sense,
    xyz=tm'*xyz; % Sense=1, Rotate body to inertial
else,
    xyz=tm*xyz; % Sense=0, Rotate inertial to body
end;
%----------- End of rot_trans3D.m ------------------------
