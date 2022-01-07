function output_img(log_intensity_now_,img_idx_now,use_median_filter,safety_offset,post_process,height,width,folder,P,log_intensity_state_)
    td_img = exp(log_intensity_state_) - safety_offset;        
    if use_median_filter
        td_img = medfilt2(td_img,[3,3]);
    end

    for ii = 1:height
        for jj = 1:width
            if (P(ii,jj)) > 100 || isnan(P(ii,jj))
               P(ii,jj) = 0.25;
               td_img(ii,jj) = exp(log_intensity_now_(ii,jj))-1;
            elseif (P(ii,jj)) < 0 
                P(ii,jj) = 0;
            end
        end
    end
    td_img(td_img>3) = NaN;
    td_img(td_img<-3) = NaN; 
    td_img(isnan(td_img)) = exp(log_intensity_now_(isnan(td_img))) - 1;

    %% post process
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
    
    %% write images
    imwrite(td_img, sprintf([folder '/image_' num2str(img_idx_now) '.png']));
end