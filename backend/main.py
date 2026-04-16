from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import autogen
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="FocusMate AI Backend")

# Configuration for AutoGen
config_list = [
    {
        "model": "gpt-4",
        "api_key": os.getenv("OPENAI_API_KEY"),
    }
]

class AppUsage(BaseModel):
    name: str
    minutes: int
    category: str

class EvaluationRequest(BaseModel):
    user_id: str
    goal: str
    usage_data: List[AppUsage]

@app.get("/")
def read_root():
    return {"status": "FocusMate AI Backend is Running"}

@app.post("/analyze")
async def analyze_focus(request: EvaluationRequest):
    print(f"\n[RECEIVED REQUEST] User: {request.user_id} | Goal: {request.goal}")
    print(f"[DATA] Apps detected: {len(request.usage_data)}")

    # Testing Mode: If no real key is provided, return a mock response
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key or api_key == "your_key_here":
        print("[MODE] Running in Mock Test Mode (No API Key)")
        return {
            "user_id": request.user_id,
            "verdict": f"AI AGENT TEST: Your goal is '{request.goal}'. I see you have {len(request.usage_data)} apps used today. This is a placeholder response to confirm the connection is working!",
            "status": "mock_evaluation"
        }

    print("[MODE] Running Real AutoGen Analysis...")
    analyst = autogen.AssistantAgent(
        name="Analyst",
        system_message="You are a data analyst. Analyze app usage and categorize it as productive or distracting based on the user's goal. Be brief and objective.",
        llm_config={"config_list": config_list},
    )

    coach = autogen.AssistantAgent(
        name="Coach",
        system_message="You are a productivity coach. Based on the analyst's report, give the user a 'Focus Verdict' (Success or Fail) and provide one piece of actionable advice. Be encouraging but firm.",
        llm_config={"config_list": config_list},
    )

    user_proxy = autogen.UserProxyAgent(
        name="UserProxy",
        human_input_mode="NEVER",
        max_consecutive_auto_reply=2,
        code_execution_config=False,
    )

    # Format the prompt
    apps_str = "\n".join([f"- {a.name}: {a.minutes} mins ({a.category})" for a in request.usage_data])
    prompt = f"""
    User Goal: {request.goal}
    Today's App Usage:
    {apps_str}
    
    Evaluate if the user was productive today towards their goal.
    """

    # Start the conversation
    chat_result = user_proxy.initiate_chat(
        coach,
        message=f"I need an evaluation based on this data: {prompt}",
        clear_history=True,
    )

    # Extract the last message as the verdict
    verdict = chat_result.summary if hasattr(chat_result, 'summary') else "Evaluation completed."

    return {
        "user_id": request.user_id,
        "verdict": verdict,
        "raw_analysis": chat_result.chat_history
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
