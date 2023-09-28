#!/usr/bin/bash
#

tar -xf gamess-current.tar.gz

cd gamess

GMS_PATH="$PWD"

#
# Download libxc as the script does not work on LUMI
#

libxc_folder=libxc
libxc_MAJOR=5
libxc_MINOR=1
libxc_PATCH=7
libxc_archive=libxc-${libxc_MAJOR}.${libxc_MINOR}.${libxc_PATCH}.tar.gz

mkdir -p ${GMS_PATH}/3rd-party/${libxc_folder}

curl https://gitlab.com/libxc/libxc/-/archive/${libxc_MAJOR}.${libxc_MINOR}.${libxc_PATCH}/$libxc_archive -o ${GMS_PATH}/$libxc_archive
tar -xzf ${GMS_PATH}/$libxc_archive -C ${GMS_PATH}/3rd-party/${libxc_folder} --strip-components=1

#
# Download the MDI support
# Based on ./tools/mdi/download-mdi.csh
# Needs make libmdi before make modules
#

mdi_folder=mdi
mdi_MAJOR=1
mdi_MINOR=2
mdi_PATCH=12

mkdir -p ${GMS_PATH}/3rd-party/${mdi_folder}

mdi_archive=v${mdi_MAJOR}.${mdi_MINOR}.${mdi_PATCH}.tar.gz

curl -L https://github.com/MolSSI-MDI/MDI_Library/archive/refs/tags/$mdi_archive -o ${GMS_PATH}/$mdi_archive
tar -xzf ${GMS_PATH}/$mdi_archive -C ${GMS_PATH}/3rd-party/${mdi_folder} --strip-components=1

# VeraChem will not work


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
make -j 32 libxc
make -j 32 libmdi
make -j 32 modules
