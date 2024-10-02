#!/bin/bash -x
rootdir=/home/shoshi/MITgcm_c68r/MITgcm/verification/lab_sea

iter=$1
iter=$((iter+1))
optimext=$(printf "%04d" $iter)
workdir=$2
optimdir=$3
builddir=$4

cp ${rootdir}/input_adlo_2lev_seaice_update/* $workdir/
#need to overwrite data.autodiff to erase anything related to multigrid
cp ${rootdir}/input_ad_2lev_seaice/data.autodiff $workdir/
cp -rp ${rootdir}/code_ad_2lev_seaice_packunpack_update/ $workdir/
cp ${builddir}/mitgcmuv $workdir/
cp ${builddir}/Makefile $workdir/
cp ${builddir}/tamc.h $workdir/
cp ${rootdir}/input/tair.labsea1979 $workdir/
cp ${rootdir}/input/flo.labsea1979 $workdir/
cp ${rootdir}/input/fsh.labsea1979 $workdir/
#cp ${rootdir}/input/prate_allzeros.labsea1979 $workdir/
cp ${rootdir}/input/prate.labsea1979 $workdir/
cp ${rootdir}/input/qa.labsea1979 $workdir/
cp ${rootdir}/input/u10m.labsea1979 $workdir/
cp ${rootdir}/input/v10m.labsea1979 $workdir/
#cp ${rootdir}/input/bathy.labsea1979 $workdir/
cp ${rootdir}/input/bathy_gebco_sr.labsea1979 $workdir/
cp ${rootdir}/input/LevCli_salt.labsea1979 $workdir/
cp ${rootdir}/input/LevCli_temp.labsea1979 $workdir/
cp ${rootdir}/input_adlo.noseaice_costsst_tape4/sigma_sst_p010402.bin $workdir/
#cp ${rootdir}/input_ad/sigma_sst.bin $workdir/
#cp ${rootdir}/input_ad/labsea_SST_fields $workdir/
cp ${rootdir}/input_adlo.noseaice_costsst_tape4/ones_64b.bin $workdir/
cp ${rootdir}/input_adlo.noseaice_costsst/labsea_SST_fields_linear_rec006 $workdir/
cp ${optimdir}/ecco_ctrl_MIT_CE_000.opt$optimext $workdir/
#rm costfinal

#for unpacking: need mainunpack=.true., mainpack=.false.
    sed -i -e 's/'"doinitxx = .TRUE"'/'"doinitxx = .FALSE"'/g' data.ctrl
    sed -i -e 's/'"doInitxx = .TRUE"'/'"doInitxx = .FALSE"'/g' data.ctrl
    sed -i -e 's/'"doMainUnpack = .FALSE."'/'"doMainUnpack = .TRUE."'/g' data.ctrl
    sed -i -e 's/'"doMainUnpack = .false."'/'"doMainUnpack = .true."'/g' data.ctrl
    sed -i -e 's/'"doMainPack = .TRUE."'/'"doMainPack = .FALSE."'/g' data.ctrl
    sed -i -e 's/'"doMainPack = .true."'/'"doMainPack = .false."'/g' data.ctrl
#only need to run for one timestep for unpacking
#    sed -i -e 's/'"nTimeSteps=48"'/'"nTimeSteps=1"'/g' data

#--- 10. (re)set optimcycle --------------------

\rm data.optim
cat > data.optim <<EOF
 &OPTIM
 optimcycle=${iter},
 /
EOF

