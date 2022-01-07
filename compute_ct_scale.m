function ct_scale = compute_ct_scale(width,height,ct,exposure,log_deblur_image,time_image,events,frame)
    i_idx = frame;
    t1 = time_image(i_idx) - exposure(i_idx)/2;
    t2 = time_image(i_idx+1) + exposure(i_idx+1)/2; 
    e_start_idx = find(events(:,1) >= t1,1,'first');
    e_end_idx = find(events(:,1) >= t2,1,'first');
    
    % only generate raw image
    x = events(:,2); 
    y = events(:,3); 
    p = events(:,4);
    sum_p = zeros(height,width);
    
    for i = e_start_idx:e_end_idx
        if p(i) < 1
            sum_p(y(i),x(i)) = sum_p(y(i),x(i)) - ct;
        else
            sum_p(y(i),x(i)) = sum_p(y(i),x(i)) + ct;
        end
    end 
    ct_scale = sum_p ./ (log_deblur_image(:,:,2) - log_deblur_image(:,:,1));     
end


