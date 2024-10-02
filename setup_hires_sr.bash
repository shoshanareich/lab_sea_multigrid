#!/bin/bash -x

#cd $rootdir
iter=0
ext2=$(printf "%04d" $iter)

rootdir=/home/shoshi/MITgcm_c68r/MITgcm/verification/lab_sea
dirrun_pup=${rootdir}/run_adlo_2lev_seaice_packunpack/
workdir=/scratch/shoshi/labsea_MG/bathy_tests/run_adhi_2lev_seaice_it${ext2}_good_bathy_2
mkdir $workdir
cd $workdir

mkdir diags

cp ${rootdir}/input_adhi_2lev_seaice/* $workdir/
cp -rp ${rootdir}/code_adhi_2lev_seaice/ $workdir/
cp ${rootdir}/build_adhi_2lev_seaice/mitgcmuv_ad $workdir/
cp ${rootdir}/build_adhi_2lev_seaice/ad_taf_output.f $workdir/
cp ${rootdir}/build_adhi_2lev_seaice/Makefile $workdir/
cp ${rootdir}/build_adhi_2lev_seaice/tamc.h $workdir/
cp ${rootdir}/input_binaries_hires/tair.labsea1979 $workdir
cp ${rootdir}/input_binaries_hires/flo.labsea1979 $workdir
cp ${rootdir}/input_binaries_hires/fsh.labsea1979 $workdir
cp ${rootdir}/input_binaries_hires/prate_allzeros.labsea1979 $workdir
cp ${rootdir}/input_binaries_hires/prate.labsea1979 $workdir
cp ${rootdir}/input_binaries_hires/qa.labsea1979 $workdir
cp ${rootdir}/input_binaries_hires/u10m.labsea1979 $workdir
cp ${rootdir}/input_binaries_hires/v10m.labsea1979 $workdir
#cp ${rootdir}./input_binaries_hires/bathy_80x64_linear.labsea1979 ./
cp ${rootdir}/input_binaries_hires/bathy_gebco_sr.labsea1979 ./
cp ${rootdir}/input_binaries_hires/LevCli_salt_80x64_linear.labsea1979 ./
cp ${rootdir}/input_binaries_hires/LevCli_temp_80x64_linear.labsea1979 ./
#cp ${rootdir}/input_binaries_hires/labsea_SST_fields_linear_ix6580_jy0116_rec4548 ./
cp ${rootdir}/input_binaries_hires/labsea_SST_fields_linear_80x64_rec4548 ./
cp ${rootdir}/input_binaries_hires/labsea_SST_fields_linear_80x64_rec006 ./
#cp ${rootdir}/input_binaries_hires/labsea_SST_fields_linear_80x64_nocoast_rec4548 ./
cp ${rootdir}/input_binaries_hires/sigma_sst_p010402_80x64.bin ./
cp ${rootdir}/input_binaries_hires/sshv4_scale_4points.bin ./
cp ${rootdir}/input_binaries_hires/ones_64b.bin ./
cp ${rootdir}/input_binaries_hires/smooth2Dscales001_x4 ./smooth2Dscales001.data
cp ${rootdir}/input_binaries_hires/smooth3DscalesH001_x4 ./smooth3DscalesH001.data 
cp ${rootdir}/input_binaries_hires/smooth3DscalesZ001 ./smooth3DscalesZ001
cp ${rootdir}/input_binaries_hires/smooth*operator* ./
cp ${rootdir}/input_binaries_hires/smooth*norm* ./

#-- swap out data.ctrl and copy high-res adjustments
if [ ${iter} -lt 1 ]; then
  sed -i -e 's/'"doinitxx = .FALSE."'/'"doinitxx = .TRUE."'/g' data.ctrl
  sed -i -e 's/'"doInitXX = .FALSE."'/'"doInitXX = .TRUE."'/g' data.ctrl
  sed -i -e 's/'"doMainPack = .FALSE."'/'"doMainPack = .TRUE."'/g' data.ctrl
  sed -i -e 's/'"doMainUnpack = .TRUE."'/'"doMainUnpack = .FALSE."'/g' data.ctrl
else
#  mkdir adxxfiles/
  cp -f ${dirrun_pup}/xx_theta_linear.000000${ext2}.data ./xx_theta.000000${ext2}.data
  cp -f ${dirrun_pup}/xx_atemp_linear.000000${ext2}.data ./xx_atemp.000000${ext2}.data
  cp -f ${rootdir}/input_binaries_hires/xx_theta.0000000000.meta ./xx_theta.000000${ext2}.meta
  cp -f ${rootdir}/input_binaries_hires/xx_atemp.0000000000.meta ./xx_atemp.000000${ext2}.meta
  sed -i -e 's/'"doinitxx = .TRUE."'/'"doinitxx = .FALSE."'/g' data.ctrl
  sed -i -e 's/'"doInitXX = .TRUE."'/'"doInitXX = .FALSE."'/g' data.ctrl
  sed -i -e 's/'"doMainPack = .FALSE."'/'"doMainPack = .TRUE."'/g' data.ctrl
  sed -i -e 's/'"doMainUnpack = .FALSE."'/'"doMainUnpack = .FALSE."'/g' data.ctrl
  sed -i -e 's/'"doMainUnpack = .false."'/'"doMainUnpack = .false."'/g' data.ctrl

\rm data.optim
cat > data.optim <<EOF
 &OPTIM
 optimcycle=${iter},
 /
EOF

#  cp ${rootdir}/run_adlo_noseaice_costsst_linear_packunpack_redo/xx_atemp.000000000${iter}.meta .
#  cp ${rootdir}/run_adlo_noseaice_costsst_linear_packunpack_redo/xx_atemp_l.000000000${iter}.data ./xx_atemp.000000000${iter}.data
#  cp ${rootdir}/run_adlo_noseaice_costsst_linear_packunpack_redo/xx_theta.000000000${iter}.meta .
#  cp ${rootdir}/run_adlo_noseaice_costsst_linear_packunpack_redo/xx_theta_l.000000000${iter}.data ./xx_theta.000000000${iter}.data
fi


