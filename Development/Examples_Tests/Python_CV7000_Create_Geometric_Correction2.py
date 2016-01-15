from register_virtual_stack import Register_Virtual_Stack_MT
 
# source directory
source_dir = "C:\\Users\\stoeter\\Documents\\Temp\\sequence_GreinerGlassPlate_GSP_500nm_beads_H12_T0001F001_raw_xx_plane6\\"
# output directory
target_dir = "C:\\Users\\stoeter\\Documents\\Temp\\result\\"
# transforms directory
transf_dir = "C:\\Users\\stoeter\\Documents\\Temp\\transform\\"
# reference image
reference_name = "GreinerGlassPlate_GSP_500nm_beads_H12_T0001F001_raw_01_plane6.tif"
# shrinkage option (false)
use_shrinking_constraint = 0
 
p = Register_Virtual_Stack_MT.Param()
# The "maximum image size":
p.sift.maxOctaveSize = 2800
# The "inlier ratio":
p.minInlierRatio = 0.05
# Implemented transformation models for choice
# 0=TRANSLATION, 1=RIGID, 2=SIMILARITY, 3=AFFINE, 4=ELASTIC, 5=MOVING_LEAST_SQUARES
p.registrationModelIndex = 3
# Implemented transformation models for choice
# 0=TRANSLATION, 1=RIGID, 2=SIMILARITY, 3=AFFINE
p.featuresModelIndex = 3 
 
Register_Virtual_Stack_MT.exec(source_dir, target_dir, transf_dir, reference_name, p, use_shrinking_constraint)