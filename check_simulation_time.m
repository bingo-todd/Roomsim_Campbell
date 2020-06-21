function [H_length, order]=check_simulation_time(Fs, c, H_length, order, room_size);
% Usage: [H_length, order]=check_simulation_time(Fs, c, H_length, order, room_size);
% Alert user to possible long simulation time due to large array sizes required
% and allow reduction of order or impulse response length
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


prefix='check_simulation_time: ';

Fs_c = Fs/c; % Samples per metre
gmean_room_size=(prod(room_size))^(1/3); % geometric mean of room dimensions (more conservative than mean and max).
max_order=max(order);

M_banner=[prefix 'Possible LONG SIMULATION TIME (Machine dependent)'];
Button1=['Reduce order from ' num2str(max_order)]; % 
Button2=['Reduce impulse response length from ' num2str(H_length/Fs) ' secs']; %
Button3='Keep current values'; %  
beep;
choice_reduce=menu(M_banner,Button1,Button2,Button3);
switch choice_reduce,
    case 0, % Cancel window keeps current values
        
    case 1,	% Reduce order.
        max_order=max(order);
        msg_title = [prefix 'Reduce order'];    
        prompt = {'Enter smaller value for max order, then OK'};
        lines = 1;
        def = {num2str(max_order)}; %Default value
        beep;
        answer = inputdlg(prompt,msg_title,lines,def,'on');
        if ~isempty(answer), % If Cancel or Close Window button operated accept current value of order
            beep;
            temp_order=str2num(answer{1});
            order = (order<=temp_order).*order+(order>temp_order).*temp_order; % Replace order xyz values that exceed new user supplied value.
            H_length = fix((2.*temp_order+1).*gmean_room_size.*Fs_c); % Length of impulse response supported by temp_order
        end;
        
    case 2, % Reduce impulse response length
        msg_title = [prefix 'Reduce impulse response length'];    
        prompt = {'Enter smaller value for impulse response (secs), then OK'};
        lines = 1;
        def = {num2str(H_length/Fs)}; %Default value
        answer = inputdlg(prompt,msg_title,lines,def,'on');
        if ~isempty(answer), % If Cancel or Close Window button operated accept current value of H_length and order
            beep;
            H_length=ceil(str2num(answer{1})*Fs); % Convert time to samples
            temp_order = fix((H_length./(gmean_room_size.*Fs_c)-1)/2); % temp_order required by length of impulse response  
            order = (order<=temp_order).*order+(order>temp_order).* temp_order; % Replace only those order xyz values that exceed new value.
        end;
        
    case 3, % Keep current values
        
end;%of menu choice_reduce

%------- End of check_simulation_time ---------------------