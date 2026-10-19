"""
title: Image Studio
description: Rewrites a plain request ("a cute puppy") into a ComfyUI prompt + negative prompt with a local Ollama model, then generates the image.
"""

# Runs inside the ollama-webui container (installed by `make start-image`), so the
# open_webui imports only resolve there.

import json
import os

import httpx
from pydantic import BaseModel, Field

from open_webui.models.users import Users
from open_webui.routers.images import CreateImageForm, image_generations

REWRITE_SYSTEM_PROMPT = """You turn short image requests into prompts for a text-to-image diffusion model.

Return JSON with:
- "prompt": one paragraph (40-80 words) of plain descriptive language. Cover the subject and its details, setting, lighting, color palette, composition/camera framing, and style (photo, illustration, 3D render...). Keep everything the user asked for; add only details that make it look better. No lists, no quality tags like "8k, masterpiece".
- "negative_prompt": a short comma-separated list of things to avoid (e.g. blurry, distorted anatomy, extra limbs, watermark, text artifacts), tailored to the subject.

Rules:
- Never add text, words, letters, signs, captions, titles, logos, or book/poster/card layouts unless the user asks for them. Image models render these as gibberish.
- Never add subjects (people, animals, objects) the user didn't ask for.
- If the user already wrote a detailed prompt, keep it nearly verbatim."""

PROMPT_SCHEMA = {
    "type": "object",
    "properties": {
        # Ollama enforces maxLength in its output grammar; small models ignore length instructions
        "prompt": {"type": "string", "maxLength": 500},
        "negative_prompt": {"type": "string", "maxLength": 200},
    },
    "required": ["prompt", "negative_prompt"],
}


def message_text(message: dict) -> str:
    content = message.get("content", "")
    if isinstance(content, list):
        return " ".join(part.get("text", "") for part in content if part.get("type") == "text")
    return content


class Pipe:
    class Valves(BaseModel):
        OLLAMA_URL: str = Field(default=os.getenv("OLLAMA_BASE_URL", "http://ollama:11434"))
        REWRITE_MODEL: str = Field(default="llama3.2:3b", description="Ollama model that writes the image prompt (1b ignores the rewrite rules)")
        IMAGE_SIZE: str = Field(default="", description="WIDTHxHEIGHT; empty uses the Images setting")

    def __init__(self):
        self.valves = self.Valves()

    async def ollama_chat(self, messages: list[dict], schema: dict | None = None) -> str:
        payload = {"model": self.valves.REWRITE_MODEL, "messages": messages, "stream": False}
        if schema:
            payload["format"] = schema
        async with httpx.AsyncClient(timeout=300) as client:
            res = await client.post(f"{self.valves.OLLAMA_URL}/api/chat", json=payload)
            res.raise_for_status()
            return res.json()["message"]["content"]

    async def pipe(self, body: dict, __user__: dict, __request__, __event_emitter__=None, __task__=None, __metadata__=None):
        # Title/tag/follow-up tasks: answer with the text model instead of making an image
        if __task__:
            return await self.ollama_chat(body["messages"])

        async def status(description: str, done: bool = False):
            if __event_emitter__:
                await __event_emitter__({"type": "status", "data": {"description": description, "done": done}})

        request = next(message_text(m) for m in reversed(body["messages"]) if m["role"] == "user")

        await status("Writing prompt...")
        try:
            rewritten = json.loads(
                await self.ollama_chat(
                    [{"role": "system", "content": REWRITE_SYSTEM_PROMPT}, {"role": "user", "content": request}],
                    PROMPT_SCHEMA,
                )
            )
            prompt, negative = rewritten["prompt"].strip() or request, rewritten["negative_prompt"].strip()
        except Exception as e:
            await status(f"Prompt rewrite failed ({e}), using your message as-is")
            prompt, negative = request, ""

        await status("Generating image...")
        user = await Users.get_user_by_id(__user__["id"])
        metadata = __metadata__ or {}
        try:
            images = await image_generations(
                __request__,
                CreateImageForm(prompt=prompt, negative_prompt=negative, size=self.valves.IMAGE_SIZE or None),
                metadata={"chat_id": metadata.get("chat_id"), "message_id": metadata.get("message_id")},
                user=user,
            )
        except Exception as e:
            await status("Image generation failed", done=True)
            return f"Image generation failed: {e}\n\n**Prompt:** {prompt}\n\n**Negative prompt:** {negative or '(none)'}"

        if __event_emitter__:
            await __event_emitter__({"type": "files", "data": {"files": [{"type": "image", **image} for image in images]}})
        await status("Image created", done=True)
        return f"**Prompt:** {prompt}\n\n**Negative prompt:** {negative or '(none)'}"
