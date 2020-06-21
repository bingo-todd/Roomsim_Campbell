function [azim,elev]=convert_view(azim,elev);
if elev > 90,
    elev=180-elev; % Restrict to range 0 < elevation <= 90
    azim=180+azim;
    if azim < -180,
        azim=azim+360; % Restrict to range 0 < azimuth <= 180
    elseif azim > 180,
        azim=azim-360; % Restrict to range -180 < azimuth <= 0
    end;
elseif elev < -90,
    elev=-180-elev; % Restrict to range -90 < elevation <= 0
    azim=180+azim;
    if azim <- 180,
        azim=azim+360; % Restrict to range 0 < azimuth <= 180
    elseif azim>180,
        azim=azim-360; % Restrict to range -180 < azimuth <= 0
    end;
end;