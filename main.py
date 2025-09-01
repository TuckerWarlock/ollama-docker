#!/usr/bin/env python3
"""
Simple Python app to interact with Ollama
"""
import os
import requests
import json
from time import sleep
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configuration from environment
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://ollama:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama3.2:3b")


def wait_for_ollama(host=None, model=None, max_retries=60):
    """Wait for Ollama service to be ready and models to be loaded"""
    host = host or OLLAMA_HOST
    model = model or OLLAMA_MODEL
    
    for i in range(max_retries):
        try:
            # First check if service is up
            response = requests.get(f"{host}/api/tags", timeout=5)
            if response.status_code == 200:
                # Check if our model is available
                models = response.json().get('models', [])
                if any(model in model_info.get('name', '') for model_info in models):
                    print(f"✅ Ollama is ready with {model}!")
                    return True
                else:
                    print(f"⏳ Waiting for {model} model to load... ({i+1}/{max_retries})")
        except requests.exceptions.RequestException:
            print(f"⏳ Waiting for Ollama service... ({i+1}/{max_retries})")
        sleep(3)
    
    print(f"❌ Ollama or model {model} failed to load")
    return False


def chat_with_ollama(prompt, model=None, host=None):
    """Send a prompt to Ollama and get response"""
    host = host or OLLAMA_HOST
    model = model or OLLAMA_MODEL
    url = f"{host}/api/generate"
    
    payload = {
        "model": model,
        "prompt": prompt,
        "stream": False
    }
    
    try:
        response = requests.post(url, json=payload, timeout=30)
        if response.status_code == 200:
            return response.json()["response"]
        else:
            return f"Error: {response.status_code} - {response.text}"
    except requests.exceptions.RequestException as e:
        return f"Connection error: {str(e)}"


def main():
    print("🚀 Starting Ollama Python Client")
    print(f"📡 Host: {OLLAMA_HOST}")
    print(f"🤖 Model: {OLLAMA_MODEL}")
    
    # Wait for Ollama to be ready
    if not wait_for_ollama():
        return
    
    # Test with a simple prompt
    print("\n💭 Testing with a simple prompt...")
    response = chat_with_ollama("Write a haiku about programming")
    print(f"📝 Response: {response}")
    
    # Interactive mode
    print(f"\n🎯 Interactive mode with {OLLAMA_MODEL} (type 'quit' to exit):")
    while True:
        try:
            prompt = input("\n👤 You: ").strip()
            if prompt.lower() in ['quit', 'exit', 'q']:
                break
            
            if prompt:
                print("🤖 Ollama:", end=" ")
                response = chat_with_ollama(prompt)
                print(response)
                
        except KeyboardInterrupt:
            print("\n👋 Goodbye!")
            break


if __name__ == "__main__":
    main()
