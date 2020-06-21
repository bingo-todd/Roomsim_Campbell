
for RT = 27:5:62
    set_file_path=sprintf('Text_setups_RT_JND/RT60_%d.txt',RT);
    BRIR_folder=sprintf('BRIR_RT60_JND/RT60_%d',RT);
    roomsim_st(set_file_path,BRIR_folder);
end

for RT = 27:5:62
    set_file_path=sprintf('Text_setups_RT_JND_rotate_90/RT60_%d.txt',RT);
    BRIR_folder=sprintf('BRIR_RT60_JND_rotate_90/RT60_%d',RT);
    roomsim_st(set_file_path,BRIR_folder);
end

for RT = 27:5:62
    set_file_path=sprintf('Text_setups_RT_JND_square/RT60_%d.txt',RT);
    BRIR_folder=sprintf('BRIR_RT60_JND_square/RT60_%d',RT);
    roomsim_st(set_file_path,BRIR_folder);
end

for RT=148:8:212
    set_file_path=sprintf('Text_setups_RT_JND_square_RT_1.8/RT60_%d.txt',RT);
    BRIR_folder = sprintf('BRIR_RT60_JND_square_RT_1.8/RT60_%d',RT);
    mkdir(BRIR_folder);
    roomsim_st(set_file_path,BRIR_folder);
end