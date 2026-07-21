# AgentCore Runtime requires a linux/arm64 container that serves on port 8080.
FROM --platform=linux/arm64 python:3.13-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY agent.py .

# BedrockAgentCoreApp exposes /invocations and /ping on 8080.
EXPOSE 8080

CMD ["python", "agent.py"]
