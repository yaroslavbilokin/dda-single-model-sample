# Single local model

Diffusers / Stable Diffusion in docker with a REST API, supporting various models, pipelines & schedulers.

Based on [kiri-art/docker-diffusers-api](https://github.com/kiri-art/docker-diffusers-api) and rewrite for uploading models on build instead of uploading on each request.
Reduces query time by ~80 percent.

Copyright (c) Gadi Cohen, 2022.  MIT Licensed.
Please give credit and link back to this repo if you use it in a public project.

## Features

* Pipelines: txt2img, img2img and inpainting in a single container
* Models: stable-diffusion, waifu-diffusion, openjourney and easy to add others (e.g. jp-sd)
* All model inputs supported, including setting nsfw filter per request
* *Permute* base config to multiple forks based on yaml config with vars
* Optionally send signed event logs / performance data to a REST endpoint
* Can automatically download a checkpoint file and convert to diffusers.

## Usage:

Most of the configuration happens via docker build variables.  You can
see all the options in the [Dockerfile](./Dockerfile), and edit them
there directly, or set via docker command line or e.g. Banana's dashboard
UI once support for build variables land (any day now).

If you're only deploying one container, that's all you need!

Lastly, there's an option to set `MODEL_ID=ALL`, and *all* models will
be downloaded, and switched at request time (great for dev, useless for
serverless).

## Running locally / development:

**Building**

1. Set `HF_AUTH_TOKEN` environment var if you haven't set it elsewhere.
2. Set `MODEL_ID` environment var to upload preferred model on build
3. `docker build -t container_name .`

**Running**

1. `docker run -d -p 8000:8000 --gpus all container_name`
2. Note: the `-it` is optional but makes it alot quicker/easier to stop the
    container using `Ctrl-C`.
3. If you get a `CUDA initialization: CUDA unknown error` after suspend,
    just stop the container, `rmmod nvidia_uvm`, and restart.

## Sending requests

The container expects an `HTTP POST` request with the following JSON body:

```json
{
  "modelInputs": {
    "prompt": "Super dog",
    "num_inference_steps": 50,
    "guidance_scale": 7.5,
    "width": 512,
    "height": 512,
    "seed": 3239022079
  },
  "callInputs": {
    "MODEL_ID": "prompthero/openjourney-v2",
    "PIPELINE": "StableDiffusionPipeline",
    "SCHEDULER": "LMSDiscreteScheduler",
    "safety_checker": true
  }
}
```

## Troubleshooting

* **403 Client Error: Forbidden for url**

  Make sure you've accepted the license on the model card of the HuggingFace model
  specified in `MODEL_ID`, and that you correctly passed `HF_AUTH_TOKEN` to the
  container.

## Adding other Models

1. For a diffusers model, simply set the `MODEL_ID` docker build variable to the name
  of the model hosted on HuggingFace, and it will be downloaded automatically at
  build time.

## Acknowledgements

Originally based on https://github.com/bananaml/serverless-template-stable-diffusion.
