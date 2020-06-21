function [H_length, order]=check_length_order(Fs, c, H_length, order, RT60, delay_s, room_size, n_sources);
% Usage: [H_length, order]=check_length_order(Fs, c, H_length, order, RT60, delay_s, room_size, n_sources);
% Estimates order and/or impulse response length and attempts to ensure sufficient underestimation of memory available,
% so that user will get early warning of possible OUT OF MEMORY condition.
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

% Basis for required memory size calculation.
% Biggest arrays in roomsim_core.m are:
% p_isource = zeros(n_isources,n_sources,2)
% isource_xyz= zeros(3,n_isources)
% dist = zeros(1,n_isources)
% refl = zeros(6,n_isources)
% TOTAL= n_isources*(10+(2*n_sources))


%*** Global Declarations ***
global MAXSIZE; % largest number of elements allowed in an array on this machine, loaded in roomsim.m .
%***************************

prefix='check_length_order: ';

T=1/Fs;
Fs_c = Fs/c; % Samples per metre

Lx=room_size(1);
Ly=room_size(2);
Lz=room_size(3);
gmean_room_size=(prod(room_size))^(1/3); % geometric mean of room dimensions (more conservative than mean and max).

FOS=80; % Factor of Safety.
max_n_isources = fix(MAXSIZE./(FOS.*(10+2.*n_sources))); % Max value of n_isources allowed
max_order = fix(0.5.*((max_n_isources/8).^(1/3) -1)); % Max allowable value of order to keep memory required < MAXSIZE
max_H_length = ceil((2.*max_order+1).*gmean_room_size.*Fs_c); % Max allowable impulse response length in samples

if order < 0, % then impulse response length (H_length) is used to limit order of reflections computed.
    if H_length < 0, % Estimate a reasonable maximum impulse response length
        H_length = fix(max(RT60)*Fs); % H_length = longest reverberation time in samples (rounded down to integer)
    end;
    % Detect possible OUT OF MEMORY due to long impulse response
    if H_length > max_H_length, % Reduce impulse response length to avoid possible out of memory error
        msg_title=[prefix 'Out of Memory possible'];
        message=['Reducing impulse response length of ' num2str(H_length/Fs) ' to ' num2str(max_H_length/Fs) ' secs'];
        h=warndlg(message,msg_title);  %Warn & beep.
        beep;
        uiwait(h);% Wait for user to acknowledge
        H_length = max_H_length;
    end;
    % Estimate order based on calculated or user provided impulse response length (As Allen & Berkley)
    range=c.*T.*H_length; % H_length in metres
    % Number of image rooms within H_length
    order_x = ceil(range./(2.*Lx)); %  Number in +x direction
    order_y = ceil(range./(2.*Ly)); %  Number in +y direction
    order_z = ceil(range./(2.*Lz)); %  Number in +z direction
    
else % order >=0, the user has chosen an order value.
    % Detect possible OUT OF MEMORY due to high order
    if order > max_order, % Need to reduce order to avoid possible out of memory error
        msg_title=[prefix 'Out of Memory possible'];
        message=['Reducing order of reflections from ' num2str(max(order)) ' to ' num2str(max_order)];
        h=warndlg(message,msg_title);  %Warn & beep.
        beep;
        uiwait(h);% Wait for user to acknowledge
        order=max_order; % Update order for following check on H_length
    end;
    
    if H_length < 0, % Estimate a maximum impulse response length based on user chosen order value
        H_length = ceil((2.*order+1).*gmean_room_size.*Fs_c); % impulse response length in samples
    elseif H_length > max_H_length, % Need to reduce impulse response length to avoid possible out of memory error
        msg_title=[prefix 'Max array size limitation'];
        message=['Out of Memory possibility. Reducing impulse response length of ' num2str(H_length/Fs) ' to ' num2str(max_H_length/Fs) ' secs'];
        h=warndlg(message,msg_title);  %Warn & beep.
        beep;
        uiwait(h);% Wait for user to acknowledge
        H_length = max_H_length; % limit impulse response length in samples
    end;
    order_x=order;% Update order direction values
    order_y=order;
    order_z=order;
end;

% If the user has supplied non-contentious order and impulse response length values, these have been passed through to here.
order=[order_x; order_y; order_z]; % Pack up order into column vector

%------- End of check_length_order.m (H_length and Order calculation and checks) -----------
