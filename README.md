# =====================================================
# 🤖 BackgroundAI Bot
# Version: 0.2.0-alpha
# =====================================================
#
# 🧩 Description:
# A multi-model Discord AI bot that connects to a custom
# PowerShell-based AI engine powered by Ollama.
#
# ⚙️ Architecture:
# 1️⃣ Frontend (Python / Discord.py)
#     - Handles commands, mentions, and message formatting
#     - Communicates with the PowerShell backend
#
# 2️⃣ Middleware (PowerShell Orchestrator)
#     - Runs multiple AI models in parallel via Ollama
#     - Cleans and merges model outputs
#
# 3️⃣ Backend (Summarizer AI)
#     - Combines all model drafts into a unified, natural response
#
# 🧠 Active Models:
#   • LLaMA2-Uncensored (7B) → Reasoning and analysis  
#   • Mistral-OpenOrca (7B)  → Creative phrasing  
#   • Mistral-OpenOrca (7B)  → Summarizer/final composer  
#
# ✨ Features:
#   • `/start` command creates #ai channel per server  
#   • Responds when mentioned inside #ai  
#   • PowerShell backend (`BackgroundAI_Bot.ps1`) handles inference  
#   • Responses cleaned and split to fit Discord’s 2000-char limit  
#   • Removes spinners, ANSI codes, and non-printable characters  
#   • Per-server question limit (default: 400)  
#   • Logging-ready for debugging  
#
# ⚠️ Status:
#   Alpha release — experimental, expect bugs and frequent updates.  
#
# 👤 Author: Reufes  
# 🏷️ Project: BackgroundAI (NightshadeAI Framework)
# =====================================================
