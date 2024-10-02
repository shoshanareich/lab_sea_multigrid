import numpy as np
import sys
sys.path.append('/home/shoshi/MITgcm_c68r/MITgcm/utils/python/MITgcmutils')
from MITgcmutils import rdmds

nx=20
ny=16
nz=21

factor = 4 # lowres * factor = hires

nxh=nx*factor
nyh=ny*factor

dirroot='/scratch/shoshi/labsea_MG/bathy_tests/'

#iter = '0000'
iter = sys.argv[1] # sys.argv[0] is name of python file
print(iter)

dirrun_lr = dirroot + '/run_adlo_2lev_seaice_it' + iter + '_good_bathy_2/'
dirrun_hr = dirroot + '/run_adhi_2lev_seaice_it' + iter + '_good_bathy_2/'


## NEW BATHY
# hfacc_hr = rdmds(dirrun_hr + 'hFacC')
hfacc_lr = rdmds('/scratch/shoshi/labsea_MG/bathy_tests/run_adlo_2lev_seaice_it0000_good_bathy/hFacC')

def bin_avg(fld):
    fld = fld.reshape(fld.shape[0], ny, factor, nx, factor)
    fld_lr = np.nanmean(fld, axis=(2,4))
    return fld_lr

def write_float64(fout,fld):
    with open(fout, 'wb') as f:
        np.array(fld, dtype=">f8").tofile(f)


# read in high-res 
xx_theta = rdmds(dirrun_hr + 'xx_theta.000000' + iter)
xx_atemp = rdmds(dirrun_hr + 'xx_atemp.000000' + iter)

adxx_theta = rdmds(dirrun_hr + 'adxx_theta.000000' + iter)
adxx_atemp = rdmds(dirrun_hr + 'adxx_atemp.000000' + iter)

m_sst_day = rdmds(dirrun_hr + 'm_sst_day.000000' + iter)
adm_sst_day = rdmds(dirrun_hr + 'adm_sst_day.000000' + iter)

# bin-avg to low-res
xx_theta_lr = bin_avg(xx_theta) * hfacc_lr
xx_atemp_lr = bin_avg(xx_atemp) * hfacc_lr[0,:,:]

adxx_theta_lr = bin_avg(adxx_theta) * hfacc_lr
adxx_atemp_lr = bin_avg(adxx_atemp) * hfacc_lr[0,:,:]

m_sst_day_lr = bin_avg(m_sst_day) * hfacc_lr[0,:,:]
adm_sst_day_lr = bin_avg(adm_sst_day) * hfacc_lr[0,:,:]

write_float64(dirrun_lr + 'xx_theta.000000' + iter + '.data', xx_theta_lr)
write_float64(dirrun_lr + 'xx_atemp.000000' + iter + '.data', xx_atemp_lr)
write_float64(dirrun_lr + 'adxx_theta.000000' + iter + '.data', adxx_theta_lr)
write_float64(dirrun_lr + 'adxx_atemp.000000' + iter + '.data', adxx_atemp_lr)
write_float64(dirrun_lr + 'm_sst_day.000000' + iter + '.data', m_sst_day_lr)
write_float64(dirrun_lr + 'adm_sst_day.000000' + iter + '.data', adm_sst_day_lr)


