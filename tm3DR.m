function [tm]=tm3DR(psi_rad,theta_rad,phi_rad);
%Usage: [tm]=tm3DR(psi_rad,theta_rad,phi_rad); %  Rotational transformation matrix
%Used to transform the coordinates of a 3D position vector xyz=[x;y;z] from an inertial axes system
% into the coordinates as viewed from a "rotating body" axes system, rotated in yaw, pitch & roll.
% In terms of a rotating body axes (+ve z up, +ve x forward, +ve y to left) i.e. MATLAB convention
% +ve psi_rad is the yaw angle in the xy plane anti-clockwise from the positive x axis (slew left).
% +ve theta_rad is the pitch angle from the xy plane (nose down). NB -ve of MATLAB convention.
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

% Compute cos and sin
c_psi=cos(psi_rad); 
s_psi=sin(psi_rad);
c_theta=cos(theta_rad);
s_theta=sin(theta_rad);
c_phi=cos(phi_rad);
s_phi=sin(phi_rad);

%Inertial axes to body axis transformation matrix tm.
tm=[c_theta.*c_psi                      c_theta.*s_psi                      -s_theta...
   ;s_phi.*s_theta.*c_psi-c_phi.*s_psi  s_phi.*s_theta.*s_psi+c_phi.*c_psi  s_phi.*c_theta...
   ;c_phi.*s_theta.*c_psi+s_phi.*s_psi  c_phi.*s_theta.*s_psi-s_phi.*c_psi  c_phi.*c_theta];

%----------- End of tm3DR.m ------------------------
