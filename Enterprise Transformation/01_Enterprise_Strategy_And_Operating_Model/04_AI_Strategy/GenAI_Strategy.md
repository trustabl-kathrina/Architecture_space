# Generative AI Strategy

## Overview
Specific strategic guidelines for the adoption of Large Language Models (LLMs) and other generative technologies.

## Core Architectural Decisions
- **Buy vs. Build**: Prefer consuming SaaS models (e.g., OpenAI, Anthropic) via secure APIs for general tasks; fine-tune open-source models (e.g., Llama, Mistral) for highly specialized, proprietary tasks.
- **RAG First**: Default to Retrieval-Augmented Generation (RAG) using enterprise data rather than fine-tuning to provide context and reduce hallucination.
- **Model Agnosticism**: Architect the platform to easily swap foundational models as the market evolves rapidly.

## Security Posture
Strict prohibition on entering proprietary enterprise data into public, consumer-facing LLMs. All GenAI interactions must route through the secure Enterprise AI Gateway.
