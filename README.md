# BackgroundAI Bot 🤖

**Version:** 0.1.0-alpha  
A Discord bot that connects to a custom **PowerShell-based AI engine**.  
This is an **alpha release** — expect bugs, limited features, and frequent updates.

---

## ✨ Features
- Slash command `/start` creates a dedicated `#ai` channel.  
- Responds when mentioned inside the AI channel.  
- Connects to a **PowerShell script** (`BackgroundAI_Bot.ps1`) to process questions.  
- Replies in **Discord embeds** for cleaner formatting.  
- Splits long responses into safe chunks (under Discord’s 2000-character limit).  
- Per-server question limit (`MAX_QUESTIONS_PER_SERVER`, default 10).  
- Logging system for better debugging.  
