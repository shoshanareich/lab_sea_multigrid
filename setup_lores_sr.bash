#!/bin/bash -x
rootdir=/home/shoshi/MITgcm_c68r/MITgcm/verification/lab_sea
iter=0
ext2=$(printf "%04d" $iter)
jobfile=$rootdir/setup_lores_sr.bash
workdir=/scratch/shoshi/labsea_MG/bathy_tests/run_adlo_2lev_seaice_it${ext2}_good_bathy_2
dirhires=/scratch/shoshi/labsea_MG/bathy_tests/run_adhi_2lev_seaice_it${ext2}_good_bathy_2


mkdir $workdir
cd $workdir

mkdir diags

conda activate py38
#python3 ../make_cost_cp.py "$ext2" linear

cp ${rootdir}/input_adlo_2lev_seaice/* $workdir/
cp -rp ${rootdir}/code_adlo_2lev_seaice/ $workdir/
cp ${rootdir}/build_adlo_2lev_seaice/mitgcmuv_ad $workdir/
cp ${rootdir}/build_adlo_2lev_seaice/ad_taf_output.f $workdir/
cp ${rootdir}/build_adlo_2lev_seaice/Makefile $workdir/
cp ${rootdir}/build_adlo_2lev_seaice/tamc.h $workdir/
cp ${rootdir}/input/tair.labsea1979 $workdir/
cp ${rootdir}/input/flo.labsea1979 $workdir/
cp ${rootdir}/input/fsh.labsea1979 $workdir/
#cp ${rootdir}/input/prate_allzeros.labsea1979 $workdir/
cp ${rootdir}/input/prate.labsea1979 $workdir/
cp ${rootdir}/input/qa.labsea1979 $workdir/
cp ${rootdir}/input/u10m.labsea1979 $workdir/
cp ${rootdir}/input/v10m.labsea1979 $workdir/
#cp ${rootdir}/input/bathy.labsea1979 $workdir/
cp ${rootdir}/input/bathy_gebco_update_sr.labsea1979 $workdir/
cp ${rootdir}/input/LevCli_salt.labsea1979 $workdir/
cp ${rootdir}/input/LevCli_temp.labsea1979 $workdir/
cp ${rootdir}/input_adlo.noseaice_costsst/sigma_sst_p01.bin $workdir/
cp ${rootdir}/input_adlo.noseaice_costsst/ones_64b.bin $workdir/
cp ${rootdir}/input_adlo.noseaice_costsst/labsea_SST_fields_linear_rec006 $workdir/
cp ${rootdir}/input_adlo_nodiva/sigma_sst_p010402.bin $workdir/
#cp ${rootdir}/input_adlo.noseaice_costsst_tape4/divided.ctrl ./
cp ${dirhires}/costfinallo_sst $workdir/costfinal
cp ${dirhires}/misfit_sst_lo.data ./misfit_sst.data
cp ${dirhires}/misfit_sst_lo.meta ./misfit_sst.meta
cp $jobfile $workdir/
#cp ${dirhires}/m_sst_step_lo.data ./m_sst_step.000000000${iter}.data
cp ${rootdir}/input_adlo.noseaice_costsst_tape4/m_sst_step.0000000000.meta ./m_sst_step.000000000${iter}.meta
#cp ${dirhires}/xx_theta_lo.000000000${iter}.data ./xx_theta.000000000${iter}.data
cp ${rootdir}/input_adlo.noseaice_costsst_tape4/xx_theta.0000000000.meta ./xx_theta.000000000${iter}.meta
#cp ${dirhires}/xx_theta_lo.effective.000000000${iter}.data ./xx_theta.effective.000000000${iter}.data
cp ${rootdir}/input_adlo.noseaice_costsst_tape4/xx_theta.effective.0000000000.meta ./xx_theta.effective.000000000${iter}.meta

#tapes:
rm -rf $workdir/tapes
cp -r $dirhires/tapes $workdir/

##--- 5. linking xx_ fields ------
##this portion is taken care of with make_costsst_cp.m
#if [ ${iter} -gt 0 ]; then
###this extxx is copied from the setup_hires_run_linear.bash
#    sed -i -e 's/'"doinitxx = .TRUE"'/'"doinitxx = .FALSE"'/g' data.ctrl
#    sed -i -e 's/'"doInitxx = .TRUE"'/'"doInitxx = .FALSE"'/g' data.ctrl
#    sed -i -e 's/'"doMainUnpack = .TRUE."'/'"doMainUnpack = .FALSE."'/g' data.ctrl
#    sed -i -e 's/'"doMainPack = .FALSE."'/'"doMainPack = .TRUE."'/g' data.ctrl
  sed -i -e 's/'"doinitxx = .TRUE."'/'"doinitxx = .FALSE."'/g' data.ctrl
  sed -i -e 's/'"doInitXX = .TRUE."'/'"doInitXX = .FALSE."'/g' data.ctrl
  sed -i -e 's/'"doMainPack = .FALSE."'/'"doMainPack = .TRUE."'/g' data.ctrl
  sed -i -e 's/'"doMainUnpack = .FALSE."'/'"doMainUnpack = .FALSE."'/g' data.ctrl
#fi

#--- 10. (re)set optimcycle --------------------

\rm data.optim
cat > data.optim <<EOF
 &OPTIM
 optimcycle=${iter},
 /
EOF

