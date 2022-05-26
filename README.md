# An Asynchronous Kalman Filter for Hybrid Event Cameras
## For academic use only

Ziwei Wang, Yonhon Ng, Cedric Scheerlinck and Robert Mahony

The paper was accepted by the 2021 IEEE Int. Conf. Computer Vision (ICCV), 2021

The conference paper PDF is available here:
https://openaccess.thecvf.com/content/ICCV2021/papers/Wang_An_Asynchronous_Kalman_Filter_for_Hybrid_Event_Cameras_ICCV_2021_paper.pdf

ArXiv: https://arxiv.org/abs/2012.05590
## Citation
If you use or discuss our AKF, please cite our paper as follows:
<pre>

@InProceedings{Wang_2021_ICCV,
    author    = {Wang, Ziwei and Ng, Yonhon and Scheerlinck, Cedric and Mahony, Robert},
    title     = {An Asynchronous Kalman Filter for Hybrid Event Cameras},
    booktitle = {Proceedings of the IEEE/CVF International Conference on Computer Vision (ICCV)},
    month     = {October},
    year      = {2021},
    pages     = {448-457}
}
</pre>


## Video
[https://www.youtube.com/watch?v=XPz7laloKws](https://www.youtube.com/watch?v=XPz7laloKws)


## Code - How to use


There are a few parameters that users can specify:

### In file './run_akf.m':
1.  'deblur_option', true for deblur and false for no deblur. Use the deblur option if the input images are blurry. 
2.  'framerate': the frame rate of the output image sequence in Hz.
3.  'use_median_filter', a flag of applying a 3-by-3 median filter to the output images.
4.  'output_high_frame_rate_flag': true: output images of the pre-defined framerate, false: output images of the frame intensity framerate.
5.  'sigma_p': the process noise parameter, default 0.0005.
6.  'sigma_i': the isolated noise parameter, default 0.03.
7.  'sigma_r': the refractory noise parameter, default 0.05.
8.  'refractory_period': the refractory period in microsecond. It models the circuit limitations in each pixel of an event camera limit the response time of events, default 1*10^4.
9.  'min_ct_scale': the minimal value for the contrast threshold scaling factor, default 0.6.
10. 'max_ct_scale': the maximal value for the contrast threshold scaling factor, default 100. 
11. 'p_ini': initial value for state covariance P, default 0.09. 

### [Click To Download Example Datasets Download](https://anu365-my.sharepoint.com/:f:/g/personal/u6456661_anu_edu_au/Epc5ULLIIENAsDtNYycTdp4BtfG8Sn2ImaL44h_qhvf2jw?e=aRIV29)
Download the datasets and save them in folder './data'.
Dataset name convention: DatasetName_StartFrame_EndFrame of the original dataset (we only keep the fast motion part or highly HDR part in the sample datasets. You can download the whole dataset sequence from the website of the following papers, and test if you like). The example datasets are publicly available datasets from:
Mueggler et al., IJRR 2017.
Scherlinck et al., ACCV 2018.
Gehrig et al., ICRA 2021.

If you want to use your datasets, define the post_process method, f_Q, exposure time, contrast threshold (ct) at the beginning of './akf_reconstruction.m'. See notes in the next section.

### In file 'akf_reconstruction.m':
1. 'post_process': 0 for no normalization, 1 for (image-min/(max-min)), 2 for user-defined maximum and minimum value for extremely bright view, 3 for user-defined maximum and minimum value for extremely dark view. Post-processing methods are important in displaying the reconstructed HDR images since the intensity values can go beyond 0 and 1. Without a proper post-processing method, the details in the HDR part of the image (higher than 1 or lower than 0) can not be displayed. Users can adjust the pre-defined maximum and minimum value in file './output_img.m' to have the best visualization.
2. The 'f_Q' is the most important parameter for image noise. It represents the inverse of the R_bar function in equation (6) in the paper. You can simply treat it as the image confidence function of intensity. For example, for an image in the range [0 255], the extreme values around 0 and 255 would have lower confidence. The 'f_Q' is included in the provided dataset. If you are using your own dataset, you need to tune it carefully.
3. The preset exposure time for each intensity image is included in the provided datasets (some datasets are recorded with auto-exposure, e.g., interlaken_01a_events_1_150.mat). If you want to use your own dataset, please set or estimate the exposure time as well.
4. If the exposure time for the intensity images are very short and there is almost no blurry, you can disable the deblur function by setting 'deblur_option' = 0. But you still need to define an 'exposure' time. 


### Notes
1. Make sure your event and image timestamps are well aligned.
2. As a nature of the filtering methods, the quality of the reconstruction results is relevant to the quality of event camera datasets. Datasets with obvious noise recorded by hybrid event-frame cameras or lower resolution/sensitivity cameras such as DAVIS 240 might lead to unsatisfied results in high temporal resolution video reconstruction. The method requires a short time to adapt and converge to the optimal Kalman filter parameters for each dataset.
3. If you have any questions or suggestions regarding this code and the corresponding results, please don't hesitate to get in touch with ziwei.wang1@anu.edu.au





