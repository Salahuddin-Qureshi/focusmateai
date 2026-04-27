import os
import autogen
import requests
from dotenv import load_dotenv

# Load environment variables
load_dotenv()
os.environ["OPENAI_API_KEY"] = os.getenv("OPENAI_API_KEY")
TAVILY_API_KEY = os.getenv("TAVILY_API_KEY")

def search_tavily(query: str):
    """Searches the web for latest trends using Tavily API via Requests (Python 3.8+ compatible)."""
    print(f"\n🔍 [SEARCHING THE WEB FOR: {query}]...")
    
    url = "https://api.tavily.com/search"
    payload = {
        "api_key": TAVILY_API_KEY,
        "query": query,
        "search_depth": "basic",
        "max_results": 3
    }
    
    try:
        response = requests.post(url, json=payload)
        response.raise_for_status()
        data = response.json()
        results = "\n".join([f"- {r['title']}: {r['content']}" for r in data.get('results', [])])
        return results if results else "No trends found."
    except Exception as e:
        return f"Error during search: {str(e)}"

def run_cli_analysis():
    print("\n--- FocusMate AI: Smart Terminal Analyzer (V3.8 Compatible) ---")
    
    goal = input("\n🎯 What is your goal for today? (e.g., 'AI Engineer'): ")
    
    usage_data = []
    print("\n📱 Enter your app usage (Leave app name empty to finish):")
    while True:
        app_name = input("App Name: ").strip()
        if not app_name: break
        try:
            minutes = int(input(f"Minutes spent on {app_name}: "))
            category = input(f"Category (social/productivity/entertainment): ").lower()
            usage_data.append({"name": app_name, "minutes": minutes, "category": category})
            print("-" * 20)
        except ValueError: print("❌ Invalid minutes.")

    if not usage_data: return

    # Setup AutoGen
    config_list = [{"model": "gpt-4o", "api_key": os.environ["OPENAI_API_KEY"]}]
    
    # 1. Researcher Agent
    researcher = autogen.AssistantAgent(
        name="Researcher",
        system_message="You are a research expert. Use the search tool to find the latest trends and skills needed for the user's goal. Summarize them briefly.",
        llm_config={"config_list": config_list},
    )

    # 2. Analyst Agent
    analyst = autogen.AssistantAgent(
        name="Analyst",
        system_message="You are a data analyst. Compare the user's app usage with the trends found by the Researcher. Explain what they are missing out on.",
        llm_config={"config_list": config_list},
    )

    # 3. Coach Agent
    coach = autogen.AssistantAgent(
        name="Coach",
        system_message="You are a productivity coach. Give a 'Focus Verdict' (Success or Fail). Tell the user how they are falling behind current trends. Finally, SUGGEST A SPECIFIC PLAN FOR THE NEXT DAY. End with 'END_VERDICT'.",
        llm_config={"config_list": config_list},
    )

    user_proxy = autogen.UserProxyAgent(
        name="UserProxy",
        human_input_mode="NEVER",
        max_consecutive_auto_reply=3,
        code_execution_config=False,
        is_termination_msg=lambda x: x.get("content") is not None and "END_VERDICT" in x.get("content", ""),
    )

    # Register the Tavily tool
    autogen.agentchat.register_function(
        search_tavily,
        caller=researcher,
        executor=user_proxy,
        name="search_tavily",
        description="Search for latest trends and news about a specific field.",
    )

    # Prepare the Prompt
    apps_str = "\n".join([f"- {a['name']}: {a['minutes']} mins ({a['category']})" for a in usage_data])
    prompt = f"""
    User Goal: {goal}
    Today's App Usage:
    {apps_str}
    
    First, find the latest trends in {goal}. Then evaluate the user's productivity and suggest a plan for tomorrow.
    """

    print("\n🤖 [AI RESEARCHERS AND COACHES ARE COLLABORATING...]\n")
    user_proxy.initiate_chat(researcher, message=prompt)

if __name__ == "__main__":
    run_cli_analysis()
