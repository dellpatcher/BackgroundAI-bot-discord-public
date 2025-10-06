# ╔══════════════════════════════════════════════════════════════════════╗
# ║                           🤖 BackgroundAI Bot                        ║
# ║                           Version: 0.2.0-alpha                       ║
# ╚══════════════════════════════════════════════════════════════════════╝
#
# 🧩 Description:
# A multi-model Discord AI bot that connects to a custom
# PowerShell-based AI engine powered by Ollama.
#
# ⚙️ Architecture Overview:
# ┌────────────────────────────────────────────────────────────────────┐
# │ 1️⃣ Frontend (Python / Discord.py)                                 │
# │     - Handles commands, mentions, and message formatting           │
# │     - Communicates with PowerShell backend via subprocess          │
# │                                                                  │
# │ 2️⃣ Middleware (PowerShell Orchestrator)                            │
# │     - Runs multiple AI models in parallel (Ollama)                │
# │     - Cleans and merges model outputs                             │
# │                                                                  │
# │ 3️⃣ Backend (Summarizer AI)                                        │
# │     - Synthesizes all model drafts into a unified, natural reply  │
# └────────────────────────────────────────────────────────────────────┘
#
# 🧠 Active Models:
#    • LLaMA2-Uncensored (7B) → Logical reasoning & analysis
#    • Mistral-OpenOrca (7B)  → Conversational and creative phrasing
#    • Mistral-OpenOrca (7B)  → Acts again as summarizer/final composer
#
# ✨ Core Features:
#    • `/start` command → Creates dedicated #ai channel per server
#    • Responds when mentioned inside #ai
#    • PowerShell backend (`BackgroundAI_Bot.ps1`) handles inference
#    • Responses auto-cleaned & split (≤2000 chars for Discord)
#    • Removes spinners, ANSI codes, & non-printable characters
#    • Per-server question limit (default: 400)
#    • Logging-ready for debug builds
#
# ⚠️ Status:
#    Alpha build — experimental, expect bugs and updates frequently.
#
# 👤 Author: Reufes
# 🏷️ Project: BackgroundAI (NightshadeAI Framework)
# ══════════════════════════════════════════════════════════════════════
