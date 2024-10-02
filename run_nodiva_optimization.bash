#!/bin/bash -x
#SBATCH -J labsea 
#SBATCH -o labsea.%j.out
#SBATCH -e labsea.%j.err
#SBATCH -t 02:00:00
#SBATCH -N 1
#SBATCH -n 1

#--- 0.load modules ------
module purge
#module load intel openmpi netcdf-fortran
module load intel/2023.1.0 openmpi4/4.1.5 phdf5/1.14.1 netcdf-fortran/4.6.0 netcdf/4.9.0 prun
echo $LD_LIBRARY_PATH

ulimit -s hard
ulimit -u hard

#---- 1.set variables ------
# note: for nprocs, take ntiles - length(blanklist)
nprocs=1
snx=20
sny=16
iter=0
itermax=9
costfactor=0.95

jobfile=run_nodiva_optimization.bash

#--- set dir ------------
rootdir=/home/shoshi/MITgcm_c68r/MITgcm/verification/lab_sea

codedir=$rootdir/code_ad_2lev_seaice_update
builddir_lo=$rootdir/build_ad_2lev_seaice_update
#builddir_lo=$rootdir/build_ad_2lev_seaice_tapes
inputdir=$rootdir/input_ad_2lev_seaice_update

# --- optim ---
optimdir=/scratch/shoshi/labsea_MG/OPTIM_3060_nodiva

while [ ! ${iter} -gt $itermax ]; do

  ext2=$(printf "%04d" $iter)

  workdir=/scratch/shoshi/labsea_MG/run_ad_2lev_seaice_it${ext2}_dv_update

  if [ ! -d $workdir ]; then
    mkdir -p $workdir;
  fi
  
  cd $workdir

  mkdir diags

  rm -f tapes/*
  rm -f profiles/*


  cp -rf ${codedir}/ .
  
#--- 3. link forcing -------------

  #--- 4. linking binary ---------
  cp ${builddir_lo}/ad_taf_output.f .
  cp ${builddir_lo}/tamc.h .
 
  cp -rp ${codedir}/ $workdir/
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
  cp ${rootdir}/input_adlo_nodiva/sigma_sst_p010402.bin $workdir/
  cp ${rootdir}/input_adlo.noseaice_costsst/ones_64b.bin $workdir/
  cp ${rootdir}/input_adlo.noseaice_costsst/labsea_SST_fields_linear_rec006 $workdir/


  #=================================================================================
  #--- 6. NAMELISTS ---------
  cp ${inputdir}/* .
  cp ${rootdir}/input_adhi_2lev_seaice/data.diagnostics .
  sed -i -e 's/'"useDiagnostics = .FALSE."'/'"useDiagnostics = .TRUE."'/g' data.ctrl

#-- swap out data.ctrl
  if [ ${iter} -lt 1 ]; then
    sed -i -e 's/'"doinitxx = .FALSE."'/'"doinitxx = .TRUE."'/g' data.ctrl
    sed -i -e 's/'"doInitXX = .FALSE."'/'"doInitXX = .TRUE."'/g' data.ctrl
    sed -i -e 's/'"doMainPack = .FALSE."'/'"doMainPack = .TRUE."'/g' data.ctrl
    sed -i -e 's/'"doMainUnpack = .TRUE."'/'"doMainUnpack = .FALSE."'/g' data.ctrl
  else
    cp -f ${optimdir}/ecco_ctrl_MIT_CE_000.opt${ext2} ./
    sed -i -e 's/'"doinitxx = .TRUE."'/'"doinitxx = .FALSE."'/g' data.ctrl
    sed -i -e 's/'"doInitXX = .TRUE."'/'"doInitXX = .FALSE."'/g' data.ctrl
    sed -i -e 's/'"doMainPack = .FALSE."'/'"doMainPack = .TRUE."'/g' data.ctrl
    sed -i -e 's/'"doMainUnpack = .FALSE."'/'"doMainUnpack = .TRUE."'/g' data.ctrl
    sed -i -e 's/'"doMainUnpack = .false."'/'"doMainUnpack = .TRUE."'/g' data.ctrl
  fi 



  #--- 7. executable --------
  \rm -f mitgcmuv*
  cp -f ${builddir_lo}/mitgcmuv_ad ./
  cp -f ${builddir_lo}/Makefile ./

  #--- 8. pickups -----------

  #--- 9. (re)set optimcycle --------------------
  \rm data.optim
  cat > data.optim <<EOF
   &OPTIM
   optimcycle=${iter},
   /
EOF
  

  #--- 11. run ----------------------------------
  set -x
  date > run.MITGCM.timing
  ./mitgcmuv_ad > stdout
  ./mitgcmuv_ad > stdout
  sed -i 's/4/0/g' divided.ctrl
  ./mitgcmuv_ad > stdout
  date >> run.MITGCM.timing

  #---- 12. cleanup -----------------------------
  mv tape*data tapes/
  du -sh tapes > list_tapes
  \rm -rf tapes/
  \rm -rf tape*
  ls -l pickup* > list_pickup
#  \rm pickup*
  \rm w2_tile_topology.*

  #--- 13. OPTIM ---------------------------------
  cd ${optimdir}
  bash reset.bash
  cp ${workdir}/ecco_cost_MIT_CE_000.opt${ext2} ${optimdir} 
  cp ${workdir}/ecco_ctrl_MIT_CE_000.opt${ext2} ${optimdir} 
  cp -f ${workdir}/costfunction${ext2} ${optimdir}
#  cost=$(grep fc costfunction${ext2}  | sed 's/D/E/g' | awk '{printf "%14.12e", $3}')
#  costf=$(grep fc costfunction${ext2} | sed 's/D/E/g' | awk '{printf "%0.14f", $3}')
  echo "iter = $iter"
#  echo "cost = $cost"
  
#  costupdate=$(echo $costf*$costfactor | bc)
#  costnew=`echo $costupdate|awk '{printf "%14.12e\n", $costupdate}'`
#  echo "costnew = $costnew"

  mv data.optim data.optim_bk
  cat > data.optim <<EOF
    &OPTIM
    optimcycle=${iter},
    numiter=100,
    nfunc=9,
    dfminFrac=0.05,
#    fmin=${costnew},
    iprint=10,
    nupdate=4,
    /
    &M1QN3
    coldstart = .TRUE.,
    /
EOF

  \rm OP*
  ./optim.x > output_optim_it${ext2}.txt

  dir_iter=${workdir}/run_optim/+it${ext2}
  mkdir -p $dir_iter
  cp data.optim $dir_iter
  cp data.optim data.optim_${ext2}
  cp ecco_ctrl_MIT_CE_000.opt${ext2} $dir_iter

#  let iter=6
  let iter=iter+1
done

echo "DONE"
