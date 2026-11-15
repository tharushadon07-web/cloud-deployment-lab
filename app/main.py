import os
from datetime import datetime, timezone
from flask import Flask, jsonify, render_template_string

app = Flask(__name__)
START = datetime.now(timezone.utc).isoformat()

PAGE = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Cloud Deployment Lab - Version 2</title><style>body{font:16px system-ui;background:#0b1220;color:#ecf2ff;min-height:100vh;display:grid;place-items:center;margin:0}main{max-width:650px;padding:48px;border:1px solid #334766;border-radius:20px;background:#131f33}small{color:#88a4d2}h1{font-size:2.6em}code{color:#9fe8c3}a{color:#acd4ff}</style></head><body><main><small>DEVOPS PORTFOLIO PROJECT</small><h1>Cloud Deployment Lab</h1><p>Flask + Docker + Jenkins + AWS. A real application with a health endpoint, tests, containerisation, and deployment automation.</p><p><strong>Environment:</strong> {{ env }}</p><p><strong>Status:</strong> <code>healthy</code></p><p>Try <a href="/health">/health</a> or <a href="/api/info">/api/info</a>.</p></main></body></html>'''

@app.get('/')
def index():
    return render_template_string(PAGE, env=os.getenv('APP_ENV', 'local'))

@app.get('/health')
def health():
    return jsonify(status='healthy'), 200

@app.get('/api/info')
def info():
    return jsonify(name='cloud-deployment-lab', version=os.getenv('APP_VERSION', '1.0.0'), environment=os.getenv('APP_ENV', 'local'), started_utc=START)
