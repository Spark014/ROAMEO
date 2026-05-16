import os

import google.generativeai as genai

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

_API_KEY = os.getenv("GEMINI_API_KEY")
_MODEL_NAME = os.getenv("GEMINI_MODEL", "gemini-1.5-pro")
_model = None


def _get_model():
    global _model
    if _model is not None:
        return _model
    if not _API_KEY:
        raise RuntimeError(
            "GEMINI_API_KEY environment variable is required for Gemini calls."
        )
    genai.configure(api_key=_API_KEY)
    _model = genai.GenerativeModel(_MODEL_NAME)
    return _model


def generate(prompt: str) -> str:
    response = _get_model().generate_content(prompt)
    return response.text


if __name__ == "__main__":
    print(generate("Explain how AI works"))
