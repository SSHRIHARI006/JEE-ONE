import os
import base64
from dotenv import load_dotenv
from anthropic import Anthropic

load_dotenv()
api_key = os.environ.get("ANTHROPIC_API_KEY")
print("Key prefix:", api_key[:15] if api_key else "None")
try:
    client = Anthropic(api_key=api_key)
    msg = client.messages.create(
        model=os.environ.get("ANTHROPIC_MODEL", "claude-3-5-sonnet-20241022"),
        max_tokens=10,
        messages=[{"role": "user", "content": "hello"}]
    )
    print("Response:", msg.content[0].text)
except Exception as e:
    print("Exception:", e)
