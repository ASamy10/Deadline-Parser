# Deadline-Parser: Flan-T5 Task & Deadline Extractor ⏰

[![Python](https://img.shields.io/badge/Python-3.11-3776AB?style=flat-square&logo=python&logoColor=white)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.110+-009688?style=flat-square&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Hugging Face](https://img.shields.io/badge/%F0%9F%A4%97%20Hugging%20Face-Transformers-yellow?style=flat-square)](https://huggingface.co/)
[![PyTorch](https://img.shields.io/badge/PyTorch-2.2+-EE4C2C?style=flat-square&logo=pytorch&logoColor=white)](https://pytorch.org/)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=flat-square&logo=docker&logoColor=white)](https://www.docker.com/)

An end-to-end NLP microservice powered by a fine-tuned **Google Flan-T5-Base** model that transforms unstructured, informal communications (emails, chats, and mixed-language project messages) into canonical **action items**, **deadlines**, and **ISO-8601 calendar timestamps**.

---

## 📌 Problem & Motivation

In fast-paced technical and startup environments, actionable deadlines are buried inside conversational emails with colloquialisms, slang, and code-switching (e.g., *"Hey yalla, we gotta submit the source code by tomorrow by EOD, ASAP!"*).

Standard Extractive Named Entity Recognition (NER) fails because:
1. It extracts exact token spans, yielding messy verbs and incomplete clauses.
2. It cannot normalize relative phrases (*"in 3 days"*, *"tomorrow afternoon"*) into actionable timestamps.
3. Commercial LLMs (OpenAI, Anthropic) pose recurring per-token costs and enterprise data privacy concerns.

**Deadline-Parser** solves this with a lightweight (~250M parameter) self-hosted Sequence-to-Sequence transformer coupled with a deterministic temporal resolution engine.

---

## 🏗 System Architecture

```
[ Unstructured Email / Message ]
              │
              ▼
   [ FastAPI Microservice ] ───► [ Reference Timestamp ]
              │                               │
              ▼                               │
  [ Flan-T5-Base Seq2Seq ]                    │
  (extract task and deadline)                 │
              │                               │
              ▼                               │
"Task: Submit code | Deadline: tomorrow EOD"   │
              │                               │
              ▼                               │
     [ Regex / Output Parser ]                │
              │                               │
              ▼                               ▼
     [ Temporal Normalizer ] ◄────────────────┘
              │
              ▼
  {
    "task": "Submit code",
    "deadline": "tomorrow EOD",
    "resolved_datetime": "2026-10-25T17:00:00"
  }
```

---

## ✨ Key Features

- **Abstractive Slot Extraction**: Unlike token-classification NER, Flan-T5 reformulates conversational tasks into imperative action phrases (e.g., *"we need to finalize ML model training"* $\to$ *"Finalize ML model training"*).
- **Code-Switching & Slang Robust**: Robust against developer terminology (*"Expo build"*, *"hyperparameters"*, *"distillation"*) and bilingual Arabic/English colloquialisms (*"yalla"*, *"bokra"*, *"isa"*).
- **Temporal Grounding (ISO 8601)**: Anchors relative expressions (*"in 3 days"*, *"next Tuesday at 4 PM"*) against an incoming `reference_date` to produce valid calendar timestamps.
- **Privacy-Preserving & CPU-Friendly**: Sub-300ms inference on commodity CPUs with zero reliance on external third-party APIs.
- **Production-Ready Packaging**: Dockerized microservice with health checks, Pydantic data validation, and automated GPU/CPU device dispatch.

---

## 📊 Training & Evaluation

The backbone model is initialized from `google/flan-t5-base` and fine-tuned using Hugging Face's `Seq2SeqTrainer`.

### Hyperparameters
- **Base Architecture**: Encoder-Decoder Transformer (~250M params)
- **Epochs**: 10
- **Learning Rate**: $2 \times 10^{-5}$
- **Batch Size**: 16 (per device)
- **Weight Decay**: 0.01
- **Generation**: Beam Search (`num_beams=4`, `early_stopping=True`, `max_length=128`)

### Benchmark Results
| Metric | Performance |
| :--- | :--- |
| **Final Validation Loss** | **0.0415** |
| **ROUGE-1** | **94.8%** |
| **ROUGE-2** | **89.2%** |
| **ROUGE-L** | **93.5%** |
| **Exact Slot Match Accuracy** | **91.2%** |
| **Average CPU Inference Latency** | **~210 ms** |

---

## 📁 Repository Structure

```
Deadline-Parser/
├── Dockerfile                  # Container definition (Python 3.11-slim)
├── docker-compose.yml          # Container orchestration & port binding
├── requirements.txt            # Production dependencies
├── main.py                     # FastAPI application & inference engine
├── deadline.ipynb              # End-to-end training, tokenization & evaluation
├── downloadModel.sh            # Optional weight download helper script
├── Model link.txt              # Model storage reference link
└── README.md                   # Project documentation
```

---

## 🚀 Quickstart & Installation

### Option 1: Local Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/ASamy10/Deadline-Parser.git
   cd Deadline-Parser
   ```

2. **Create and activate a virtual environment**:
   ```bash
   python -m venv venv
   # Linux/macOS:
   source venv/bin/activate
   # Windows:
   venv\Scripts\activate
   ```

3. **Install dependencies**:
   ```bash
   pip install --upgrade pip
   pip install -r requirements.txt
   pip install torch --index-url https://download.pytorch.org/whl/cpu
   ```

4. **Obtain the model weights**:
   - Download the model weights folder and place it under `./final_extraction_model/`
   - Alternatively, load directly from Hugging Face Hub by configuring `MODEL_PATH` in `main.py`.

5. **Start the API server**:
   ```bash
   python main.py
   ```
   Interactive Swagger documentation will be available at [http://localhost:8000/docs](http://localhost:8000/docs).

---

### Option 2: Docker Setup

Run the containerized application with a single command:

```bash
docker compose up --build -d
```

Check service health:
```bash
curl http://localhost:8000/health
```

---

## 📡 API Reference

### `POST /extract`
Extracts tasks, deadlines, and resolves relative dates to ISO 8601.

#### Request Body
```json
{
  "email_text": "Hey yalla, we gotta submit the source code for our ML project by tomorrow by EOD, ASAP!",
  "reference_date": "2026-10-24T09:00:00"
}
```

#### Response Body
```json
{
  "task": "Submit source code",
  "deadline": "tomorrow by EOD",
  "resolved_datetime": "2026-10-25T17:00:00",
  "raw_generation": "Task: Submit source code | Deadline: tomorrow by EOD"
}
```

#### cURL Example
```bash
curl -X POST "http://localhost:8000/extract" \
     -H "Content-Type: application/json" \
     -d '{
       "email_text": "Can we finish the slide deck for the client presentation by Tuesday at 4 PM?",
       "reference_date": "2026-10-24T10:00:00"
     }'
```

---

## 🧠 Architectural Trade-offs & Design Choices

| Dimension | Selected Approach (Flan-T5-Base) | Alternative 1 (Extractive NER) | Alternative 2 (LLM APIs) |
| :--- | :--- | :--- | :--- |
| **Task Rephrasing** | ✅ Abstractive synthesis yields clean, imperative verbs | ❌ Awkward raw token spans | ✅ Strong abstraction |
| **Privacy & Sovereignty** | ✅ Self-hosted on enterprise premises | ✅ Self-hosted | ❌ Data sent to 3rd-party servers |
| **Inference Cost** | ✅ Zero per-token API fees | ✅ Very low compute footprint | ❌ Recurring API subscription/costs |
| **Latency** | ⚡ ~200ms CPU inference | ⚡ ~20ms CPU inference | ⏳ 800ms - 2500ms network latency |
| **Hallucination Risk** | ⚠️ Minor generative hallucination risk | ✅ 0% (only extracts existing text) | ⚠️ Hallucination risk |

---

## 🔮 Roadmap & Future Enhancements

- [ ] **Multi-Task Extraction**: Support parsing multi-task emails with distinct individual deadlines.
- [ ] **ONNX Runtime & 8-bit Quantization**: Reduce memory footprint from ~990MB to <300MB for edge/mobile deployments.
- [ ] **PEFT / LoRA Fine-Tuning**: Implement parameter-efficient adapter fine-tuning for lightweight versioning.
- [ ] **Calendar Integration**: Direct OAuth export to Google Calendar and Microsoft Outlook APIs.

---

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.
