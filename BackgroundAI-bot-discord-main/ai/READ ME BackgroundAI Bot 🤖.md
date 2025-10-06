# 🤖 BackgroundAI Bot  
**Version:** 0.2.0-alpha  

---

## 🧩 Overview
**BackgroundAI** is a multi-model **AI wrapper** that connects a Discord bot (Python) to a PowerShell-based AI engine powered by **Ollama**.  
It combines **three AI models** into one unified personality — **NightshadeAI** — by fusing reasoning, creativity, and summarization into a single response.

This project is currently in **alpha**, so expect limited functionality and active development.

---

## ⚙️ Architecture

### 1️⃣ Discord Frontend (Python)
- Built with **discord.py**  
- Handles messages, mentions, and `/start` command  
- Sends user prompts to the PowerShell AI engine  
- Cleans and splits long replies to fit Discord’s 2000-character limit  

### 2️⃣ PowerShell AI Orchestrator
- Receives the prompt from the Python bot  
- Runs **multiple Ollama models** in sequence  
- Cleans and merges their outputs into unified text  

### 3️⃣ Summarizer Layer
- A final model refines all drafts into one coherent, human-readable message  
- Acts as the “editor” that defines NightshadeAI’s final tone and style  

---

## 🧠 Active Models
| Role | Model | Purpose |
|------|--------|----------|
| Reasoning | **LLaMA2-Uncensored (7B)** | Analytical and logical thinking |
| Conversational | **Mistral-OpenOrca (7B)** | Natural phrasing and creative tone |
| Summarizer | **Mistral-OpenOrca (7B)** | Merges all responses into one unified answer |

---

## ✨ Features
- `/start` command creates a dedicated `#ai` channel per server  
- Mentions trigger NightshadeAI to respond  
- PowerShell backend (`BackgroundAI_Bot.ps1`) manages model execution  
- Cleans spinner characters, ANSI codes, and other artifacts  
- Per-server question limit (default: 400)  
- Logging-ready for debugging and monitoring  

---

## 🧰 Requirements
- **Windows 10/11** with PowerShell 5.1+  
- **Python 3.9+**  
- **Discord.py** library  
- **Ollama** installed and added to your system PATH  
- Ollama models:
  - `llama2-uncensored:7b`
  - `mistral-openorca:7b`

---

## 🚀 Setup & Run

### 1️⃣ Clone the Repository
```bash
git clone https://github.com/yourusername/BackgroundAI.git
cd BackgroundAI
