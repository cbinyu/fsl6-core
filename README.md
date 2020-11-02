# fsl6-core

[![Docker image](https://img.shields.io/badge/docker-cbinyu%2Ffsl6--core-brightgreen?logo=docker&style=flat)](https://hub.docker.com/r/cbinyu/fsl6-core/tags/)
[![DOI](https://zenodo.org/badge/176756097.svg)](https://zenodo.org/badge/latestdoi/176756097)

Dockerfile for a bare-bones installation of FSL 6.0

It doesn't include:
- most of the atlases
- gpu tools
- Fsleyes

Although smaller in size than a full install of FSL, it still is huge (~9.5 GB).

It is intended as a `base` for building other docker images, by copying from `fsl6-core` just the tools needed (see this [`Dockerfile`](https://github.com/cbinyu/pydeface/blob/master/Dockerfile) as an example).


By using this software you agree to [FSL's license](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Licence)
