function speed_estimator;
%Usage: speed_estimator;
% Provides a scale factor used to estimate the time in seconds to compute 
% n_images number of images, so that user can be advised roughly how long to wait.
%------------------------------------------------------------------ 
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
%-------------------------------------------------------------------------
% Functions called:

%*** Global Declarations ***
global SPEED_FACTOR; % To be used for estimating roomsim_core.m execution time
global CONV_FACTOR; % To be used for estimating convolution times for routines using conv.m (not in use)
global CONV_FACTOR_2; % To be used for estimating convolution times for roomsim_convolve.m, roomsim_cocktail.m

%----------------------------------------------------------------
% Running within MATLAB on a 1.5GHz P4 this code takes tim1 = 0.156 s
% Running within MATLAB on a 0.93GHz P4 this code takes tim1 = 0.24 s
%A processor clock speed can be estimated as proc_speed = 0.156*1.5/tim1 GHz
%A 1.5GHz P4 computes ~600 images/sec.
%Thus time for n_images on unknown machine is t_n_images = n_images*tim1/(0.156*600) = n_images*(tim1/94) secs
%A 0.93GHz P4 computes ~150 images/sec.
%Thus time for n_images on unknown machine is t_n_images = n_images*tim1/(0.24*150) = n_images*(tim1/37) secs
% Use intermediate estimate of tim1/50

tic;
dummy=0;
for counter = 1:250000,
    dummy = dummy+sqrt(sin(pi/2)); % A reasonable computing load ??
end;
tim1=toc;
SPEED_FACTOR= tim1./50;
%---------------------------------------------------------
% Compute a value for estimating convolution (filter) times for conv command.
% Running within MATLAB on a 1.5GHz P4 this code takes tim2 = 0.86 s
% Running within MATLAB on a 0.93GHz P4 this code takes tim2 = 1.8 s
% Running within MATLAB on a 0.45GHz P2 this code takes tim2 = 5 s
% Running within MATLAB on a 0.27GHz P? this code takes tim2 = 25 s
Lim_1=(1:0.1:1000);
Lim_2=(1:0.1:1000);
tic; 
y = conv(Lim_1,Lim_2);
tim2=toc;
CONV_FACTOR = length(Lim_1).*(length(Lim_2))./tim2; % Thus convolution time estimate is time_est=channels.*LENGTH_1.*LENGTH_2./CONV_FACTOR;
%---------------------------------------------------------
% Compute a value for estimating convolution (filter) times using fft implementation.
% Running within MATLAB on a 1.5GHz P4 this code takes tim3 = 0.07 s
% Running within MATLAB on a 0.93GHz P4 this code takes tim3 = 0.09 s

tic;
N=length(Lim_1)+length(Lim_2)-1;
FFT_length=2^nextpow2(N);
X = fft(Lim_1,FFT_length); % The fft function will zero pad the data with FFT_length-d_rows zeros prior to transforming
Y = fft(Lim_1,FFT_length);
temp = real(ifft(X.*Y));
tim3=toc;
CONV_FACTOR_2 = 3.*FFT_length.*log2(FFT_length)./tim3;
% Thus convolution by FFT time estimate is: time_est=channels.*FFT_length*log2(FFT_length)./CONV_FACTOR_2;
%--------- End of speed estimator --------------------