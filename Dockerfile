###########################################################
# This is the Dockerfile to build a machine with a bare-  #
# bones installation of the latest FSL (6.0).             #
###########################################################

###   Start by creating a "builder"   ###

ARG DEBIAN_VERSION=buster
ARG BASE_PYTHON_VERSION=3.8
# (don't use simply PYTHON_VERSION bc. it's an env variable)
ARG FSL_VERSION=6.0.4

# Use an official Python runtime as a parent image
FROM python:${BASE_PYTHON_VERSION}-slim-${DEBIAN_VERSION} as builder

## install:
# -curl (to get the FSL distribution)
# -libquadmath0 (needed to run many FSL commands )
# -bc
# -dc
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    curl \
    libquadmath0 \
    bc \
    dc \
  && apt-get clean -y && apt-get autoclean -y && apt-get autoremove -y


# Specify where to install packages:
ENV INSTALL_FOLDER=/usr/local/


###   Install FSL   ###

# The following gives you a clean install of FSL to run in a CLI

# install FSL:
# "fslinstaller.py" only works for python 2.X.
# We exclude atlases, etc, and gpu stuff (this image
#   does not have CUDA):
# This makes the BASE_PYTHON_VERSION available inside this stage
ARG FSL_VERSION
RUN curl -sSL https://fsl.fmrib.ox.ac.uk/fsldownloads/fsl-${FSL_VERSION}-centos7_64.tar.gz | tar xz -C ${INSTALL_FOLDER} \
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
RUN sed -i -e "/fsleyes/d" -e "/wxpython/d" ${FSLDIR}/etc/fslconf/fslpython_environment.yml && \
    sed -i -e "s/repo.continuum.io/repo.anaconda.com/" ${FSLDIR}/etc/fslconf/fslpython_install.sh && \
    ${FSLDIR}/etc/fslconf/fslpython_install.sh && \
    find ${FSLDIR}/fslpython/envs/fslpython/lib/python3.7/site-packages/ -type d \( \
        -name "tests" \
	-o -name "test_files" \
	-o -name "test_data" \
	-o -name "sample_data" \
    \) -print0 | xargs -0 rm -r && \
    for pkg in botocore pylint awscli jedi PyQt5 skimage/data tvtk; do \
      rm -fr ${FSLDIR}/fslpython/envs/fslpython/lib/python3.7/site-packages/$pkg; \
    done && \
    rm -r ${FSLDIR}/fslpython/pkgs/* && \
    for d in example resources/testimage resources/fsl; do \
      rm -r ${FSLDIR}/fslpython/envs/fslpython/lib/python3.7/site-packages/tirl/share/$d; \
    done && \
    rm -r ${FSLDIR}/fslpython/envs/fslpython/bin/pandoc* \
          ${FSLDIR}/fslpython/envs/fslpython/bin/qmake && \
    rm -r ${FSLDIR}/fslpython/envs/fslpython/include/qt \
          ${FSLDIR}/fslpython/envs/fslpython/include/vtk* && \
    for d in doc qt/3rd_party_licenses gir-1.0; do \
      rm -r ${FSLDIR}/fslpython/envs/fslpython/share/$d; \
    done && \
    rm -r ${FSLDIR}/fslpython/envs/fslpython/translations/qt* && \
    for t in imcp imglob immv; do \
      ln -s ${FSLDIR}/fslpython/envs/fslpython/bin/${t} ${FSLDIR}/bin/ ; \
    done && \
    ${FSLDIR}/fslpython/bin/conda clean --all

RUN rm -r ${FSLDIR}/fslpython/envs/fslpython/resources/qtwebengine* \
          ${FSLDIR}/fslpython/envs/fslpython/conda-meta/vtk* \
          ${FSLDIR}/fslpython/envs/fslpython/lib/libQt5* \
          ${FSLDIR}/fslpython/envs/fslpython/lib/cmake \
          ${FSLDIR}/fslpython/envs/fslpython/lib/libavcodec.a

RUN for l in libopenblas libopenblas64 libopenblas64_ libopenblaso libopenblaso64 libopenblasp libopenblasp64 libopenblasp64_; do \
    # if they are the same, delete and link: \
    diff ${FSLDIR}/lib/${l}.so ${FSLDIR}/lib/${l}.so.0 && rm ${FSLDIR}/lib/${l}.so && ln -s ./${l}.so.0 ${FSLDIR}/lib/${l}.so ; \
    diff ${FSLDIR}/lib/${l}.so.0 ${FSLDIR}/lib/${l}-r0.3.3.so && rm ${FSLDIR}/lib/${l}.so.0 && ln -s ./${l}-r0.3.3.so ${FSLDIR}/lib/${l}.so.0 ; \
done && \
  rm -r ${FSLDIR}/lib/libbedpostx_cuda.so && \
  rm -r ${FSLDIR}/lib/libvtk* ${FSLDIR}/lib/libqwt.* ${FSLDIR}/lib/libfslvtkio.*

#############

###  Now, get a new machine with only the essentials  ###
FROM python:${BASE_PYTHON_VERSION}-slim-${DEBIAN_VERSION} as Application

# This makes the BASE_PYTHON_VERSION available inside this stage
ARG BASE_PYTHON_VERSION
ENV PYTHON_LIB_PATH=/usr/local/lib/python${BASE_PYTHON_VERSION}

ENV FSLDIR=/usr/local/fsl/ \
    FSLOUTPUTTYPE=NIFTI_GZ
ENV PATH=${FSLDIR}/bin:$PATH \
    LD_LIBRARY_PATH=${FSLDIR}:${LD_LIBRARY_PATH}

# Copy system binaries and libraries:
COPY --from=builder ./lib/x86_64-linux-gnu/     /lib/x86_64-linux-gnu/
COPY --from=builder ./usr/lib/x86_64-linux-gnu/ /usr/lib/x86_64-linux-gnu/
COPY --from=builder ./usr/bin/                  /usr/bin/
COPY --from=builder ./usr/local/bin/           /usr/local/bin/
# COPY --from=builder ./${PYTHON_LIB_PATH}/site-packages/      ${PYTHON_LIB_PATH}/site-packages/

# Copy $FSLDIR:
COPY --from=builder ./${FSLDIR}/  ${FSLDIR}/

## Copy an extra library needed by FSL:
#COPY --from=builder ./usr/lib/x86_64-linux-gnu/libquadmath.so.0     \
#                    ./usr/lib/x86_64-linux-gnu/libquadmath.so.0.0.0 \
#                                    /usr/lib/x86_64-linux-gnu/


# Overwrite the entrypoint of the base Docker image (python)
ENTRYPOINT ["/bin/bash"]
