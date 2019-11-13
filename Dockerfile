###########################################################
# This is the Dockerfile to build a machine with a bare-  #
# bones installation of the latest FSL (6.0).             #
###########################################################

ARG DEBIAN_VERSION=buster
ARG BASE_PYTHON_VERSION=3.8
# (don't use simply PYTHON_VERSION bc. it's an env variable)

# Use an official Python runtime as a parent image
FROM python:${BASE_PYTHON_VERSION}-slim-${DEBIAN_VERSION}

## install:
# -curl, tar, unzip (to get the FSL distribution)
# -bzip2 (to install the fslpython tools)
# -libquadmath0 (needed to run many FSL commands )
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    curl \
    libquadmath0 \
  && apt-get clean -y && apt-get autoclean -y && apt-get autoremove -y


# Specify where to install packages:
ENV INSTALL_FOLDER=/usr/local/


###   Install FSL   ###

# The following gives you a clean install of FSL to run in a CLI

# install FSL 6.0.2:
# "fslinstaller.py" only works for python 2.X.
# We exclude atlases, etc, and gpu stuff (this image
#   does not have CUDA):
RUN curl -sSL https://fsl.fmrib.ox.ac.uk/fsldownloads/fsl-6.0.2-centos7_64.tar.gz | tar xz -C ${INSTALL_FOLDER} \
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

# Install fslpython
# (Potentially, we could also not install "vtk")
# Also, you can probably do "${FSLDIR}/fslpython/bin/conda clean --all"
RUN sed -i -e "/fsleyes/d" -e "/wxpython/d" ${FSLDIR}/etc/fslconf/fslpython_environment.yml && \
    ${FSLDIR}/etc/fslconf/fslpython_install.sh && \
    find ${FSLDIR}/fslpython/envs/fslpython/lib/python3.7/site-packages/ -type d -name "tests"  -print0 | xargs -0 rm -r && \
    ${FSLDIR}/fslpython/bin/conda clean --all

# Overwrite the entrypoint of the base Docker image (python)
ENTRYPOINT ["/bin/bash"]
