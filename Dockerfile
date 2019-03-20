###########################################################
# This is the Dockerfile to build a machine with a bare-  #
# bones installation of the latest FSL (6.0).             #
###########################################################


# Use an official Python runtime as a parent image
FROM python:3.5-slim

## install:
# -curl, tar, unzip (to get the FSL distribution)
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    curl \
    tar \
    unzip \
  && apt-get clean -y && apt-get autoclean -y && apt-get autoremove -y


# Specify where to install packages:
ENV INSTALL_FOLDER=/usr/local/


###   Install FSL   ###

# The following gives you a clean install of FSL to run in a CLI

# install FSL 6.0.1:
# "fslinstaller.py" only works for python 2.X.
# We exclude atlases, etc, and gpu stuff (this image
#   does not have CUDA):
RUN curl -sSL https://fsl.fmrib.ox.ac.uk/fsldownloads/fsl-6.0.1-centos7_64.tar.gz | tar xz -C ${INSTALL_FOLDER} \
    --exclude='fsl/doc' \
    --exclude='fsl/data/first' \    
    --exclude='fsl/data/atlases' \
    --exclude='fsl/data/possum' \    
    --exclude='fsl/src' \    
    --exclude='fsl/extras/src' \    
    --exclude='fsl/bin/fslview*' \
    --exclude='fsl/bin/FSLeyes' \
    --exclude='fsl/bin/*_gpu*' \
    --exclude='fsl/bin/*_cuda*'
#    # Note: ${INSTALL_FOLDER}/fsl/data/standard is needed for functional processing

# Configure environment
ENV FSLDIR=${INSTALL_FOLDER}/fsl/ \
    FSLOUTPUTTYPE=NIFTI_GZ
# (Note: the following cannot be included in the same one-line with
#        the above, since it depends on the previous variables)
ENV PATH=${FSLDIR}/bin:$PATH \
    LD_LIBRARY_PATH=${FSLDIR}:${LD_LIBRARY_PATH}


# Overwrite the entrypoint of the base Docker image (python)
ENTRYPOINT ["/bin/bash"]