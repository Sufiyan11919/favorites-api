import os
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DB_URL','mysql+pymysql://user:pass@localhost/weatherdb')
db = SQLAlchemy(app)

class Favorite(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_email = db.Column(db.String(255), nullable=False)
    city = db.Column(db.String(120), nullable=False)

    __table_args__ = (db.UniqueConstraint('user_email','city', name='uix_email_city'),)

@app.route('/api/fav', methods=['GET'])
def list_fav():
    email = request.args.get('user','demo@example.com')
    favs = Favorite.query.filter_by(user_email=email).all()
    return jsonify([f.city for f in favs])

@app.route('/api/fav', methods=['POST'])
def add_fav():
    data = request.get_json()
    email = data.get('user','demo@example.com')
    city = data.get('city')
    if not city:
        return jsonify({'error':'city required'}),400
    fav = Favorite(user_email=email, city=city)
    db.session.merge(fav)
    db.session.commit()
    return jsonify({'status':'saved'})

@app.route('/api/fav', methods=['DELETE'])
def del_fav():
    email = request.args.get('user','demo@example.com')
    city = request.args.get('city')
    Favorite.query.filter_by(user_email=email, city=city).delete()
    db.session.commit()
    return jsonify({'status':'deleted'})

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(host='0.0.0.0', port=5000)
