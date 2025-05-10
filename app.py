# favourites-api/app.py
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.exc import IntegrityError
import os

# ---- hard-coded fallbacks (can be overridden by env vars) ----
DB_URL = os.getenv("DB_URL", "sqlite:///favourites.db")   # no DB server needed
PORT   = int(os.getenv("PORT", 4000))                     # K8s probes 4000
# -------------------------------------------------------------

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = DB_URL
db = SQLAlchemy(app)

class Favorite(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_email = db.Column(db.String(255), nullable=False)
    city = db.Column(db.String(120), nullable=False)
    __table_args__ = (db.UniqueConstraint("user_email", "city",
                                          name="uix_email_city"),)

# ---------- health endpoint for readiness/liveness ----------
@app.route("/")
def ping():
    return "ok", 200
# ------------------------------------------------------------

@app.route("/api/fav", methods=["GET"])
def list_fav():
    email = request.args.get("user", "demo@example.com")
    favs = Favorite.query.filter_by(user_email=email).all()
    return jsonify([f.city for f in favs])

@app.route("/api/fav", methods=["POST"])
def add_fav():
    data  = request.get_json(force=True, silent=True) or {}
    email = data.get("user", "demo@example.com")
    city  = data.get("city")
    if not city:
        return jsonify(error="city required"), 400
    try:
        db.session.add(Favorite(user_email=email, city=city))
        db.session.commit()
        return jsonify(status="saved")
    except IntegrityError:
        db.session.rollback()
        return jsonify(error="already saved"), 409


# @app.route("/api/fav", methods=["PUT"])
@app.route("/api/fav", methods=["DELETE"])
def del_fav():
    email = request.args.get("user", "demo@example.com")
    city  = request.args.get("city")
    Favorite.query.filter_by(user_email=email, city=city).delete()
    db.session.commit()
    return jsonify(status="deleted")

if __name__ == "__main__":
    with app.app_context():
        db.create_all()               # creates SQLite file if it doesn't exist
    app.run(host="0.0.0.0", port=PORT)
