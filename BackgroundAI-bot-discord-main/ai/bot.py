import os
import re
import discord
from discord.ext import commands
import subprocess

# -------------------------
# Config
# -------------------------
TOKEN = " token_here"
AI_NAME = "NightshadeAI"
MAX_QUESTIONS_PER_SERVER = 400

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
POWERSHELL_SCRIPT = os.path.join(SCRIPT_DIR, "BackgroundAI_Bot.ps1")

server_question_count = {}

intents = discord.Intents.default()
intents.messages = True
intents.message_content = True
intents.guilds = True

bot = commands.Bot(command_prefix="!", intents=intents)

# -------------------------
# Clean PowerShell AI output
# -------------------------
def clean_ai_output(text):
    """
    Fully clean AI output:
    - Removes braille spinner characters (⠙ ⠹ ⠸ ⠼ …)
    - Removes ANSI escape codes
    - Removes other non-printable Unicode
    """
    # Remove braille spinner characters (U+2800 to U+28FF)
    text = re.sub(r'[\u2800-\u28FF]', '', text)
    
    # Remove ANSI escape codes
    ansi_escape = re.compile(r'\x1B[@-_][0-?]*[ -/]*[@-~]')
    text = ansi_escape.sub('', text)
    
    # Remove other non-printable/unusual Unicode except newlines
    text = re.sub(r'[^\x20-\x7E\r\n]', '', text)
    
    return text.strip()

# -------------------------
# Call PowerShell AI safely
# -------------------------
def ask_ai(question):
    try:
        proc = subprocess.Popen(
            ["powershell", "-ExecutionPolicy", "Bypass", "-File", POWERSHELL_SCRIPT, question],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT
        )

        full_response_bytes = b""

        while True:
            byte_line = proc.stdout.readline()
            if not byte_line and proc.poll() is not None:
                break
            if byte_line:
                full_response_bytes += byte_line

        proc.wait()

        response = full_response_bytes.decode("utf-8", errors="ignore").strip()
        if not response:
            response = "⚠️ AI returned no response."
        
        # ✅ Clean the response fully
        return clean_ai_output(response)

    except Exception as e:
        return f"⚠️ Error calling AI: {e}"

# -------------------------
# Split response for Discord
# -------------------------
def split_discord_message(text, limit=2000):
    chunks = []
    while len(text) > limit:
        split_pos = text.rfind('\n', 0, limit)
        if split_pos == -1:
            split_pos = text.rfind(' ', 0, limit)
        if split_pos == -1:
            split_pos = limit
        chunks.append(text[:split_pos].strip())
        text = text[split_pos:].strip()
    if text:
        chunks.append(text)
    return chunks

# -------------------------
# Slash command /start
# -------------------------
@bot.event
async def on_ready():
    print(f"{AI_NAME} is online!")
    try:
        await bot.tree.sync()
    except Exception as e:
        print(e)

@bot.tree.command(name="start", description="Create AI channel")
async def start(interaction: discord.Interaction):
    guild = interaction.guild
    if guild is None:
        await interaction.response.send_message("❌ This command only works in a server.", ephemeral=True)
        return

    existing = discord.utils.get(guild.text_channels, name="ai")
    if existing:
        await interaction.response.send_message("⚠️ AI channel already exists.", ephemeral=True)
        return

    channel = await guild.create_text_channel("ai")
    server_question_count[guild.id] = 0
    await interaction.response.send_message(f"✅ AI channel created: {channel.mention}")

# -------------------------
# Respond in AI channel
# -------------------------
@bot.event
async def on_message(message):
    if message.author.bot or message.guild is None:
        return

    await bot.process_commands(message)

    guild_id = message.guild.id
    ai_channel = discord.utils.get(message.guild.text_channels, name="ai")
    if ai_channel is None or message.channel.id != ai_channel.id:
        return

    if bot.user.mentioned_in(message):
        server_question_count.setdefault(guild_id, 0)
        if server_question_count[guild_id] >= MAX_QUESTIONS_PER_SERVER:
            await message.channel.send(f"❌ {AI_NAME} has reached the question limit for this server.")
            return

        user_question = message.content
        for mention in message.mentions:
            user_question = user_question.replace(f"<@{mention.id}>", "").replace(f"<@!{mention.id}>", "")
        user_question = user_question.strip()

        if not user_question:
            await message.channel.send("⚠️ Please ask a question after mentioning me.")
            return

        server_question_count[guild_id] += 1

        async with message.channel.typing():
            response = ask_ai(user_question)

        for chunk in split_discord_message(response):
            await message.channel.send(f"🤖 {AI_NAME}:\n{chunk}")

# -------------------------
# Run bot
# -------------------------
bot.run(TOKEN)

