# Rabbit Hole

**Rabbit Hole** is a web-based visualization tool designed to help users explore ideas and connections. It starts with a single topic and lets you "fall down the rabbit hole" by expanding nodes to reveal related concepts, creating an infinite, interactive knowledge graph.

<img width="838" height="817" alt="Screenshot 2026-01-02 at 3 26 24 PM" src="https://github.com/user-attachments/assets/5e27fef1-b7fc-4dab-b72b-dcb5e36693a3" />


## About the Project

This project was built as an experiment using browser-based LLM coding tools. The goal was to create a lightweight, interactive web app that visualizes relationships between topics.

Currently, the app allows a user to input a starting seed (e.g., "axolotl") and generates a graph of related concepts. Users can click any node to treat it as a new parent, expanding the graph further and further.

## Features

* **Topic Search:** Start your journey with any keyword or concept.
* **Interactive Graph:** Visualizes concepts as nodes and relationships as links.
* **Recursive Exploration:** Click on any "child" node to expand it and find *its* relationships.
* **Wikipedia Integration:** Currently uses the Wikipedia API to determine related topics.

## Roadmap & Future Vision

This is currently a "bare bones" prototype. The ultimate vision is to move beyond simple keyword association and use Large Language Models (LLMs) to provide deeper context.

* **LLM Integration:** Replace the Wikipedia API with an LLM to generate more abstract or creative connections.
* **Relationship Context:** Implement a feature where the LLM describes *why* two nodes are related (e.g., instead of just linking "Apple" to "Newton," the edge would explain "Newton discovered gravity when an apple fell...").
* **UI/UX Improvements:** Enhanced animations and node organization.

## Tech Stack

* **Frontend:** HTML/CSS/JavaScript
* **Visualization:** [Insert Library Name here, e.g., D3.js or Cytoscape.js]
* **Data Source:** Wikipedia API (Current)

## How to Run

1.  Clone the repository:
    ```bash
    git clone [https://github.com/your-username/rabbit-hole.git](https://github.com/your-username/rabbit-hole.git)
    ```
2.  Open `index.html` in your web browser.
3.  Type a topic and start exploring!
