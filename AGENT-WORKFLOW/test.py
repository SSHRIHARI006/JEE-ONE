import os
import anthropic

client = anthropic.Anthropic(
    api_key=os.environ.get("ANTHROPIC_API_KEY", ""),
)

try:
    message = client.messages.create(
        model="claude-3-haiku-20240307",
        max_tokens=10,
        messages=[
            {"role": "user", "content": "Ping"}
        ]
    )
    print("✅ API Key is WORKING. Response:", message.content[0].text)
except anthropic.AuthenticationError:
    print("❌ API Key is INVALID. Check for typos or billing issues.")
except Exception as e:
    print(f"⚠️ An error occurred: {e}")