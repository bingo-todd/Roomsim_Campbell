RT_list = [0,0.1,0.3,0.5,0.7]
for RT_i = 1:5
    RT = RT_list(RT_i);
    set_file_path=sprintf('Text_setups_front_hemifield/setup_MIT_RT60_%.1f.txt',RT);
    BRIR_folder=sprintf('BRIR_front_hemifield/RT60_%.1f',RT);
    mkdir(BRIR_folder)
    roomsim_st(set_file_path,BRIR_folder);
end