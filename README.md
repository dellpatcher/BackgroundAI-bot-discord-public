# =====================================================
# 🤖 BackgroundAI PowerShell AI Wrapper
# Version: 0.2.0-alpha
# =====================================================
#
# 🧩 Description:
# BackgroundAI is a multi-model AI wrapper designed to work with
# Ollama models and connect seamlessly to the Discord bot frontend.
# This script acts as the AI orchestration layer, running multiple
# models, merging their results, and returning a unified response.
#
# ⚙️ Architecture:
# 1️⃣ Input (Prompt from Discord)
#     - Receives user questions passed from the Python bot
#
# 2️⃣ Model Layer (Ollama)
#     - Executes multiple base models in parallel
#     - Cleans and collects their responses
#
# 3️⃣ Summarizer Layer
#     - Uses a summarizer model to merge all outputs into a
#       single, coherent NightshadeAI response
#
# 🧠 Active Models:
#   • LLaMA2-Uncensored (7B) → Logical reasoning and analysis  
#   • Mistral-OpenOrca (7B)  → Creative and conversational tone  
#   • Mistral-OpenOrca (7B)  → Acts again as summarizer/final composer  
#
# ✨ Features:
#   • Auto-detects Ollama installation  
#   • Cleans model output (removes spinners, ANSI codes, etc.)  
#   • Runs models safely using redirected standard output  
#   • Merges results into a unified, human-readable reply  
#   • Returns the final message to the Discord bot for display  
#
# ⚠️ Status:
#   Alpha release — experimental, expect bugs and frequent updates.  
#
# 👤 Author: Reufes  
# 🏷️ Project: BackgroundAI (NightshadeAI Wrapper)
# =====================================================
