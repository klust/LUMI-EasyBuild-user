#!/usr/bin/bash
#

tar -xf gamess-current.tar.gz

cd gamess

GMS_PATH="$PWD"





#
# Compile environment
#

module load LUMI/23.03 partition/C
module load cpeCray/23.03
module load buildtools/23.03
#module load Boost/1.81.0-cpeCray-23.03
#module load Eigen/3.4.0

#
# Build the software
#

make -j 32 ddi
make -j 32
