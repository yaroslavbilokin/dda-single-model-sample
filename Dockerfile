ARG FROM_IMAGE="gadicc/diffusers-api-base:python3.9-pytorch1.12.1-cuda11.6-xformers"
# You only need the -banana variant if you need banana's optimization
# i.e. not relevant if you're using RUNTIME_DOWNLOADS
# ARG FROM_IMAGE="gadicc/python3.9-pytorch1.12.1-cuda11.6-xformers-banana"
FROM ${FROM_IMAGE} as base
ENV FROM_IMAGE=${FROM_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive

FROM base AS patchmatch
ARG USE_PATCHMATCH=0
WORKDIR /tmp
COPY scripts/patchmatch-setup.sh .
RUN sh patchmatch-setup.sh

FROM base as output
RUN mkdir /api
WORKDIR /api

ADD requirements.txt requirements.txt
RUN pip3 install -r requirements.txt

RUN git clone https://github.com/huggingface/diffusers && cd diffusers && git checkout 5e5ce13e2f89ac45a0066cb3f369462a3cf1d9ef
WORKDIR /api
RUN pip install -e diffusers

# We add the banana boilerplate here
ADD server.py .
EXPOSE 8000

# Dev: docker build --build-arg HF_AUTH_TOKEN=${HF_AUTH_TOKEN} ...
# Banana: currently, comment out ARG and set by hand ENV line.
ARG HF_AUTH_TOKEN="HF_AUTH_TOKEN"
ENV HF_AUTH_TOKEN=${HF_AUTH_TOKEN}

# MODEL_ID, can be any of:
# 1) Hugging face model name
# 2) A directory containing a diffusers model
# 3) Your own unique model id if using CHECKPOINT_URL below.
# 4) "ALL" to download all known models (useful for dev)
ARG MODEL_ID="MODEL_ID"
ENV MODEL_ID=${MODEL_ID}

# ARG PIPELINE="StableDiffusionInpaintPipeline"
ARG PIPELINE="ALL"
ENV PIPELINE=${PIPELINE}

COPY root-cache/huggingface /root/.cache/huggingface
COPY root-cache/checkpoints /root/.cache/checkpoints
RUN du -sh /root/.cache/*

# If set, it will be downloaded and converted to diffusers format, and
# saved in a directory with same MODEL_ID name to be loaded by diffusers.
ARG CHECKPOINT_URL=""
ENV CHECKPOINT_URL=${CHECKPOINT_URL}
ADD download-checkpoint.py .
RUN python3 download-checkpoint.py
ADD convert-to-diffusers.py .
RUN python3 convert-to-diffusers.py
# RUN rm -rf checkpoints

# Add your model weight files 
# (in this case we have a python script)
ADD getScheduler.py .
ADD loadModel.py .
ADD download.py .
RUN python3 download.py

# Deps for RUNNING (not building) earlier options
ARG USE_PATCHMATCH=0
RUN if [ "$USE_PATCHMATCH" = "1" ] ; then apt-get install -yqq python3-opencv ; fi
COPY --from=patchmatch /tmp/PyPatchMatch PyPatchMatch

# Add your custom app code, init() and inference()
ADD send.py .
ADD app.py .

CMD python3 -u server.py

