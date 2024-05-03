# To specify which MATLAB release to install in the container, edit the value of the MATLAB_RELEASE argument.
# Use lowercase to specify the release, for example: ARG MATLAB_RELEASE=r2021b
ARG MATLAB_RELEASE=r2024a

# Specify the list of products to install into MATLAB.
# If additional packages are necessary, specify them here
ARG MATLAB_PRODUCT_LIST="MATLAB"

# Specify MATLAB Install Location.
ARG MATLAB_INSTALL_LOCATION="/opt/matlab/${MATLAB_RELEASE}"

# Build from gradescope base
FROM gradescope/autograder-base:latest

# Load args into container
ARG MATLAB_RELEASE
ARG MATLAB_PRODUCT_LIST
ARG MATLAB_INSTALL_LOCATION
ARG LICENSE_SERVER

# Import local files
ADD source /autograder/source

# Copy run_autograder into proper location and make it executable
RUN cp /autograder/source/run_autograder /autograder/run_autograder
RUN dos2unix /autograder/run_autograder
RUN chmod +x /autograder/run_autograder

ENV DEBIAN_FRONTEND="noninteractive" TZ="Etc/UTC"

# Download necessary Matlab dependencies
RUN apt-get update
RUN apt-get install -y ca-certificates \
libasound2 \
libc6 \
libcairo-gobject2 \
libcairo2 \
libcap2 \
libcups2 \
libdrm2 \
libfontconfig1 \
libgbm1 \
libgdk-pixbuf-2.0-0 \
libgl1 \
libglib2.0-0 \
libgstreamer-plugins-base1.0-0 \
libgstreamer1.0-0 \
libgtk-3-0 \
libice6 \
libltdl7 \
libnspr4 \
libnss3 \
libpam0g \
libpango-1.0-0 \
libpangocairo-1.0-0 \
libpangoft2-1.0-0 \
libsndfile1 \
libudev1 \
libuuid1 \
libwayland-client0 \
libxcomposite1 \
libxcursor1 \
libxdamage1 \
libxfixes3 \
libxft2 \
libxinerama1 \
libxrandr2 \
libxt6 \
libxtst6 \
libxxf86vm1 \
locales \
locales-all \
make \
net-tools \
procps \
sudo \
unzip \
zlib1g

RUN apt-get clean && apt-get -y autoremove && rm -rf /var/lib/apt/lists/*

# Install Matlab
RUN wget -q https://www.mathworks.com/mpm/glnxa64/mpm \ 
    && chmod +x mpm \
    && sudo HOME=${HOME} ./mpm install \
    --release=${MATLAB_RELEASE} \
    --destination=${MATLAB_INSTALL_LOCATION} \
    --products ${MATLAB_PRODUCT_LIST} \
    || (echo "MPM Installation Failure. See below for more information:" && cat /tmp/mathworks_root.log && false) \
    && sudo rm -rf mpm /tmp/mathworks_root.log ${HOME}/.MathWorks \
    && sudo ln -s ${MATLAB_INSTALL_LOCATION}/bin/matlab /usr/local/bin/matlab