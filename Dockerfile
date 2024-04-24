# Default Gradescope Dockerfile

# Define base and a couple of tags
ARG BASE_REPO=gradescope/autograder-base
ARG TAG=latest
ARG VER=R2024a

FROM ${BASE_REPO}:${TAG}

# Import local files
ADD source /autograder/source
ADD matlab /matlab

RUN cp /autograder/source/run_autograder /autograder/run_autograder

RUN dos2unix /autograder/run_autograder /autograder/source/setup.sh
RUN chmod +x /autograder/run_autograder

RUN apt-get update && \
    apt-get install -y unzip && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN cd /matlab && \
    unzip matlab_${VER}_Linux.zip && \
    ./install -inputFile installer_input.txt && \
    cd /autograder/source