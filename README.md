# =====================================================
# BackgroundAI Bot 🤖
# Version: 0.2.0-alpha
# =====================================================
#
# A multi-model Discord AI bot that connects to a custom
# PowerShell-based engine powered by Ollama.
#
# 🧠 Architecture Overview:
# - Frontend: Discord bot (Python) handles messages and formatting.
# - Middleware: PowerShell orchestrator runs multiple AI models in parallel.
# - Backend: Summarizer AI merges model outputs into one unified response.
#
# Effectively, this bot runs **3 AI models as one system**:
#   1. LLaMA 2 (uncensored): reasoning and analysis
#   2. Mistral OpenOrca: creative and conversational tone
#   3. Mistral (summarizer): merges both into a clean final reply
#
# ✨ Key Features:
# - Slash command `/start` creates a dedicated #ai channel per server.
# - Mentions trigger NightshadeAI responses inside that channel.
# - PowerShell backend (`BackgroundAI_Bot.ps1`) handles AI inference.
# - Responses are cleaned, chunked, and formatted for Discord (≤2000 chars).
# - Built-in question counter per server (default limit: 400).
# - Cleans AI output (removes spinner chars, ANSI codes, non-printable text).
# - Safe subprocess communication between Python and PowerShell.
#
# ⚠️ Status: Alpha — expect bugs, limited features, and frequent updates.
#
# Author: Reufes
# Project: BackgroundAI
# =====================================================
