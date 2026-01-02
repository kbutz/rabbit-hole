# main.py
from fastapi import FastAPI
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
import wikipedia
import random

app = FastAPI()

# Enable CORS so the HTML file can talk to this backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"]
)

@app.get("/")
def read_root():
    return FileResponse('index.html')

@app.get("/expand")
def expand_topic(topic: str):
    try:
        page = wikipedia.page(topic, auto_suggest=False, redirect=True)
        links = page.links
        # Return a smaller, random sample of links to keep the graph manageable
        if len(links) > 10:
            links = random.sample(links, 10)
        return {"topic": topic, "related": links}
    except wikipedia.exceptions.PageError:
        return {"topic": topic, "related": []}
    except wikipedia.exceptions.DisambiguationError as e:
        # Return a few disambiguation options
        return {"topic": topic, "related": e.options[:5]}
