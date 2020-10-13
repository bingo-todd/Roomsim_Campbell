function c_tetrahedron3(x,y,z,delta,C_Faces,alph,C_Edge)
% Usage: c_tetrahedron3(x,y,z,delta,C_Faces,alph,C_Edge);
% Draws a 3D tetrahedron with coloured faces
%-------------------------------------------------------------
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
%---------------------------------------------------------------------
%Functions called: 

V1=[x y-delta z-delta]; V2=[x y z+delta]; V3=[x y+delta z-delta]; V4=[x+2*delta y z-delta]; %tetrahedron vertices [x y z]
vertex_list=[V1;V2;V3;V4];
faces=[V1 V2 V4; V2 V3 V4; V3 V1 V4];
vertex_connection=[1 2 4; 2 3 4; 3 1 4]; % Order of connection of vertices
%Draw the tetrahedron in 3D
patch('Faces',vertex_connection,'Vertices',vertex_list,'FaceVertexAlphaData',alph,'FaceAlpha','flat','FaceColor','flat','FaceVertexCdata',C_Faces,'EdgeColor',C_Edge);    
%---------------------------- End of c_tertrahedron.m ------------------------------------- 
