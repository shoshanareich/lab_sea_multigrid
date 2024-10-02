#!/bin/bash -x
rootdir=/home/shoshi/MITgcm_c68r/MITgcm/verification/lab_sea

iter=1
ext2=$(printf "%04d" $iter)

jobfile=$rootdir/setup_packunpack_sr.bash
workdir=$rootdir/run_adlo_2lev_seaice_packunpack
optimdir=$rootdir/run_adlo_2lev_seaice_it0000/OPTIM
#optimdir=$rootdir/OPTIM_3060_tape4
mkdir $workdir
cd $workdir
cp ${rootdir}/input_adlo_2lev_seaice/* $workdir/
#need to overwrite data.autodiff to erase anything related to multigrid
cp ${rootdir}/input_ad_2lev_seaice/data.autodiff $workdir/
cp -rp ${rootdir}/code_ad_2lev_seaice_packunpack/ $workdir/
cp ${rootdir}/build_ad_2lev_seaice_packunpack/mitgcmuv $workdir/
cp ${rootdir}/build_ad_2lev_seaice_packunpack/Makefile $workdir/
cp ${rootdir}/build_ad_2lev_seaice_packunpack/tamc.h $workdir/
cp ${rootdir}/input/tair.labsea1979 $workdir/
cp ${rootdir}/input/flo.labsea1979 $workdir/
cp ${rootdir}/input/fsh.labsea1979 $workdir/
#cp ${rootdir}/input/prate_allzeros.labsea1979 $workdir/
cp ${rootdir}/input/prate.labsea1979 $workdir/
cp ${rootdir}/input/qa.labsea1979 $workdir/
cp ${rootdir}/input/u10m.labsea1979 $workdir/
cp ${rootdir}/input/v10m.labsea1979 $workdir/
cp ${rootdir}/input/bathy.labsea1979 $workdir/
cp ${rootdir}/input/LevCli_salt.labsea1979 $workdir/
cp ${rootdir}/input/LevCli_temp.labsea1979 $workdir/
cp ${rootdir}/input_adlo.noseaice_costsst_tape4/sigma_sst_p010402.bin $workdir/
#cp ${rootdir}/input_ad/sigma_sst.bin $workdir/
#cp ${rootdir}/input_ad/labsea_SST_fields $workdir/
cp ${rootdir}/input_adlo.noseaice_costsst_tape4/ones_64b.bin $workdir/
cp ${rootdir}/input_adlo.noseaice_costsst/labsea_SST_fields_linear_rec006 $workdir/
cp $jobfile $workdir/
cp ${optimdir}/ecco_ctrl_MIT_CE_000.opt$ext2 $workdir/
#rm costfinal

#for unpacking: need mainunpack=.true., mainpack=.false.
    sed -i -e 's/'"doinitxx = .TRUE"'/'"doinitxx = .FALSE"'/g' data.ctrl
    sed -i -e 's/'"doInitxx = .TRUE"'/'"doInitxx = .FALSE"'/g' data.ctrl
    sed -i -e 's/'"doMainUnpack = .FALSE."'/'"doMainUnpack = .TRUE."'/g' data.ctrl
    sed -i -e 's/'"doMainUnpack = .false."'/'"doMainUnpack = .true."'/g' data.ctrl
    sed -i -e 's/'"doMainPack = .TRUE."'/'"doMainPack = .FALSE."'/g' data.ctrl
    sed -i -e 's/'"doMainPack = .true."'/'"doMainPack = .false."'/g' data.ctrl
#only need to run for one timestep for unpacking
#    sed -i -e 's/'"nTimeSteps=576"'/'"nTimeSteps=1"'/g' data

#--- 10. (re)set optimcycle --------------------

\rm data.optim
cat > data.optim <<EOF
 &OPTIM
 optimcycle=${iter},
 /
EOF

#./mitgcmuv
