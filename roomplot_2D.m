function roomplot_2D(c,Fs,room_size,source_xyz,receiver_xyz,receiver,sensor_xyz,H_length,source,p_isource);
%Usage: roomplot_2D(c,Fs,room_size,source_xyz,receiver_xyz,receiver,sensor_xyz,H_length,source,p_isource);
% Display a 2D plot of Room, Image Sources and Image Room Boundaries at height slice_z.
%--------------------------------------------------------------------------------------------- 
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
%--------------------------------------------------------------------------------------------------
%Functions called: 

%*** Global Declarations ***
global FIG_LOC; % Location for plots. Loaded in roomsim_run.m
global H_filename; % Identifier for current impulse response file. Declared in roomsim_run.

%--------------------------- Initialisation ----------------------------
invis_h=[]; imagesM_h=[]; imagesL_h=[]; imagesR_h=[]; % Declare arrays as empty to avoid error if no such to be plotted
[L_colormap, R_colormap, LR_colormap]=isource_colormaps; % Get the user defined colormaps L, R & LR.
n_sources=size(p_isource,2); %Number of primary sources
n_images=size(p_isource,1); % Number of image sources
T=1/Fs;

% Unpack room dimensions
Lx=room_size(1); % Length
Ly=room_size(2); % Width
Lz=room_size(3); % Height

%Unpack source(s) coordinates
x=source_xyz(1,:);
y=source_xyz(2,:);
z=source_xyz(3,:);

%Unpack receiver reference coordinates (Head or sensor(s))
xp=receiver_xyz(1);
yp=receiver_xyz(2);
zp=receiver_xyz(3);
%-------------------------------------------------------------------------

%Dialogue for setting 2D plot slice height
answer={};
banner = 'Roomplot_2D:';
prompt = {'Enter height for Slice (Default is source1 height z (m) :'};
lines = 1;
def = {num2str(z(1))}; %Default value
beep;
answer = inputdlg(prompt,banner,lines,def,'on');
if isempty(answer),
    h=warndlg('2D plot cancelled',banner);
    beep;
    pause(1);
    try,
        close(h); % Destroy the advisory notice if user has not cancelled
    catch,
    end;
    return; % Close dialogue box button operation, no plot produced.
end;

slice_z=str2num(answer{1});% Height value in slice_z.

%Display the visualisation menu
menu_title=[banner 'Choose a visualisation'];
B1_text='Intensity shown by stem height (Pseudo 3D)';
B2_text='Intensity shown by marker colour (2D Plan)';
beep;
M_VIScase = menu(menu_title,B1_text,B2_text);
switch M_VIScase
    case 0
        h=warndlg('2D plot cancelled',banner);
        beep;
        pause(1);
        try,
            close(h); % Destroy the advisory notice if user has not cancelled
        catch,
        end;
        return; % Close dialogue box button operation, no plot produced.
        
    case 1
        stem_F=true; % Display a Pseudo 3D stem plot
        
    case 2
        stem_F=false; % Display a 2D colour coded plan view
end;

disp_images=fix((n_images.^(1/3)).^2); % Estimate number of images in a slice plane
if disp_images >500,
    query_msg = ['Show "inaudible" image sources?  NB Displaying ' num2str(disp_images) ' images will take some time.'];% Advise the user
else,
    query_msg = ['Show "inaudible" image sources?'];% 
end;
banner='Roomplot_2D: ';
beep;
button = questdlg(query_msg,banner,'Yes','No','No');
switch button
    case []
        h=warndlg('2D plot cancelled',banner);
        beep;
        pause(1);
        try,
            close(h); % Destroy the advisory notice if user has not cancelled
        catch,
        end;
        return; % Close dialogue box button operation, no plot produced.
        
    case 'Yes'
        vis_F=true; % Show invisibles/inaudibles
        
    case 'No'
        vis_F=false; % Hide invisibles/inaudibles
end;

%----------------------- 2D Plot of the room and the image rooms---------------
curr_fig=get(0,'CurrentFigure'); %Get handle of current figure
if isempty(curr_fig),
    figh=figure(1); %Start first figure
else,
    figh=figure();%(curr_fig+1); %Start new figure
end;
set(figh,'Name',H_filename,'position',FIG_LOC); % Identify the figure and place it at FIG_LOC

clf; % Make sure it's a clean sheet
back_col=[0.7 0.7 0.7]; % Background colour light grey
whitebg(back_col); % Set figure background colour
hold on

%Plot the location of the image sources
x_size=[]; y_size=[]; % Clear accumulators for 2Dplot sizing

% Display a 2D intensity or 3D stem plot
switch receiver % ---------- Identify and position the receiver system---------------------
    case {'one_mic'}
        if ~stem_F, % Plot a 2D plan view
            sensorM_h=plot(sensor_xyz(1),sensor_xyz(2),'o','MarkerEdgeColor','m','MarkerFaceColor','none'); % Position of mono sensor       
        else, % Plot a 3D view on the -60dB reference plane
            sensorM_h=plot3(sensor_xyz(1),sensor_xyz(2),-60,'o','MarkerEdgeColor','m','MarkerFaceColor','none'); % Position of mono sensor       
        end;
        cm_LR = LR_colormap; % Get the 60 colormap RGB values
        for ps=1:n_sources, % For each parent source
            for is=1:n_images, % For each image source
                if (source(3,is,ps) > slice_z-0.01) & (source(3,is,ps) < slice_z+0.01), % Display a slice at the chosen height +/- 0.01m
                    temp_x=[]; temp_y=[];
                    if p_isource(is,ps,1) > 0, % Plot only "visible" sources (with delays <H_length or impulse response peaks >-60dB)
                        h_max_dB60=round(60+20*log10(p_isource(is,ps,1))); % Index of h_max from bottom (1) to top (60) of the colormap
                        if h_max_dB60 <1, % Enforce 1 to 60 range
                            h_max_dB60=1;
                        elseif h_max_dB60 >60,
                            h_max_dB60=60;
                        end;
                        mark_colour= cm_LR(h_max_dB60,:); % (green cross)
                        if ~stem_F, % Plot a 2D plan view
                            imagesM_h=plot(source(1,is,ps),source(2,is,ps),'+','MarkerEdgeColor',mark_colour,'MarkerFaceColor','none'); %Plot the visible image source(xy,ImageNo,Source)
                        else, % Plot a 3D view from the -60dB reference plane
                            imagesM_h=line([source(1,is,ps) source(1,is,ps)],[source(2,is,ps) source(2,is,ps)],[-60 h_max_dB60-60],'Marker','+','MarkerEdgeColor',mark_colour,'Color',mark_colour);
                        end;
                    elseif vis_F, % Plot "invisible" image sources as points in black
                        if ~stem_F, % Plot a 2D plan view
                            invis_h=plot(source(1,is,ps),source(2,is,ps),'k.'); %Plot positions source(xyz,ImageNo,ParentSource)
                        else, % Plot a 3D view on the -60dB reference plane
                            invis_h=plot3(source(1,is,ps),source(2,is,ps),-60,'k.'); %Plot positions source(xyz,ImageNo,ParentSource)                      
                        end;
                    end;
                    temp_x= source(1,is,ps); temp_y= source(2,is,ps);
                    x_size=[x_size temp_x]; y_size=[y_size temp_y]; % Accumulate size for plotting
                end; % of Slice select
            end; % For each image source
        end; % For each parent source
        
    case {'two_mic','mithrir','cipicir'} %
        if ~stem_F, % Plot a 2D plan view
            plot(sensor_xyz(1,:),sensor_xyz(2,:),'k'); %Draw line between L & R sensors
            plot(receiver_xyz(1),receiver_xyz(2),'dk'); % Mark the receiver reference point
            if sensor_xyz(3,2)>sensor_xyz(3,1), % Allow overlap of higher sensor on lower for plan view
                sensorL_h=plot(sensor_xyz(1,1),sensor_xyz(2,1),'o','MarkerEdgeColor','b','MarkerFaceColor','none'); % Position of L sensor     
                sensorR_h=plot(sensor_xyz(1,2),sensor_xyz(2,2),'o','MarkerEdgeColor','r','MarkerFaceColor','none'); % Position of R sensor
            else,
                sensorR_h=plot(sensor_xyz(1,2),sensor_xyz(2,2),'o','MarkerEdgeColor','r','MarkerFaceColor','none'); % Position of R sensor
                sensorL_h=plot(sensor_xyz(1,1),sensor_xyz(2,1),'o','MarkerEdgeColor','b','MarkerFaceColor','none'); % Position of L sensor     
            end;    
        else, % Plot a 3D view on the -60dB reference plane
            plot3(sensor_xyz(1,:),sensor_xyz(2,:),-60.*ones(1,size(sensor_xyz,2)),'k'); %Draw line between L & R sensors
            plot3(receiver_xyz(1),receiver_xyz(2),-60,'dk'); % Mark the receiver reference point
            sensorL_h=plot3(sensor_xyz(1,1),sensor_xyz(2,1),-60,'o','MarkerEdgeColor','b','MarkerFaceColor','none'); % Position of L sensor     
            sensorR_h=plot3(sensor_xyz(1,2),sensor_xyz(2,2),-60,'o','MarkerEdgeColor','r','MarkerFaceColor','none'); % Position of R sensor       
        end;
        cm_L = L_colormap; % Get the 60 colormap RGB values for left sensor only
        cm_R = R_colormap; % Get the 60 colormap RGB values for right sensor only
        for ps=1:n_sources, % For each parent source
            for is=1:n_images, % For each image source (with delays <H_length or impulse response peaks >-60dB)
                if (source(3,is,ps) > slice_z-0.01) & (source(3,is,ps) < slice_z+0.01), % Display a slice at the chosen height
                    temp_x=[]; temp_y=[]; %Clear plot size accumulators
                    if p_isource(is,ps,1)>0, % Plot sources "visible" to L sensor
                        h_max_dB60=round(60+20*log10(p_isource(is,ps,1))); %Index from bottom (1) to top (60) of the colormap
                        if h_max_dB60 <1, % Enforce 1 to 60 range
                            h_max_dB60=1;
                        elseif h_max_dB60 >60,
                            h_max_dB60=60;
                        end;
                        mark_colour= cm_L(h_max_dB60,:);
                        if ~stem_F, %Plot a plan view of the visible image source positions (blue cross) (xy,ImageNo,Source)
                            imagesL_h=plot(source(1,is,ps),source(2,is,ps),'+','MarkerEdgeColor',mark_colour,'MarkerFaceColor','none'); %Plot the visible image source positions (+) (xy,ImageNo,Source)
                        else, % Plot a 3D view from the -60dB reference plane
                            imagesL_h=line([source(1,is,ps) source(1,is,ps)],[source(2,is,ps) source(2,is,ps)],[-60 h_max_dB60-60],'Marker','+','MarkerEdgeColor',mark_colour,'MarkerFaceColor','none','Color',mark_colour);                           
                        end;                           
                    end;
                    if p_isource(is,ps,2)>0, % Plot sources "visible" to R sensor
                        h_max_dB60=round(60+20*log10(p_isource(is,ps,2))); %Index from bottom (1) to top (60) of the colormap
                        if h_max_dB60 <1, % Enforce 1 to 60 range
                            h_max_dB60=1;
                        elseif h_max_dB60 >60,
                            h_max_dB60=60;
                        end;
                        mark_colour= cm_R(h_max_dB60,:);
                        if ~stem_F, %Plot a plan view of the visible image source positions (red square) (xy,ImageNo,Source)
                            imagesR_h=plot(source(1,is,ps),source(2,is,ps),'s','MarkerEdgeColor',mark_colour); %Plot the visible image source positions (+) (xy,ImageNo,Source)
                        else, % Plot a 3D view from the -60dB reference plane
                            imagesR_h=line([source(1,is,ps) source(1,is,ps)],[source(2,is,ps) source(2,is,ps)],[-60 h_max_dB60-60],'Marker','s','MarkerEdgeColor',mark_colour,'MarkerFaceColor','none','Color',mark_colour);                           
                        end;                           
                    end;
                    if vis_F && (p_isource(is,ps,1)== 0 && p_isource(is,ps,2) == 0), % Plot "invisible" image sources as points in black
                        if ~stem_F, % Plot a 2D plan view
                            invis_h=plot(source(1,is,ps),source(2,is,ps),'k.'); %Plot positions of source(xyz,ImageNo,ParentSource)
                        else, % Plot a 3D view on the -60dB reference plane
                            invis_h=plot3(source(1,is,ps),source(2,is,ps),-60,'k.'); %Plot positions of source(xyz,ImageNo,ParentSource)                      
                        end;
                    end
                    temp_x= source(1,is,ps); temp_y= source(2,is,ps);
                    x_size=[x_size temp_x]; y_size=[y_size temp_y]; % Accumulate size for plotting
                end; %Slice select
            end; % For each image source
        end; % For each parent source
        
    otherwise,
        disp('Unknown receiver set up at freq response plot');
        return;
end; % Switch receiver

%Scale the plot to show all image sources and the complete room.
xmin= min([x_size -Lx])-Lx; xmax= max([x_size Lx]+Lx);
ymin= min([y_size -Ly])-Ly; ymax= max([y_size Ly]+Ly);
% Convert max and min to integer number of room lengths
xr_min=floor(xmin/Lx);xr_max=ceil(xmax/Lx);
yr_min=floor(ymin/Ly);yr_max=ceil(ymax/Ly);

%-------------------- Draw the room, image rooms and reference plane ------------------------------
if ~stem_F, % Plot a 2D plan view
    outline_h=plot([0 Lx],[0 0],'r',[0 0],[0 Ly],'m',[0 Lx],[Ly Ly],'b',[Lx Lx],[0 Ly],'g'); % Outline the room
    source_h=plot(x,y,'o','MarkerEdgeColor','g','MarkerFaceColor','none'); %Position of source(s)
    % Plot the imaged rooms
    for xrooms=xr_min:xr_max,
        plot([xrooms xrooms]*Lx,[yr_min yr_max]*Ly,'k:');
    end;
    for yrooms=yr_min:yr_max,
        bounds_h=plot([xr_min xr_max]*Lx,[yrooms yrooms]*Ly,'k:');
    end;
    [rows cols]=size(p_isource);
    if rows*cols > n_sources, % If not anechoic room
        rad=c*T*H_length; % Calculate radius corresponding to the longest impulse response length in metres
        rectangle('Curvature',[1 1],'Position',[xp-rad,yp-rad,2*rad,2*rad],'EdgeColor','r','LineStyle',':'); %Plot circular limit of audible image sources
    end;
    axis([xr_min*Lx xr_max*Lx yr_min*Ly yr_max*Ly]); % Scale primary axes in metres
    title(['2D Plot of Room, Image Source(s) and Image Room Boundaries at slice height ' num2str(slice_z) ' m']);
    axis equal;
    xlabel('Length (x) m'); ylabel('Width (y) m');
else, % Plot a 3D view with stems from a reference plane at -60dB
    outline_h=plot3([0 Lx],[0 0],[-60 -60],'r',[0 0],[0 Ly],[-60 -60],'m',[0 Lx],[Ly Ly],[-60 -60],'b',[Lx Lx],[0 Ly],[-60 -60],'g'); % Outline the room
    source_h=plot3(x,y,-60*ones(size(x)),'o','MarkerEdgeColor','g','MarkerFaceColor','none'); %Position of source(s)
    % Plot the imaged rooms
    for xrooms=xr_min:xr_max,
        plot3([xrooms xrooms]*Lx,[yr_min yr_max]*Ly,[-60 -60],'k:');
    end;
    for yrooms=yr_min:yr_max,
        bounds_h=plot3([xr_min xr_max]*Lx,[yrooms yrooms]*Ly,[-60 -60],'k:');
    end;
    axis([xr_min*Lx xr_max*Lx yr_min*Ly yr_max*Ly -60 0]); % Scale primary axes in metres and height in dB
    title(['3D Stem plot of Room, Image Source(s) and Image Room Boundaries at slice height ' num2str(slice_z) ' m']);
    zlabel('Intensity (z) dB');
    view(3); % Set view for 3D stem plot
    xlabel('Length (x) m'); ylabel('Width (y) m');
end;
%------------------------------------------------------------------

switch receiver % ---------- Identify the receiver system and display the legend ---------------------
    case {'one_mic'}
        if vis_F, %Show legend that features "invisible" image sources
            legend([outline_h; bounds_h; source_h; sensorM_h; imagesM_h; invis_h],{'Ay1';'Ax1';'Ay2';'Ax2'...
                    ;'Room Bounds';'Source(s)';'Receiver';'Images Mono';'"Inaudible"'},-1);
        else,
            legend([outline_h; bounds_h; source_h; sensorM_h; imagesM_h],{'Ay1';'Ax1';'Ay2';'Ax2'...
                    ;'Room Bounds';'Source(s)';'Receiver';'Images Mono'},-1);
        end;
    case {'two_mic','mithrir','cipicir'}
        if vis_F, %Show legend that features "invisible" image sources
            if isempty(imagesL_h) & ~isempty(imagesR_h), % Don't show LH
                legend([outline_h; bounds_h; source_h; sensorL_h; sensorR_h; imagesR_h; invis_h],{'Ay1';'Ax1';'Ay2';'Ax2'...
                        ;'Room Bounds';'Source(s)';'Receiver L';'Receiver R';'Image vis R';'"Inaudible"'},-1);
            elseif isempty(imagesR_h) & ~isempty(imagesL_h), % Don't show RH
                legend([outline_h; bounds_h; source_h; sensorL_h; sensorR_h; imagesL_h; invis_h],{'Ay1';'Ax1';'Ay2';'Ax2'...
                        ;'Room Bounds';'Source(s)';'Receiver L';'Receiver R';'Image vis L';'"Inaudible"'},-1);
            elseif isempty(imagesR_h) & isempty(imagesL_h), % Don't show RH or LH
                legend([outline_h; bounds_h; source_h; sensorL_h; sensorR_h; invis_h],{'Ay1';'Ax1';'Ay2';'Ax2'...
                        ;'Room Bounds';'Source(s)';'Receiver L';'Receiver R';'"Inaudible"'},-1);
            else, % Show all
                legend([outline_h; bounds_h; source_h; sensorL_h; sensorR_h; imagesL_h; imagesR_h; invis_h],{'Ay1';'Ax1';'Ay2';'Ax2'...
                        ;'Room Bounds';'Source(s)';'Receiver L';'Receiver R';'Image vis L';'Image vis R';'"Inaudible"'});
            end;
        else, % Don't show Inaudibles
            if isempty(imagesL_h) & ~isempty(imagesR_h), % Don't show LH
                legend([outline_h; bounds_h; source_h; sensorL_h; sensorR_h; imagesR_h],{'Ay1';'Ax1';'Ay2';'Ax2'...
                        ;'Room Bounds';'Source(s)';'Receiver L';'Receiver R';'Image vis R'},-1);
            elseif isempty(imagesR_h) & ~isempty(imagesL_h), % Don't show RH
                legend([outline_h; bounds_h; source_h; sensorL_h; sensorR_h; imagesL_h],{'Ay1';'Ax1';'Ay2';'Ax2'...
                        ;'Room Bounds';'Source(s)';'Receiver L';'Receiver R';'Image vis L'},-1);
            elseif isempty(imagesR_h) & isempty(imagesL_h), % Don't show RH or LH
                legend([outline_h; bounds_h; source_h; sensorL_h; sensorR_h],{'Ay1';'Ax1';'Ay2';'Ax2'...
                        ;'Room Bounds';'Source(s)';'Receiver L';'Receiver R'},-1);
            else, % Show all
                legend([outline_h; bounds_h; source_h; sensorL_h; sensorR_h; imagesL_h; imagesR_h],{'Ay1';'Ax1';'Ay2';'Ax2'...
                        ;'Room Bounds';'Source(s)';'Receiver L';'Receiver R';'Image vis L';'Image vis R'},-1);
            end; 
        end;
end;

hold off
%--------------------------- End of roomplot_2D.m -----------------------------------------------
