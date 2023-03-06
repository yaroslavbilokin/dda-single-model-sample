import torch
import os
from diffusers import pipelines as _pipelines, StableDiffusionPipeline
from getScheduler import getScheduler, DEFAULT_SCHEDULER

HF_AUTH_TOKEN = os.getenv("HF_AUTH_TOKEN")
PIPELINE = os.getenv("PIPELINE")

MODEL_IDS = [
    "prompthero/openjourney-v2",
]


def loadModel(model_id: str, load=True):
    print(("Loading" if load else "Downloading") + " model: " + model_id)

    pipeline = (
        StableDiffusionPipeline if PIPELINE == "ALL" else getattr(_pipelines, PIPELINE)
    )

    scheduler = getScheduler(model_id, DEFAULT_SCHEDULER, not load)

    model = pipeline.from_pretrained(
        model_id,
        # revision="fp32",
        torch_dtype=None,
        use_auth_token=HF_AUTH_TOKEN,
        scheduler=scheduler,
        local_files_only=load,
    )

    return model.to("cuda") if load else None
