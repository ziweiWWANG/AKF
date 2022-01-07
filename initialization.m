function [ts_array_,ts_array_2,frame_idx,R,C,weight]...
    = initialization(height, width)
    ts_array_ = zeros(height, width);
    ts_array_2 = zeros(height, width);
    R = ones(height,width);
    C = zeros(height,width);
    frame_idx = 0;
    weight = 0;
end