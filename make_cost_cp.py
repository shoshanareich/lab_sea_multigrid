import numpy as np
from scipy.interpolate import griddata, LinearNDInterpolator, NearestNDInterpolator
from scipy.ndimage import generic_filter
import sys
sys.path.append('/home/shoshi/MITgcm_c68r/MITgcm/utils/python/MITgcmutils')
from MITgcmutils import rdmds

nx=20
ny=16
nz=21

factor = 4 # lowres * factor = hires

nxh=nx*factor
nyh=ny*factor

dirroot='/home/shoshi/MITgcm_c68r/MITgcm/verification/lab_sea/'

#iter = '0000'
iter = sys.argv[1] # sys.argv[0] is name of python file
#interp = sys.argv[2]
print(iter)
#print(interp)
interp = 'linear'

dirrun_lr = dirroot + 'grid_lores/'
dirrun_hr = dirroot + 'grid_hires_linear/'

#dirrun_pup = dirroot + 'run_adlo_noseaice_costsst_' + interp + '_packunpack_tape24hr/'
dirrun_pup = '/scratch/shoshi/labsea_MG/bathy_tests/run_adlo_2lev_seaice_packunpack_bad_bathy/'

# read in unpacked low-res adjustments
xx_theta = rdmds(dirrun_pup + 'xx_theta.000000' + iter).reshape(nz, ny, nx)
xx_atemp = rdmds(dirrun_pup + 'xx_atemp.000000' + iter).reshape(8,ny, nx)


# read in high-res grid and low-res grid
xc_lr = rdmds(dirrun_lr + 'XC')
yc_lr = rdmds(dirrun_lr + 'YC')

xc_hr = rdmds(dirrun_hr + 'XC')
yc_hr = rdmds(dirrun_hr + 'YC')

## NEW BATHY
# hfacc_hr = rdmds(dirrun_hr + 'hFacC')
hfacc_hr = rdmds('/scratch/shoshi/labsea_MG/bathy_tests/run_adhi_2lev_seaice_it0000_new_bathy/hFacC')

# now we have the choice between interpolating lores xx to hires xx using
# linear or nearest.  An used 'linear' for now

# Replace NaNs with the mean of their neighbors
def inpaint_nans(arr):
    isnan = np.isnan(arr)
    arr[isnan] = generic_filter(arr, np.nanmean, size=3)[isnan] # average of 3x3 square of points
    return arr

# fix weird border anns
def fill_border_nans(arr):
    # Fill NaNs in rows
    for i in range(arr.shape[0]):
        row_non_nans = np.where(~np.isnan(arr[i, :]))[0]
        if len(row_non_nans) > 0:
            if np.isnan(arr[i, 0]):
                arr[i, 0] = arr[i, row_non_nans[0]]
            if np.isnan(arr[i, -1]):
                arr[i, -1] = arr[i, row_non_nans[-1]]
    
    # Fill NaNs in columns
    for j in range(arr.shape[1]):
        col_non_nans = np.where(~np.isnan(arr[:, j]))[0]
        if len(col_non_nans) > 0:
            if np.isnan(arr[0, j]):
                arr[0, j] = arr[col_non_nans[0], j]
            if np.isnan(arr[-1, j]):
                arr[-1, j] = arr[col_non_nans[-1], j]

    return arr

def linear_interp(xx_lr):

    xx_hr = np.zeros((xx_lr.shape[0], nyh, nxh))
    for i in range(xx_lr.shape[0]):
        
        # linear interpolation
        tmp = griddata((xc_lr.ravel(), yc_lr.ravel()), xx_lr[i,:,:].ravel(), (xc_hr.ravel(), yc_hr.ravel()), method='linear')
        tmp = tmp.reshape(xc_hr.shape[0], xc_hr.shape[1])
        
        # handle NaNs
        tmp = inpaint_nans(tmp)
        
        # set floor and ceiling to that of low-res  
        lmin = np.min(xx_lr[i,:,:])
        lmax = np.max(xx_lr[i,:,:])
        tmp = np.clip(tmp, lmin, lmax)

        tmp = fill_border_nans(tmp)
        
        xx_hr[i,:,:] = tmp

    return xx_hr


# try nearest neighbor interpolation
def nearest_interp(xx_lr):

    xx_hr = np.zeros((xx_lr.shape[0], nyh, nxh))
    for i in range(xx_lr.shape[0]):
        
        # linear interpolation
        tmp = griddata((xc_lr.ravel(), yc_lr.ravel()), xx_lr[i,:,:].ravel(), (xc_hr.ravel(), yc_hr.ravel()), method='nearest')
        tmp = tmp.reshape(xc_hr.shape[0], xc_hr.shape[1])
        
        # handle NaNs
        tmp = inpaint_nans(tmp)
        
        # set floor and ceiling to that of low-res  
        lmin = np.min(xx_lr[i,:,:])
        lmax = np.max(xx_lr[i,:,:])
        tmp = np.clip(tmp, lmin, lmax)
        
        xx_hr[i,:,:] = tmp

    return xx_hr

def write_float64(fout,fld):
    with open(fout, 'wb') as f:
        np.array(fld, dtype=">f8").tofile(f)



if interp == 'linear':
    
    # linear interpolation
    xx_theta_hr = linear_interp(xx_theta)*hfacc_hr
    xx_atemp_hr = linear_interp(xx_atemp)*hfacc_hr[0,:,:]

    xx_theta_hr[np.isnan(xx_theta_hr)] = 0
    xx_atemp_hr[np.isnan(xx_atemp_hr)] = 0

    write_float64(dirrun_pup + 'xx_theta_hr.000000' + iter + '.data', xx_theta_hr)
    write_float64(dirrun_pup + 'xx_atemp_hr.000000' + iter + '.data', xx_atemp_hr)

elif interp == 'nearest':
    
    # nn interpolation
    xx_theta_hr = nearest_interp(xx_theta)*hfacc_hr
    xx_atemp_hr = nearest_interp(xx_atemp)*hfacc_hr[0,:,:]

    xx_theta_hr[np.isnan(xx_theta_hr)] = 0
    xx_atemp_hr[np.isnan(xx_atemp_hr)] = 0

    write_float64(dirrun_pup + 'xx_theta_nearest.000000' + iter + '.data', xx_theta_hr)
    write_float64(dirrun_pup + 'xx_atemp_nearest.000000' + iter + '.data', xx_atemp_hr)

