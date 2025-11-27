import shutil
import tempfile

from fastapi import FastAPI, File, Form, UploadFile
from fastapi.responses import JSONResponse
from faster_whisper import WhisperModel
import uvicorn

app = FastAPI(title="Lobna Local STT")
_models_cache = {}


def _get_model(name: str) -> WhisperModel:
  if name not in _models_cache:
    _models_cache[name] = WhisperModel(name, device="cpu", compute_type="int8")
  return _models_cache[name]


@app.post("/transcribe")
async def transcribe(
  audio: UploadFile = File(...),
  model: str = Form("small"),
  locale: str = Form("ar")
):
  with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
    shutil.copyfileobj(audio.file, tmp)
    tmp_path = tmp.name

  whisper = _get_model(model)
  segments, info = whisper.transcribe(tmp_path, language=locale.split("_")[0])
  text = " ".join(segment.text.strip() for segment in segments).strip()
  return JSONResponse({"text": text, "language": info.language})


if __name__ == "__main__":
  uvicorn.run("local_stt_server:app", host="0.0.0.0", port=8080, reload=False)

