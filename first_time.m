function first_time
% This function checks for a previous acceptance of the licence conditions
% Its purpose is to avoid challenging the user more than once per calendar year.

%*** Global Declarations ***
global year_zero; % The most recent licence acceptance year
global SPEED_FACTOR; % To be used for estimating roomsim_core.m execution time
global CONV_FACTOR; % To be used for estimating convolution times for routines using conv.m (not in use)
global CONV_FACTOR_2; % To be used for estimating convolution times for roomsim_convolve.m, roomsim_cocktail.m

if exist([pwd '\roomsim_pp.mat'],'file')
    load roomsim_pp.mat; % get year of last acceptance of license and previous time estimator factors
    this_year = datestr(now,10); % get this year
    if ~strcmp(year_zero,this_year) % if license has not been accepted this year
        roomsim_welcome;% Display Welcome Screen
        year_zero=this_year; % License terms were accepted so update year_zero
        save roomsim_pp.mat year_zero SPEED_FACTOR CONV_FACTOR CONV_FACTOR_2; % and update passport file
    end;
    
else % roomsim_pp.mat does not exist so assume first time run  
    roomsim_welcome;% Display Welcome Screen
    year_zero = datestr(now,10); % get this year

    %--------- Characterise platform -----------------------
    msg_title='first_time';
    message='Estimating platform speed - please wait';
    h=msgbox(message,msg_title);
    SPEED_FACTOR=[];
    CONV_FACTOR=[];
    CONV_FACTOR_2=[];
    % Check the machine speed
    speed_estimator; % Estimate initial values for Globals SPEED_FACTOR and CONV_FACTORs related to machine speed
    
    save roomsim_pp.mat year_zero SPEED_FACTOR CONV_FACTOR CONV_FACTOR_2; % and create passport file
    try,
        close(h); % Destroy the advisory notice if user has not cancelled
    catch,
    end;
    
end;
