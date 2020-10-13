function schematic_head(receiver_xyz,receiver_off,head_width,skin)
% Usage: schematic_head(receiver_xyz,receiver_off,head_width,skin);
% Draw a schematic head with eyes, nose and ears.
% receiver_xyz(x,y,z) is the location in room axes.
% receiver_off(yaw, pitch, roll) is the rotational offset in radians.
% head_width is the ear separation for head (m), and skin is the colormap for sphere.
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
%Functions called: c_tetrahedron3.m, tm3DR.m

[tm]=tm3DR(receiver_off(1),-receiver_off(2),receiver_off(3));
tmT=tm'; % Do transpose here for efficiency

% Unpack the reference coordinates locating the head position
x=receiver_xyz(1);
y=receiver_xyz(2);
z=receiver_xyz(3);

%--------- Data for drawing head -----------------
scale_F=0.5*head_width; % Radius of schematic (spherical) skull
[XX YY ZZ]=sphere; % Data for sphere having 20*20 faces
x_skull=scale_F.*XX;
y_skull=scale_F.*YY;
z_skull=scale_F.*ZZ;
% Compute the rotated cordinates
for p=1:21,
    for q=1:21,
        [xyz]=tmT*[x_skull(p,q);y_skull(p,q);z_skull(p,q)];
        tx_skull(p,q)=xyz(1);
        ty_skull(p,q)=xyz(2);
        tz_skull(p,q)=xyz(3);
    end;
end;

hold on;
% Draw the skull
cm=colormap(skin); % Skin colour
cmin=min(min(z+z_skull));
cmax=max(max(z+z_skull));
caxis([cmin cmax]); % Scale the colormap
surf(x+tx_skull,y+ty_skull,z+tz_skull,'EdgeColor','none');

%---------- Data for drawing the nose --------------------
x_nose=0.9.*scale_F;
y_nose=0;
z_nose=0.1.*scale_F;
delta=0.15.*scale_F;

V1=[x_nose; y_nose-delta; z_nose-delta]; V2=[x_nose; y_nose; z_nose+delta];
V3=[x_nose; y_nose+delta; z_nose-delta]; V4=[x_nose+2.*delta; y_nose; z_nose-delta]; %tetrahedron vertices [x y z]
% Compute the rotated cordinates
[V1]=tmT*V1;
[V2]=tmT*V2;
[V3]=tmT*V3;
[V4]=tmT*V4;

% tetrahedron vertices [x y z]
V1=[x+V1(1) y+V1(2) z+V1(3)]; V2=[x+V2(1) y+V2(2) z+V2(3)];
V3=[x+V3(1) y+V3(2) z+V3(3)]; V4=[x+V4(1) y+V4(2) z+V4(3)];
vertex_list=[V1;V2;V3;V4];
faces=[V1 V2 V4; V2 V3 V4; V3 V1 V4];
vertex_connection=[1 2 4; 2 3 4; 3 1 4]; % Order of connection of vertices

% Draw the nose tetrahedron in 3D
alph=1; % Face transparency
C_Faces3=[1 0 0;0 0 1;0 0 0]; % Nose colours red (R), blue (L), black (base)
C_Edge='k'; % Edge colour of tetrahedral nose
patch('Faces',vertex_connection,'Vertices',vertex_list,'FaceVertexAlphaData',alph,'FaceAlpha','flat','FaceColor','flat','FaceVertexCdata',C_Faces3,'EdgeColor',C_Edge);  
%--------------------------------------------------

%---------- Data for drawing the ears ----------------------
x_ear=0.15.*x_skull;
y_ear_L=0.98.*scale_F+0.15*y_skull;
y_ear_R=-y_ear_L;
z_ear=0.15.*z_skull;
% Compute the rotated cordinates
for p=1:21,
    for q=1:21,
        [xyz]=tmT*[x_ear(p,q);y_ear_L(p,q);z_ear(p,q)];
        tx_ear(p,q)=xyz(1);
        ty_ear_L(p,q)=xyz(2);
        tz_ear(p,q)=xyz(3);
    end;
end;
% Draw the Left ear
surf(x+tx_ear, y+ty_ear_L, z+tz_ear,'EdgeColor','b');

% Compute the rotated cordinates
for p=1:21,
    for q=1:21,
        [xyz]=tmT*[x_ear(p,q);y_ear_R(p,q);z_ear(p,q)];
        tx_ear(p,q)=xyz(1);
        ty_ear_R(p,q)=xyz(2);
        tz_ear(p,q)=xyz(3);
    end;
end;
% Draw the Right ear
surf(x+tx_ear, y+ty_ear_R, z+tz_ear,'EdgeColor','r');
%--------------------------------------------------

% Draw the eyes (sclera and pupils)
x_sclera=0.7.*scale_F+0.15*x_skull;
y_sclera_L=0.5.*scale_F+0.15*y_skull;
y_sclera_R=-y_sclera_L;
z_sclera=0.2.*scale_F+0.15*z_skull;

% Compute the rotated cordinates
for p=1:21,
    for q=1:21,
        [xyz]=tmT*[x_sclera(p,q);y_sclera_L(p,q);z_sclera(p,q)];
        tx_sclera(p,q)=xyz(1);
        ty_sclera_L(p,q)=xyz(2);
        tz_sclera(p,q)=xyz(3);
    end;
end;
% Draw the Left sclera
surf(x+tx_sclera,y+ty_sclera_L,z+tz_sclera,'EdgeColor','w'); % Draw sclera

% Compute the rotated cordinates
for p=1:21,
    for q=1:21,
        [xyz]=tmT*[x_sclera(p,q);y_sclera_R(p,q);z_sclera(p,q)];
        tx_sclera(p,q)=xyz(1);
        ty_sclera_R(p,q)=xyz(2);
        tz_sclera(p,q)=xyz(3);
    end;
end;
% Draw the Right sclera
surf(x+tx_sclera,y+ty_sclera_R,z+tz_sclera,'EdgeColor','w');

x_pupil=0.8.*scale_F+0.05.*x_skull;
y_pupil_L=0.55.*scale_F+0.05.*y_skull;
y_pupil_R=-y_pupil_L;
z_pupil=0.2.*scale_F+0.05.*z_skull;

% Compute the rotated cordinates
for p=1:21,
    for q=1:21,
        [xyz]=tmT*[x_pupil(p,q);y_pupil_L(p,q);z_pupil(p,q)];
        tx_pupil(p,q)=xyz(1);
        ty_pupil_L(p,q)=xyz(2);
        tz_pupil(p,q)=xyz(3);
    end;
end;
% Draw the Left pupil
surf(x+tx_pupil,y+ty_pupil_L,z+tz_pupil,'EdgeColor','b'); % Draw pupil

% Compute the rotated cordinates
for p=1:21,
    for q=1:21,
        [xyz]=tmT*[x_pupil(p,q);y_pupil_R(p,q);z_pupil(p,q)];
        tx_pupil(p,q)=xyz(1);
        ty_pupil_R(p,q)=xyz(2);
        tz_pupil(p,q)=xyz(3);
    end;
end;
% Draw the Right pupil
surf(x+tx_pupil,y+ty_pupil_R,z+tz_pupil,'EdgeColor','r');

axis equal;
hold off;
%--------------------------------- End of schematic_head.m -------------------------------
