function [output_deblur_t1,output_deblur_t2] = deblur_edge_outer(min_ct_scale,max_ct_scale,img_idx_now,time_image,exposure,events,image,c_deblur,safety_offset)
    %% outer edge deblur frame 1
    output_deblur_on_1 = deblur_mid(min_ct_scale,max_ct_scale,img_idx_now,time_image(img_idx_now),exposure,events,image,c_deblur,safety_offset);
    output_deblur_1_log = log(output_deblur_on_1+1); % add safety_offset 1
    t1 = time_image(img_idx_now) - exposure/2;
    t2 = time_image(img_idx_now);
    e_start_idx = find(events(:,1) >= t1,1,'first');
    e_end_idx = find(events(:,1) >= t2,1,'first');

    for i_e = e_start_idx:e_end_idx
        xe = events(i_e,2);           % [1 -> width]
        ye = events(i_e,3);           % [1 -> height]
        polarity_e = events(i_e,4);    % [-1, 1]
        if (polarity_e == 1)
            contrast_threshold_e = c_deblur;
        else
            contrast_threshold_e = -c_deblur;
        end
        output_deblur_1_log(ye,xe) = output_deblur_1_log(ye,xe) - contrast_threshold_e;
    end
    output_deblur_t1 = exp(output_deblur_1_log)-safety_offset;

    %% outer edge deblur frame 2
    output_deblur_on_2 = deblur_mid(min_ct_scale,max_ct_scale,img_idx_now+1,time_image(img_idx_now+1),exposure,events,image,c_deblur,safety_offset);
    output_deblur_2_log = log(output_deblur_on_2+1);
    t1 = time_image(img_idx_now+1);
    t2 = time_image(img_idx_now+1) + exposure/2;
    e_start_idx = find(events(:,1) >= t1,1,'first');
    e_end_idx = find(events(:,1) >= t2,1,'first');

    for i_e = e_start_idx:e_end_idx
        xe = events(i_e,2);           % [1 -> width]
        ye = events(i_e,3);           % [1 -> height]
        polarity_e = events(i_e,4);    % [-1, 1]
        if (polarity_e == 1)
            contrast_threshold_e = c_deblur;
        else
            contrast_threshold_e = -c_deblur;
        end
        output_deblur_2_log(ye,xe) = output_deblur_2_log(ye,xe) + contrast_threshold_e;
    end
    output_deblur_t2 = exp(output_deblur_2_log)-safety_offset;
end