function [answer,Fs,humidity,temperature,order,H_length,H_filename,air_F,dist_F,Fc_HP,plot_F2,plot_F3,alpha_F]=man_inp_params;
% Usage: [answer,Fs,humidity,temperature,order,H_length,H_filename,air_F,dist_F,Fc_HP,plot_F2,plot_F3,alpha_F]=man_inp_params;
% Prompted manual input of the basic parameters of the simulation
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

% Declare and clear simulation parameters
Fs =[]; humidity =[]; temperature =[]; order =[]; H_length =[]; H_filename =[];
air_F =[]; dist_F =[]; Fc_HP =[];plot_F2 =[]; plot_F3 =[];alpha_F =[];

banner = 'roomsim_setup: Enter Simulation control parameters 1';
prompt = {'Sampling frequency Fs > 8000 (Hz) :'...
        ,'Humidity of air 20<= h <= 70 (%):'...
        ,'Temperature of air (Celcius):'...
        ,'Limit to Order of reflections (-1 Program decides):'...
        ,'Limit to Impulse response length (samples) (-1 Program decides):'...
        ,'Filename for Impulse response:'...
    };
lines=1;
def = {'44100','50','20','-1','-1','ROOM_IMPULSE'}; %Default values
beep;
answer={};
answer = inputdlg(prompt,banner,lines,def,'on');
if ~isempty(answer),% Trap CANCEL button operation
    Fs=str2num(answer{1});
    humidity=str2num(answer{2});
    temperature=str2num(answer{3});
    order=str2num(answer{4});
    H_length=str2num(answer{5});
    H_filename=answer{6};

    % Set up second input dialogue box    
    answer={}; % Clear the answer flag
    banner = 'roomsim_setup: Enter Simulation control parameters 2';
    prompt = {'Air flag, 1 = Air absorption present (0 = not present):'...
            ,'Distance flag, 1 = Distance Attenuation present (0 = not present):'...
            ,'High-Pass filter cut-off (Hz), scalar value eg 50~100 (0 = filter not present):'...
            ,'2D Plotting flag, 1 = Display 2D Plot (0 = No Plot):'...
            ,'3D Plotting flag, 1 = Display 3D Plot (0 = No Plot):'...
            ,'Transparency flag, 1 = not opaque (0 = reflectivity sets opacity):'...
        };
    lines=1;
    def = {'1','1','0','0','0','0'}; %Default values
    beep;
    answer={};
    answer = inputdlg(prompt,banner,lines,def,'on');
    if ~isempty(answer),% Trap CANCEL button operation
        air_F=logical(str2num(answer{1}));
        dist_F=logical(str2num(answer{2}));
        Fc_HP = str2num(answer{3});
        plot_F2=logical(str2num(answer{4}));
        plot_F3=logical(str2num(answer{5}));
        alpha_F=logical(str2num(answer{6}));
    end;
end;

%------------- End of man_inp_params.m -------------------------
