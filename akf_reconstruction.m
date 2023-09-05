function akf_reconstruction(DataName, deblur_option, ...
    framerate, use_median_filter, output_high_frame_rate_flag,...
    sigma_p, sigma_i, sigma_r,refractory_period, min_ct_scale, max_ct_scale,...
    p_ini)
    
    %% the post_process method, exposure and 'f_Q' is included in the provided datasets.
    % if you are using your datasets, carefully define these parameters here.
    
    %% post_process method
    % 0: no normalization,
    % 1: (image-min/(max-min)),
    % 2: user-defined max and min value for extremely bright view
    % 3: user-defined max and min value for extremely dark view
    
    % for example:
    % post_process = 1; 
    
    %% f_Q, exposure time and contrast threshold
    % The 'f_Q' is the most important parameter for image noise. It 
    % represents the inverse of the R_bar function in equation (6) in the 
    % paper. You can simply treat it as the image confidence function of 
    % intensity. For example, for an image in range [0 255], the extreme 
    % values around 0 and 255 would have lower confidence. You can find the 
    % sample weight function from the provided dataset link.
    
    % The preset exposure time for each intensity image is included in the 
    % provided datasets (some datasets are recorded with auto-exposure, 
    % e.g., interlaken_01a_events_1_150.mat). If you want to use your own 
    % dataset, please set or estimate the exposure time as well.
    
    % for example:
    % load('../src/mat/weight_function.mat'); f_Q = max(weight_func,0.09) * 7e5;
    % exposure = zeros(10)+500; % define exposure time for 10 input images
    % ct = 0.1; % set contrast threshold
    
    
    %% set output folders 
    folder = sprintf(['./reconstruction/' DataName]);
    if ~exist(folder, 'dir')
    	mkdir(folder)
    end
    fileID_bw = fopen(sprintf(['./' folder '/timestamps.txt']),'w');
    if output_high_frame_rate_flag
        high_frame_rate_folder = sprintf([folder '_hfr']);
        if ~exist(high_frame_rate_folder, 'dir')
           mkdir(high_frame_rate_folder)
        end
    end
    
    %% load dataset
    image = []; events = [];    
    load_data_add = sprintf(['./data/' DataName '.mat']);
    load(load_data_add);
    %% initialization
    [ts_array_,ts_array_2,frame_idx,R_inv_array,C,weight]...
        = initialization(im_height, im_width);
    frame_time = floor(1/framerate * 1e6);
    frame_start = 2;
    frame_end =  length(time_image); 
    safety_offset = 1;
    P = zeros(im_height,im_width) + p_ini; 
    new_frame_f = 1;
    write_output_f = 0;
    img_idx_now = frame_start;
    img_idx_next = frame_start+1;  % intensity range [1 256]
    img_now_ts_1 = time_image(img_idx_now)-exposure(img_idx_now)/2;
    img_now_ts_mid = time_image(img_idx_now);
    img_now_ts_2 = time_image(img_idx_now)+exposure(img_idx_now)/2;
    img_next_ts_1 = time_image(img_idx_now+1)-exposure(img_idx_now)/2;   
    img1_round_in_0255 = double(image(:,:,img_idx_now))+1;  
    img2_round_in_0255 = double(image(:,:,img_idx_next))+1;
    img1_round_in_01 = img1_round_in_0255/255;
    img2_round_in_01 = img2_round_in_0255/255;
    log_intensity_now_ = log(double(image(:,:,frame_start))/255 + safety_offset);
    
    t1 = time_image(frame_start);
    e_start_idx = find(events(:,1) >= t1,1,'first');
    t2 = time_image(frame_end);
    if t2 >= events(end,1)
        e_end_idx = size(events,1); % last event
    else
        e_end_idx = find(events(:,1) >= t2,1,'first');
    end
    t_next_publish_ = time_image(frame_start)+exposure(img_idx_now)/2;
    output_deblur_t1 = double(image(:,:,frame_start))/255;
    output_deblur_t2 = double(image(:,:,frame_start+1))/255;
    log_deblur_image_now(:,:,1) = log(double(output_deblur_t1) + safety_offset);
    log_deblur_image_now(:,:,2) = log(double(output_deblur_t2) + safety_offset);
    log_intensity_state_ = log_deblur_image_now(:,:,1);
    ct_scale = compute_ct_scale(ct,exposure,log_deblur_image_now,time_image,events,img_idx_now);   
    % assume forwards and backbards interpolation are the same at the beginning
    log_output_interp_t1 = log_deblur_image_now(:,:,1);
    log_output_interp_t2 = log_output_interp_t1;   
    
    %% event Update 
    for i=e_start_idx:e_end_idx
        ts = events(i,1);          % microsecond
        x = events(i,2);           
        y = events(i,3);           
        polarity = events(i,4);    % [-1, 1]
        
        %% update raw image & deblur image & ct_scale
        if events(i,1) > time_image(frame_end) || img_idx_next >= (frame_end-1)
            break;
        %% need deblur => update reference image inside exposure time    
        elseif deblur_option && (ts > img_now_ts_1) && (ts <= img_now_ts_2)
            if new_frame_f
                output_deblur_1_log = deblur_edge_left(min_ct_scale,max_ct_scale,img_idx_now,time_image,exposure(img_idx_now),events,image,ct,safety_offset); 
                log_intensity_now_ = output_deblur_1_log;
                new_frame_f = 0;
            else
                if (polarity == 1)
                    contrast_threshold = ct;
                else
                    contrast_threshold = -ct;
                end
                log_intensity_now_(y,x) = log_intensity_now_(y,x) + contrast_threshold;
            end

            %% time to output image
            if (ts > img_now_ts_mid) && write_output_f  
                intensity_now_ = exp(log_intensity_now_) - safety_offset;
                intensity_now_(intensity_now_>1) = 1;
                intensity_now_(intensity_now_<0) = 0;
                log_intensity_now_ = log(intensity_now_ + safety_offset);   
                
                %% global update
                delta_t = (ts - ts_array_)/1e6;
                C = (log_intensity_state_ - log_intensity_now_) ./ P;
                log_intensity_state_ = (1 ./ (1 ./ P + R_inv_array .* delta_t)) .* C + log_intensity_now_;
                P = 1 ./ ((1 ./ P) + R_inv_array .* delta_t);
                P = P + sigma_p .* delta_t;
                ts_array_(:) = ts;
                
                % output images and timestamps
                output_img(log_intensity_now_,img_idx_now,use_median_filter,safety_offset,post_process,folder,P,log_intensity_state_)
                output_img_ts = time_image(img_idx_now) / 1e6;
                output_img_ts = sprintf('%0.9f',output_img_ts);
                outputIdxTs = sprintf(['image_' num2str(img_idx_now) '.png ' num2str(output_img_ts) '\n']);
                fprintf(fileID_bw,outputIdxTs);     
                write_output_f = 0;
            end
            
        %% no deblur + time to output 
        elseif (~deblur_option) && (ts > img_now_ts_1) && (ts <= img_now_ts_2) && write_output_f 
            log_intensity_now_ = log(double(image(:,:,img_idx_now))/255+safety_offset);

            %% global update
            delta_t = (ts - ts_array_)/1e6;
            if (min(delta_t)<0)
                fprintf('ERROR! Check code! \n')
            end
            C = (log_intensity_state_ - log_intensity_now_) ./ P;
            log_intensity_state_ = (1 ./ (1 ./ P + R_inv_array .* delta_t)) .* C + log_intensity_now_;
            P = 1 ./ ((1 ./ P) + R_inv_array .* delta_t);
            P = P + sigma_p .* delta_t;
            ts_array_(:) = ts;
            
            % output images and timestamps
            output_img(log_intensity_now_,img_idx_now,use_median_filter,safety_offset,post_process,folder,P,log_intensity_state_)
            output_img_ts = time_image(img_idx_now) / 1e6;
            output_img_ts = sprintf('%0.9f',output_img_ts);
            outputIdxTs = sprintf(['image_' num2str(img_idx_now) '.png ' num2str(output_img_ts) '\n']);
            fprintf(fileID_bw,outputIdxTs); 
            write_output_f = 0;

        %% time to update to next frame    
        elseif (ts > img_next_ts_1) && (img_idx_next < length(time_image))
            new_frame_f = 1;
            write_output_f = 1;
            img_idx_next = img_idx_next + 1;
            img_idx_now = img_idx_now + 1;
            img_now_ts_1 = time_image(img_idx_now) - exposure(img_idx_now)/2;
            img_now_ts_mid = time_image(img_idx_now);
            img_now_ts_2 = time_image(img_idx_now) + exposure(img_idx_now)/2;
            img_next_ts_1 = time_image(img_idx_now + 1) - exposure(img_idx_now)/2;
            img_next_ts_2 = time_image(img_idx_now + 1) + exposure(img_idx_now)/2;

            % deblur the first and the second image
            if deblur_option
                [output_deblur_t1,output_deblur_t2] = deblur_edge_outer(min_ct_scale,max_ct_scale,img_idx_now,time_image,exposure(img_idx_now),events,image,ct,safety_offset);        
            else
                output_deblur_t1 = double(image(:,:,img_idx_now))/255;
                output_deblur_t2 = double(image(:,:,img_idx_now+1))/255;
            end
            log_deblur_image_now(:,:,1) = log(double(output_deblur_t1) + safety_offset);
            log_deblur_image_now(:,:,2) = log(double(output_deblur_t2) + safety_offset);          
            
            % update ct_scale between the first and the second image
            ct_scale = compute_ct_scale(ct,exposure,log_deblur_image_now,time_image,events,img_idx_now);      

            % update parameters for interpolation forward -- current time: time_image(img_idx_now) 
            log_output_interp_t1 = log_deblur_image_now(:,:,1);

            % update parameters for interpolation backward -- current time: time_image(img_idx_now) 
            log_output_interp_t2 = log_deblur_image_now(:,:,2);
            t1 = img_now_ts_1;   
            t2 = img_next_ts_2;
            e_start_idx_interp = find(events(:,1) >= t1,1,'first');
            e_end_idx_interp = find(events(:,1) >= t2,1,'first');
            for id = e_start_idx_interp:e_end_idx_interp
                if events(id,4) < 1
                    if ct_scale(events(id,3),events(id,2)) >= min_ct_scale && ct_scale(events(id,3),events(id,2)) <= max_ct_scale
                        log_output_interp_t2(events(id,3),events(id,2)) = log_output_interp_t2(events(id,3),events(id,2)) + ct/ct_scale(events(id,3),events(id,2));
                    else
                        log_output_interp_t2(events(id,3),events(id,2)) = log_output_interp_t2(events(id,3),events(id,2)) + ct;
                    end
                else  
                    if ct_scale(events(id,3),events(id,2)) >= min_ct_scale && ct_scale(events(id,3),events(id,2)) <= max_ct_scale
                        log_output_interp_t2(events(id,3),events(id,2)) = log_output_interp_t2(events(id,3),events(id,2)) - ct/ct_scale(events(id,3),events(id,2));
                    else
                        log_output_interp_t2(events(id,3),events(id,2)) = log_output_interp_t2(events(id,3),events(id,2)) - ct;
                    end
                end
            end
            
            % image noise update
            img1_round_in_0255 = round(double(image(:,:,img_idx_now))) + 1;  % intensity range [1 256]  
            img1_round_in_01 = img1_round_in_0255 / 255;  % intensity range [0 1]
            R_img_idx = img_idx_next;
            img2_round_in_0255 = round(double(image(:,:,R_img_idx))) + 1;  % intensity range [1 256]
            R_bar_inv =  f_Q(img1_round_in_0255);
            R_inv_array = R_bar_inv .* (img1_round_in_01 + safety_offset).^2;   
        end

        %% local update           
        log_intensity_now = log_intensity_now_(y,x);
        delta_t = (ts - ts_array_(y,x))/1e6;
        if (polarity == 1)
            contrast_threshold = ct;
        else
            contrast_threshold = -ct;
        end
        C(y,x) = (log_intensity_state_(y,x) - log_intensity_now) ./ P(y,x);
        log_intensity_state_(y,x) = (1 ./ (1 ./ P(y,x) + R_inv_array(y,x) .* delta_t)) .* C(y,x) + log_intensity_now;
        log_intensity_state_(y,x) = log_intensity_state_(y,x) + contrast_threshold;   
        if x > 1 && x < im_width && y > 1 && y < im_height && ((ts - ts_array_2(y,x)) > refractory_period)
            ts_neig = ts_array_2(y-1:y+1,x-1:x+1);
            Q_i = sigma_i * min(ts - ts_neig(:))/1e6; % in second, depends on neighbour pixels
            Q_r = 0;
        elseif x > 1 && x < im_width && y > 1 && y < im_height && ((ts - ts_array_2(y,x)) <= refractory_period)
            ts_neig = ts_array_2(y-1:y+1,x-1:x+1);
            Q_i = sigma_i * min(ts - ts_neig(:))/1e6; % in second, depends on neighbour pixels
            Q_r = sigma_r * min(ts - ts_array_2(y,x))/1e6;
        else 
            Q_i = 10; % border trust interpolation
            Q_r = 10;
        end
        P(y,x) = 1 ./ ((1 ./ P(y,x)) + R_inv_array(y,x) .* delta_t);
        P(y,x) = P(y,x) + sigma_p .* delta_t;
        P(y,x) = P(y,x) + Q_i + Q_r;
        ts_array_(y,x) = ts;
        ts_array_2(y,x) = ts;
        
        %% continuous-time interpolation
        if polarity < 1
            if ct_scale(y,x) >= min_ct_scale && ct_scale(y,x) <= max_ct_scale
                log_output_interp_t1(y,x) = log_output_interp_t1(y,x) + (-ct/ct_scale(y,x));
                log_output_interp_t2(y,x) = log_output_interp_t2(y,x) + (-ct/ct_scale(y,x));
            else
                log_output_interp_t1(y,x) = log_output_interp_t1(y,x) + (-ct);
                log_output_interp_t2(y,x) = log_output_interp_t2(y,x) + (-ct);
            end
        else
            if ct_scale(y,x) >= min_ct_scale && ct_scale(y,x) <= max_ct_scale
                log_output_interp_t1(y,x) = log_output_interp_t1(y,x) + (ct/ct_scale(y,x));
                log_output_interp_t2(y,x) = log_output_interp_t2(y,x) + (ct/ct_scale(y,x));
            else
                log_output_interp_t1(y,x) = log_output_interp_t1(y,x) + ct;
                log_output_interp_t2(y,x) = log_output_interp_t2(y,x) + ct;
            end
        end
        output_interp_t1 = exp(log_output_interp_t1(y,x)) - safety_offset;
        output_interp_t2 = exp(log_output_interp_t2(y,x)) - safety_offset; 

        %% interpolation update         
        if (ts >= img_now_ts_2) && (ts <= img_next_ts_1)
            weight = (ts - img_now_ts_2) / (img_next_ts_1 - img_now_ts_2);
            output_interp_mid = output_interp_t1 * (1 - weight) + output_interp_t2 * (weight);
        elseif (ts >= img_now_ts_1) && (ts < img_now_ts_2)
            % inside of the exposure time of the first image
            % no interpolation, use forward integration
            % ts cannot go beyond img_next_ts_1
            weight = 0;  
            output_interp_mid = output_interp_t1;
        end
        log_intensity_now_(y,x) = log(output_interp_mid+safety_offset); 
                  
        %% high frame rate reconstruction - update globally with a certain framerate     
         if (ts > t_next_publish_)   
            %% compute R
            R_bar_inv =  1./(1./f_Q(img1_round_in_0255) .* (1 - weight) + 1./f_Q(img2_round_in_0255) .* weight);
            R_inv_array = R_bar_inv .* (img1_round_in_01 .* (1 - weight) + img2_round_in_01 .* weight + safety_offset).^2;   
            
            %% gobal update           
            delta_t = (ts - ts_array_)/1e6;
            C = (log_intensity_state_ - log_intensity_now_) ./ P;
            log_intensity_state_ = (1 ./ (1 ./ P + R_inv_array .* delta_t)) .* C + log_intensity_now_;
            P = 1 ./ ((1 ./ P) + R_inv_array .* delta_t);
            P = P + sigma_p .* delta_t;
            ts_array_(:) = ts;
            
            %% high frequency image output          
            if output_high_frame_rate_flag
                output_img(log_intensity_now_,frame_idx,use_median_filter,safety_offset,post_process,high_frame_rate_folder,P,log_intensity_state_)
                frame_idx = frame_idx + 1;
            end            
            ts_array_(:) = ts;
            t_next_publish_ = t_next_publish_ + frame_time;                 
         end 
    end
end