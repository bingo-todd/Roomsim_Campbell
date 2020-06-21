RT_list = zeros(0,1);
% % roomount = 1;

room_size=[5,4,2.75];
F_abs = [125,250,500,1000,2000,4000];

scale_list = 0.1:0.0001:10;
scale_num = length(scale_list);

for scale_i = 1:scale_num
    A_wall = [0.03 0.15 0.50 0.80 0.85 0.80
              0.03 0.15 0.50 0.80 0.85 0.80
              0.03 0.15 0.50 0.80 0.85 0.08
              0.03 0.15 0.50 0.80 0.85 0.80];

    A_floor = [0.15 0.11 0.10 0.07 0.06 0.07];

    A_roof =  [0.01 0.01 0.01 0.02 0.02 0.02];

    A_all = [A_wall*scale_list(scale_i); A_floor; A_roof]';

    humidity = 50;
    m_air = 5.5E-4*(50/humidity)*(F_abs/1000).^(1.7);
    c= 343;

    RT60_estimator = 'Norris_Eyring';
    [RT60_Air MFP_Air]= reverberation_time(c,room_size,A_all,F_abs,m_air,RT60_estimator);
    RT_list(end+1) = RT60_Air(4);
end

plot(scale_list,RT_list,'linewidth',2);
hold on;
plot([1,1],[0,2],'r');
xlabel('scale'); ylabel('RT(1 kHz)');
saveas(gcf,'RT_curve','bmp');
% close

tar_RT = 1.48:0.08:2.12;
tar_RT = [0.2,0.45,0.7];
tar_RT_len = length(tar_RT);
tar_A = zeros(tar_RT_len,1);
for tar_RT_i = 1:tar_RT_len
    [~,index] = min((tar_RT(tar_RT_i)-RT_list).^2);
    tar_A(tar_RT_i) = scale_list(index);
end
%stem(tar_RT,tar_A);
disp(tar_A');