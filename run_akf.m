clear 
close all

%% Dataset
% you can download example datasets: 
% public dataset: city_09d_150_200, boxes_6dof_500_800, night_drive, interlaken_01a_1_150.
% our HDR dataset: carpark1, carpark2, tree1, tree2, tree3, city.
% or you can process and use your own dataset
DataName = 'city_09d_150_200';  

%% There are a few parameters that can be specified by users:
% deblur_option: true for deblur and false for no deblur
deblur_option = true;
% framerate: the frame rate of the output image sequence in Hz
framerate = 300;
% use_median_filter: true for apply a 3-by-3 median filter to the output
% images, false for not apply
use_median_filter = false;
% output_high_frame_rate_flag: 
% true: output images of the pre-defined framerate, 
% false: output images of the frame intensity framerate
output_high_frame_rate_flag = true; 
% sigma_p: the process noise parameter
sigma_p = 0.005; 
% sigma_i: the isolated noise parameter
sigma_i = 0.03;
% sigma_r: the refractory noise parameter
sigma_r = 0.05;
% refractory_period: the refractory period in microsecond. It models the 
% circuit limitations in each pixel of an event camera limit the response 
% time of events
refractory_period = 1*10^4;
% min_ct_scale: the minimal value for the contrast threshold scaling factor
min_ct_scale = 0.6; 
% max_ct_scale: the maximum value for the contrast threshold scaling factor
max_ct_scale = 100; 
% p_ini: the initial value for state covariance P
p_ini = 0.09;

%% run akf reconstruction
akf_reconstruction(DataName, deblur_option, ... 
    framerate, use_median_filter, output_high_frame_rate_flag,...
    sigma_p, sigma_i, sigma_r,refractory_period, min_ct_scale, max_ct_scale,...
    p_ini)


