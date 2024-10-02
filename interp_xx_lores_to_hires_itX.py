import numpy as np
from scipy.interpolate import griddata, Rbf 
import sys
sys.path.append('/home/shoshi/MITgcm_c68r/MITgcm/utils/python/MITgcmutils')
from MITgcmutils import rdmds

nx=20
ny=16
nz=21

factor = 4 # lowres * factor = hires

nxh=nx*factor
nyh=ny*factor

#dirroot='/home/shoshi/MITgcm_c68r/MITgcm/verification/lab_sea/'
dirroot='/scratch/shoshi/labsea_MG/bathy_tests/'

#iter = '0000'
iter = sys.argv[1] # sys.argv[0] is name of python file
print(iter)

#dirrun_lr = dirroot + 'grid_lores/'
#dirrun_hr = dirroot + 'grid_hires_linear/'
dirrun_lr = dirroot + 'run_adlo_2lev_seaice_it0000_bad_bathy/'
dirrun_hr = dirroot + 'run_adhi_2lev_seaice_it0000_bad_bathy/'

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

# use linear interpolation, then have the choice between rbf and nearest to fix edges
# use rbf for now

def linear_interp(xx_lr, dim):

    points = np.array([xc_lr.ravel(), yc_lr.ravel()]).T
    
    xx_hr = np.zeros((xx_lr.shape[0], nyh, nxh))
    for i in range(xx_lr.shape[0]):
        
        values = xx_lr[i,:,:].ravel()
    
        # Create a mask to filter out NaN values in the low-resolution data
        mask = ~np.isnan(values)
    
        # Interpolate onto the high-resolution grid using linear interpolation
        tmp = griddata(points[mask], values[mask], (xc_hr, yc_hr), method='linear')
    
        # Identify where the high-resolution grid still has NaN values after linear interpolation
        nan_mask = np.isnan(tmp)
    
        # Apply RBF interpolation to fill the remaining NaN values
        if np.any(nan_mask):
            xc_hr_flat = xc_hr[nan_mask]
            yc_hr_flat = yc_hr[nan_mask]
        
            rbf = Rbf(points[mask][:, 0], points[mask][:, 1], values[mask], function='linear')
            tmp[nan_mask] = rbf(xc_hr_flat, yc_hr_flat)

        # or apply nn interpolation to fill the remaining NaN values
        # tmp[nan_mask] = griddata(points[mask], values[mask], (xc_hr[nan_mask], yc_hr[nan_mask]), method='nearest')
    
        # set floor and ceiling to that of low-res  
        lmin = np.min(xx_lr[i,:,:])
        lmax = np.max(xx_lr[i,:,:])
        tmp = np.clip(tmp, lmin, lmax)

        if dim == 2:
            xx_hr[i,:,:] = tmp * hfacc_hr[0,:,:]
        elif dim == 3:
            xx_hr[i,:,:] = tmp * hfacc_hr[i,:,:]

    return xx_hr



def write_float64(fout,fld):
    with open(fout, 'wb') as f:
        np.array(fld, dtype=">f8").tofile(f)


xx_theta_hr = linear_interp(xx_theta, 3)
xx_atemp_hr = linear_interp(xx_atemp, 2)

xx_theta_hr[np.isnan(xx_theta_hr)] = 0
xx_atemp_hr[np.isnan(xx_atemp_hr)] = 0

write_float64(dirrun_pup + 'xx_theta_hr.000000' + iter + '.data', xx_theta_hr)
write_float64(dirrun_pup + 'xx_atemp_hr.000000' + iter + '.data', xx_atemp_hr)

