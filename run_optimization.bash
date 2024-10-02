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

source activate py38

#---- set variables ------
# note: for nprocs, take ntiles - length(blanklist)
nprocs=1
snx_hi=80
sny_hi=64
snx_lo=20
sny_lo=16
iter=0
itermax=5
costfactor=0.95
interp_type="linear"
#interp_type="nearest"

jobfile=run_optimization.bash

#--- set dir ------------
rootdir=/home/shoshi/MITgcm_c68r/MITgcm/verification/lab_sea

builddir_hi=$rootdir/build_adhi_2lev_seaice_update
builddir_lo=$rootdir/build_adlo_2lev_seaice_update
builddir_pup=$rootdir/build_ad_2lev_seaice_packunpack_update
optimdir=/scratch/shoshi/labsea_MG/bathy_tests/OPTIM_3600

# --- optim ---

while [ ! ${iter} -gt $itermax ]; do

  ext2=$(printf "%04d" $iter)

# --- 1.high-res forward run ---  
  
  workdir_hi=/scratch/shoshi/labsea_MG/bathy_tests/run_adhi_2lev_seaice_it${ext2}_bad_bathy

  if [ ! -d $workdir_hi ]; then
    mkdir -p $workdir_hi;
  fi
  
  cd $workdir_hi
  
  # cp binaries into workdir_hi
  # change data.ctrl
  # cp xx_[ctrl] adjustments if iter > 0
  ${rootdir}/link_hires.bash $iter $ext2 $builddir_hi 

  #---  run  --------
  \rm -f mitgcmuv*
  cp -f ${builddir_hi}/mitgcmuv_ad ./
  cp -f ${builddir_hi}/Makefile ./
  
  set -x
  date > run.MITGCM.timing
  ./mitgcmuv_ad > stdout
  date >> run.MITGCM.timing
  cd ..

# --- 2.low-res adjoint run ---
  
  workdir_lo=/scratch/shoshi/labsea_MG/bathy_tests/run_adlo_2lev_seaice_it${ext2}_bad_bathy

  if [ ! -d $workdir_lo ]; then
    mkdir -p $workdir_lo;
  fi

  # create low-res xx_[ctrl]
  python3 ${rootdir}/make_cost_cp.py "$ext2" 

  cd $workdir_lo

  # cp binaries into workdir_lo
  # cp ONLINE low-res cost, misfit, barfiles, and xx_[ctrl]
  # create data.optim
  ${rootdir}/link_lores.bash $iter $workdir_hi $builddir_lo
  
  #---  run  --------
  \rm -f mitgcmuv*
  cp -f ${builddir_lo}/mitgcmuv_ad ./
  cp -f ${builddir_lo}/Makefile ./
  
  set -x
  date > run.MITGCM.timing
  ./mitgcmuv_ad > stdout
  date >> run.MITGCM.timing

  sed -i 's/4/0/g' divided.ctrl
  date > run.MITGCM.timing
  ./mitgcmuv_ad > stdout
  date >> run.MITGCM.timing
  cd ..


# --- 3. OPTIM ----------------
  cd ${optimdir}
  #bash reset.bash
  cp ${workdir_lo}/ecco_cost_MIT_CE_000.opt${ext2} ${optimdir} 
  cp ${workdir_lo}/ecco_ctrl_MIT_CE_000.opt${ext2} ${optimdir} 
  cp ${workdir_lo}/data.ctrl ${optimdir} 
  cp -f ${workdir_lo}/costfinal ${optimdir}
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

  dir_iter=${workdir_lo}/run_optim/+it${ext2}
  mkdir -p $dir_iter
  cp data.optim $dir_iter
  cp data.optim data.optim_${ext2}
  cp ecco_ctrl_MIT_CE_000.opt${ext2} $dir_iter
  cd ..

# --- 4. pack unpack -----------

  workdir_pup=/scratch/shoshi/labsea_MG/bathy_tests/run_adlo_2lev_seaice_packunpack_bad_bathy

  if [ ! -d $workdir_pup ]; then
    mkdir -p $workdir_pup;
  fi

  cd $workdir_pup

  # cp ecco*ctrl*iter from optim 
  # change data.ctrl to unpack=TRUE
  # change data to run for 1 timestep 
  ${rootdir}/link_packunpack.bash $ext2 $workdir_pup $optimdir $builddir_pup 

  #---  run  --------
  \rm -f mitgcmuv*
  cp -f ${builddir_pup}/mitgcmuv ./
  cp -f ${builddir_pup}/Makefile ./
  
  set -x
  date > run.MITGCM.timing
  ./mitgcmuv > stdout #2>&1 &

#  # Get the PID of the executable
#  EXEC_PID=$!
#  
#  # Monitor the log file in a loop using grep
#  while true; do
#      if grep -q "time_tsnumber" STDOUT.0000; then
#          echo "Pattern found, killing executable."
#          kill $EXEC_PID
#          break
#      fi
#      sleep 1  # Wait for 1 second before checking again
#  done
#  
#  # Optionally, wait for the executable to finish if not killed
#  wait $EXEC_PID

  date >> run.MITGCM.timing
  
  cd ..

# --- 5. interpolate adjustments to high-res -----------
echo $(printf "%04d" $((iter+1)))  # "000$((iter+1))"
python3 ${rootdir}/interp_xx_lores_to_hires_itX.py $(printf "%04d" $((iter+1))) #"000$((iter+1))" $interp_type

#  let iter=6
  let iter=iter+1
done

echo "DONE"
