timing_tool.py -timing SliceTimingForAll.txt -scale_data 0.001 -write_timing SliceTimingSec

TR=`3dinfo -tr ${wf}/${s}/r1_RS_original.nii.gz`
NV=`3dinfo -nv ${wf}/${s}/r1_RS_original.nii.gz`
plrt=`echo "1" | bc`

3dToutcount -automask -fraction -polort ${plrt} ${wf}/${s}/r1_RS_original.nii.gz > outcount.1D
1deval -a outcount.1D -expr "1-step(a-0.1)" > out_censor.1D

min_outlier_index=`3dTstat -argmin -prefix - outcount.1D\' | sed "s/ //g"`

3dDespike -NEW -nomask -prefix r02_despike.nii.gz ${wf}/${s}/r1_RS_original.nii.gz

3dvolreg -prefix r02_PA_volreg.nii.gz -base r02_despike.nii.gz[${min_outlier_index}] ${wf}/${s}/r1_PA_original.nii.gz
3dvolreg -prefix r03_volreg.nii.gz -base r02_despike.nii.gz[${min_outlier_index}] -1Dfile ./motion_parameters.1D r02_despike.nii.gz

3dTstat -median -prefix rm.blip.med.fwd r03_volreg.nii.gz
3dTstat -median -prefix rm.blip.med.rev r02_PA_volreg.nii.gz

3dAutomask -apply_prefix rm.blip.med.masked.fwd rm.blip.med.fwd+orig
3dAutomask -apply_prefix rm.blip.med.masked.rev rm.blip.med.rev+orig

3dQwarp -plusminus -pmNAMES Rev For                           \
	-pblur 0.05 0.05 -blur -1 -1                          \
	-noweight -minpatch 9                                 \
	-source rm.blip.med.masked.rev+orig                   \
	-base   rm.blip.med.masked.fwd+orig                   \
	-prefix blip_warp

3dNwarpApply -quintic -nwarp blip_warp_For_WARP+orig      \
	     -source r03_volreg.nii.gz       \
             -prefix r04_QwarpNwarp.nii.gz

3drefit -atrcopy r03_volreg.nii.gz IJK_TO_DICOM_REAL      \
	r04_QwarpNwarp.nii.gzfz

3dTshift -tpattern @./SliceTimingSec -prefix r05_tshift.nii.gz r04_QwarpNwarp.nii.gz
3dresample -orient LPI -prefix r06_reorient.nii.gz -inset r05_tshift.nii.gz
3dDetrend -DAFNI_1D_TRANOUT=YES -prefix motion_parameters_det.1D -polort ${plrt} motion_parameters.1D\'
1d_tool.py -infile motion_parameters.1D -derivative -demean -write motion_parameters_der.1D

1d_tool.py -infile motion_parameters.1D -show_censor_count -censor_prev_TR -censor_motion 0.3 motion_parameters

1d_tool.py -infile motion_parameters_det.1D -show_max_displace | cut -d " " -f3 > max_displace

1deval -a out_censor.1D -b motion_parameters_censor.1D -expr "a*b" > censor_combined.1D
1d_tool.py -show_censor_count -infile censor_combined.1D > censor_count

3dAutomask -dilate 1 -prefix Brain_mask.nii.gz ./r06_reorient.nii.gz

3dresample -orient LPI -prefix a1_brain.nii.gz -inset ${wf}/${s}/a1_brain.nii.gz
3dresample -orient LPI -prefix a1_aseg.nii.gz -inset ${wf}/${s}/a1_aseg.nii.gz

@Align_Centers -cm -base r06_reorient.nii.gz -dset a1_brain.nii.gz -child a1_aseg.nii.gz

3dresample -master a1_brain_shft.nii.gz -prefix ttt.nii.gz -inset r06_reorient.nii.gz[`echo ${min_outlier_index}`]
3dWarpDrive -prefix a2_brain_shiftrotate.nii.gz -shift_rotate -final NN -base ttt.nii.gz -input a1_brain_shft.nii.gz
3dWarp -NN -matparent a2_brain_shiftrotate.nii.gz -prefix a2_aseg_shiftrotate.nii.gz a1_aseg_shft.nii.gz
rm ttt.nii.gz

align_epi_anat.py -big_move -cost lpc+ZZ -anat ./a2_brain_shiftrotate.nii.gz -epi r06_reorient.nii.gz -epi_base ${min_outlier_index} -partial_axial -volreg off -tshift off -anat_has_skull no -epi_strip 3dAutomask -Allineate_opts '-final NN' -child_anat a2_aseg_shiftrotate.nii.gz

@auto_tlrc -init_xform AUTO_CENTER -base MNI152_T1_2009c+tlrc -input a2_brain_shiftrotate_al+orig -no_ss

3dcalc -a a2_aseg_shiftrotate_al+orig -expr 'amongst(a,2,7,41,46,251,252,253,254,255)' -prefix ttt_WM_highres.nii.gz
3dmask_tool -input ttt_WM_highres.nii.gz -prefix ttt_WM_highres_erod.nii.gz -dilate_input -1
3dfractionize -prefix WM_EPImask.nii.gz -template r06_reorient.nii.gz -input ttt_WM_highres_erod.nii.gz -clip 0.8
3dcalc -a a2_aseg_shiftrotate_al+orig -expr 'amongst(a,4,43)' -prefix ttt_LV_highres.nii.gz
3dfractionize -prefix LV_EPImask.nii.gz -template r06_reorient.nii.gz -input ttt_LV_highres.nii.gz -clip 0.7
rm ttt_LV_highres.nii.gz ttt_WM_highres_erod.nii.gz ttt_WM_highres.nii.gz

3dmaskave -q -mask LV_EPImask.nii.gz r06_reorient.nii.gz > lv.1D
3dmaskave -q -mask WM_EPImask.nii.gz r06_reorient.nii.gz > wm.1D
3dDetrend -DAFNI_1D_TRANOUT=YES -normalize -prefix lv_det.1D -polort ${plrt} ./lv.1D\'
3dDetrend -DAFNI_1D_TRANOUT=YES -normalize -prefix wm_det.1D -polort ${plrt} ./wm.1D\'

3dTproject -input r06_reorient.nii.gz -polort ${plrt} -cenmode NTRP -mask Brain_mask.nii.gz -censor censor_combined.1D -ort motion_parameters_det.1D -ort motion_parameters_der.1D -ort lv_det.1D -ort wm_det.1D -prefix r07_cleaned.nii.gz

3dBandpass -prefix r08_bandpass.nii.gz 0.009 0.08 r07_cleaned.nii.gz

3dcalc -prefix GM_EPImask.nii.gz -a ./Brain_mask.nii.gz -b ./WM_EPImask.nii.gz -c ./LV_EPImask.nii.gz -expr "step(a)-step(b)-step(c)"
3dBlurInMask -prefix r09 -mask ./GM_EPImask.nii.gz -FWHM 5 -preserve -input ./r08_bandpass.nii.gz


