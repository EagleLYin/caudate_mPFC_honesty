### GBC ###

3dTcorrMap -input ${wf}/${s}/r09_RS.nii.gz -automask -Zmean ${wf}/${s}/r10_GBC_RS.nii.gz
3dcalc -a ${wf}/${s}/r10_GBC_RS.nii.gz -expr 'atanh(a)' -prefix ${wf}/${s}//r11_GBC_RS.nii.gz



