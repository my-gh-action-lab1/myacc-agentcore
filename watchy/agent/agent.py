"""watchy - a Bedrock AgentCore Runtime agent with two simple tools:

1. get_capital  - looks up the capital city of a country (static table).
2. send_email   - sends an email notification via an Amazon SNS topic.

Invoke payload:
    {"prompt": "What is the capital of Japan?"}
    {"prompt": "Email me at the team saying the deployment finished"}
"""

import os

import boto3
from bedrock_agentcore.runtime import BedrockAgentCoreApp
from strands import Agent, tool
from strands.models import BedrockModel

app = BedrockAgentCoreApp()

REGION = os.environ.get("AWS_REGION", "eu-west-1")
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN", "")
MODEL_ID = os.environ.get("MODEL_ID", "eu.anthropic.claude-sonnet-5")

# Not every country in the world - just a solid, easy-to-extend starter list.
CAPITALS = {
    "france": "Paris", "germany": "Berlin", "italy": "Rome", "spain": "Madrid",
    "portugal": "Lisbon", "united kingdom": "London", "ireland": "Dublin",
    "netherlands": "Amsterdam", "belgium": "Brussels", "switzerland": "Bern",
    "austria": "Vienna", "sweden": "Stockholm", "norway": "Oslo",
    "denmark": "Copenhagen", "finland": "Helsinki", "poland": "Warsaw",
    "czech republic": "Prague", "greece": "Athens", "hungary": "Budapest",
    "romania": "Bucharest", "ukraine": "Kyiv", "russia": "Moscow",
    "turkey": "Ankara",
    "united states": "Washington, D.C.", "canada": "Ottawa",
    "mexico": "Mexico City", "brazil": "Brasilia", "argentina": "Buenos Aires",
    "chile": "Santiago", "colombia": "Bogota", "peru": "Lima",
    "venezuela": "Caracas", "cuba": "Havana",
    "china": "Beijing", "japan": "Tokyo", "india": "New Delhi",
    "south korea": "Seoul", "north korea": "Pyongyang", "indonesia": "Jakarta",
    "pakistan": "Islamabad", "bangladesh": "Dhaka", "vietnam": "Hanoi",
    "thailand": "Bangkok", "philippines": "Manila", "malaysia": "Kuala Lumpur",
    "singapore": "Singapore", "saudi arabia": "Riyadh",
    "united arab emirates": "Abu Dhabi", "israel": "Jerusalem",
    "iran": "Tehran", "iraq": "Baghdad",
    "egypt": "Cairo", "nigeria": "Abuja", "south africa": "Pretoria",
    "kenya": "Nairobi", "ethiopia": "Addis Ababa", "morocco": "Rabat",
    "ghana": "Accra", "algeria": "Algiers", "tunisia": "Tunis",
    "libya": "Tripoli",
    "australia": "Canberra", "new zealand": "Wellington",
}


@tool
def get_capital(country: str) -> str:
    """Look up the capital city of a country.

    Args:
        country: Country name, e.g. "France" or "Japan".

    Returns:
        A sentence naming the capital, or a message if it isn't in the table.
    """
    capital = CAPITALS.get(country.strip().lower())
    if capital:
        return f"The capital of {country} is {capital}."
    return f"Sorry, I don't have the capital of '{country}' in my lookup table."


@tool
def send_email(subject: str, message: str) -> str:
    """Send an email notification via the SNS topic configured for this agent.

    Args:
        subject: Email subject line (truncated to 100 characters).
        message: Email body text.

    Returns:
        Confirmation the message was queued, or an error.
    """
    if not SNS_TOPIC_ARN:
        return "ERROR: SNS_TOPIC_ARN environment variable is not configured."

    sns = boto3.client("sns", region_name=REGION)
    response = sns.publish(TopicArn=SNS_TOPIC_ARN, Subject=subject[:100], Message=message)
    return f"Email queued via SNS (MessageId={response['MessageId']})"


SYSTEM_PROMPT = (
    "You are watchy, a helpful assistant. Use the get_capital tool to answer "
    "questions about a country's capital city. Use the send_email tool only "
    "when the user explicitly asks to be emailed or notified - it delivers "
    "the message through Amazon SNS to whoever is subscribed to that topic."
)


@app.entrypoint
def invoke(payload):
    """AgentCore Runtime entrypoint."""
    prompt = (payload or {}).get("prompt", "").strip()
    if not prompt:
        return {"error": "payload must include a non-empty 'prompt' field"}

    agent = Agent(
        model=BedrockModel(model_id=MODEL_ID, region_name=REGION),
        system_prompt=SYSTEM_PROMPT,
        tools=[get_capital, send_email],
    )
    result = agent(prompt)
    return {"result": str(result)}


if __name__ == "__main__":
    app.run()
