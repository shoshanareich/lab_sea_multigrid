#!/bin/bash -x

rootdir=/home/shoshi/MITgcm_c68r/MITgcm/verification/lab_sea
iter=$1
dirhires=$2

builddir=$3


cp ${rootdir}/input_adlo_2lev_seaice_update/* ./
cp -rp ${rootdir}/code_adlo_2lev_seaice_update/ ./
cp ${builddir}/mitgcmuv_ad ./
cp ${builddir}/ad_taf_output.f ./
cp ${builddir}/Makefile ./
cp ${builddir}/tamc.h ./
cp ${rootdir}/input/tair.labsea1979 ./
cp ${rootdir}/input/flo.labsea1979 ./
cp ${rootdir}/input/fsh.labsea1979 ./
#cp ${rootdir}/input/prate_allzeros.labsea1979 ./
cp ${rootdir}/input/prate.labsea1979 ./
cp ${rootdir}/input/qa.labsea1979 ./
cp ${rootdir}/input/u10m.labsea1979 ./
cp ${rootdir}/input/v10m.labsea1979 ./
#cp ${rootdir}/input/bathy.labsea1979 ./
cp ${rootdir}/input/bathy_gebco_sr.labsea1979 ./
cp ${rootdir}/input/LevCli_salt.labsea1979 ./
cp ${rootdir}/input/LevCli_temp.labsea1979 ./
cp ${rootdir}/input_adlo.noseaice_costsst/sigma_sst_p01.bin ./
cp ${rootdir}/input_adlo.noseaice_costsst/ones_64b.bin ./
cp ${rootdir}/input_adlo.noseaice_costsst/labsea_SST_fields_linear_rec006 ./
cp ${rootdir}/input_adlo_nodiva/sigma_sst_p010402.bin ./
cp ${dirhires}/costfinallo_sst ./costfinal
cp ${dirhires}/misfit_sst_lo.data ./misfit_sst.data
cp ${dirhires}/misfit_sst_lo.meta ./misfit_sst.meta
#cp ${dirhires}/m_sst_day_lo.data ./m_sst_day.000000000${iter}.data
cp ${rootdir}/input_adlo.noseaice_costsst_tape4/m_sst_step.0000000000.meta ./m_sst_step.000000000${iter}.meta
#cp ${dirhires}/xx_theta_lo.000000000${iter}.data ./xx_theta.000000000${iter}.data
cp ${rootdir}/input_adlo.noseaice_costsst_tape4/xx_theta.0000000000.meta ./xx_theta.000000000${iter}.meta
#cp ${dirhires}/xx_theta_lo.effective.000000000${iter}.data ./xx_theta.effective.000000000${iter}.data
cp ${rootdir}/input_adlo.noseaice_costsst_tape4/xx_theta.effective.0000000000.meta ./xx_theta.effective.000000000${iter}.meta

#tapes:
rm -rf ./tapes
cp -r $dirhires/tapes ./

##--- 5. linking xx_ fields ------
#if [ ${iter} -lt 1 ]; then
#  sed -i -e 's/'"doinitxx = .FALSE."'/'"doinitxx = .TRUE."'/g' data.ctrl
#  sed -i -e 's/'"doInitXX = .FALSE."'/'"doInitXX = .TRUE."'/g' data.ctrl
#  sed -i -e 's/'"doMainPack = .FALSE."'/'"doMainPack = .TRUE."'/g' data.ctrl
#  sed -i -e 's/'"doMainUnpack = .TRUE."'/'"doMainUnpack = .FALSE."'/g' data.ctrl
#else
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

