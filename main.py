from fastapi import FastAPI
from pydantic import BaseModel
from transformers import AutoModelForSeq2SeqLM, AutoTokenizer
import torch
import uvicorn

app = FastAPI()

model_path = "." 

print("⏳ Loading model... Please wait.")
tokenizer = AutoTokenizer.from_pretrained("google/flan-t5-base")
model = AutoModelForSeq2SeqLM.from_pretrained(model_path, local_files_only=True)
print("✅ Model loaded successfully!")

class EmailInput(BaseModel):
    email_text: str

@app.post("/extract")
async def extract_task_and_deadline(data: EmailInput):
    # This prefix helps the model know exactly what to do
    input_text = "extract task and deadline: " + data.email_text
    
    inputs = tokenizer(input_text, return_tensors="pt")
    
    with torch.no_grad():
        # Increased max_length to 128 to ensure the deadline isn't cut off
        outputs = model.generate(
            **inputs, 
            max_length=128, 
            num_beams=4, 
            early_stopping=True
        )
    
    extracted_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
    
    return {
        "raw_result": extracted_text
    }

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000)