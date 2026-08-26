from flask import Flask, request, jsonify
from flask_cors import CORS
import uuid
import time

app = Flask(__name__)
CORS(app) # Allow Godot HTML5 clients to fetch

# In-memory storage for lobbies
# Format: { room_id: { "name": str, "ip": str, "port": int, "private": bool, "password": str, "last_ping": float } }
lobbies = {}

@app.route('/register', methods=['POST'])
def register():
    data = request.json
    client_ip = request.remote_addr # Get host IP automatically
    
    room_id = str(uuid.uuid4())[:8]
    lobbies[room_id] = {
        "id": room_id,
        "name": data.get("name", "Match"),
        "ip": client_ip,
        "port": data.get("port", 7350),
        "private": data.get("private", False),
        "password": data.get("password", ""),
        "last_ping": time.time()
    }
    
    return jsonify({"success": True, "room_id": room_id})

@app.route('/list', methods=['GET'])
def list_servers():
    # Cleanup stale lobbies (> 2 minutes without ping)
    now = time.time()
    stale = [k for k, v in lobbies.items() if now - v["last_ping"] > 120]
    for k in stale:
        del lobbies[k]
        
    servers_list = []
    for room_id, info in lobbies.items():
        servers_list.append({
            "id": info["id"],
            "name": info["name"],
            "private": info["private"]
        })
        
    return jsonify({"servers": servers_list})

@app.route('/join', methods=['GET'])
def join_server():
    room_id = request.args.get("room")
    pw = request.args.get("pw", "")
    
    if room_id not in lobbies:
        return jsonify({"error": "Room not found"}), 404
        
    room = lobbies[room_id]
    
    if room["private"] and room["password"] != pw:
        return jsonify({"error": "Incorrect password"}), 403
        
    return jsonify({"ip": room["ip"], "port": room["port"]})

if __name__ == '__main__':
    # Run on all interfaces, port 8080
    app.run(host='0.0.0.0', port=8080)