3dmaskave -q -mask ${scriptwf}/${roi}.nii.gz ${wf}/${s}/r09_RS.nii.gz > ${targetwf}/TimeS/TS_${s}_${roi}.1D

3dDeconvolve -input ${wf}/${s}/r09_RS.nii.gz -censor ${wf}/${s}/censor_combined.1D \
-polort -1 -num_stimts 1 \
-stim_file 1 ${targetwf}/TimeS/TS_${s}_${roi}.1D -stim_label 1 ROI \
-fout -tout -rout -bucket ${targetwf}/Images/r10_${s}_${roi}.nii.gz

3dcalc -prefix ${targetwf}/Images/r11_${s}_${roi}.nii.gz -a ${targetwf}/Images/r10_${s}_${roi}.nii.gz[2] -b ${targetwf}/Images/r10_${s}_${roi}.nii.gz[4] -expr "ispositive(a)*sqrt(b)-isnegative(a)*sqrt(b)"

3dcalc -prefix ${targetwf}/Images/r12_${s}_${roi}.nii.gz -a ${targetwf}/Images/r11_${s}_${roi}.nii.gz  -expr "0.5*log((1+a)/(1-a))"



