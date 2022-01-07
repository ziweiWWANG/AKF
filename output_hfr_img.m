function output_hfr_img(frame_idx,td_img,post_process,high_frame_rate_folder)
    % post process
    if post_process == 1
        tmp = sort(td_img(:)); 
        intensity_lower_bound = tmp(floor(numel(tmp)*0.03));
        intensity_upper_bound = tmp(ceil(numel(tmp)*0.97));  
        td_img = (td_img - intensity_lower_bound) / (intensity_upper_bound - intensity_lower_bound);
    elseif post_process == 2 % extremely bright view
        intensity_lower_bound = -0.001; 
        intensity_upper_bound = 1.2;
        td_img = (td_img - intensity_lower_bound) / (intensity_upper_bound - intensity_lower_bound);
    elseif post_process == 3 % extremely dark view
        intensity_lower_bound = -0.001;
        intensity_upper_bound = 0.4;
        td_img = (td_img - intensity_lower_bound) / (intensity_upper_bound - intensity_lower_bound);
    end 
    imwrite(td_img,[high_frame_rate_folder '/image_' num2str(frame_idx) '.png']);  
end