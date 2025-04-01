from flask import Flask, render_template, request, redirect
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime, timezone
import os

app = Flask(__name__)
# app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://postgres:password@localhost:5432/postgres'   # running locally
# postgres_link = 'postgresql://{user}:{password}@{host}:{port}/{database}'
# app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://postgres:password@db:5432/mydb'   # with docker-compose
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DB_LINK')  
# Initialize SQLAlchemy with app context
db = SQLAlchemy()
db.init_app(app)

class Student(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    attendance = db.relationship('Attendance', backref='student', lazy=True)

class Attendance(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    date = db.Column(db.Date, nullable=False, default=lambda: datetime.now(timezone.utc))
    status = db.Column(db.String(10), nullable=False)
    student_id = db.Column(db.Integer, db.ForeignKey('student.id'), nullable=False)

# Create tables within app context
def init_db():
    with app.app_context():
        db.create_all()

@app.route('/')
def index():
    students = Student.query.all()
    return render_template('index.html', students=students)

@app.route('/add', methods=['POST'])
def add_student():
    name = request.form['name']
    new_student = Student(name=name)
    db.session.add(new_student)
    db.session.commit()
    return redirect('/')

@app.route('/attendance', methods=['POST'])
def mark_attendance():
    student_id = request.form['student_id']
    status = request.form['status']
    new_attendance = Attendance(student_id=student_id, status=status)
    db.session.add(new_attendance)
    db.session.commit()
    return redirect('/')

if __name__ == '__main__':
    init_db()  # Initialize database tables before running the app
    app.run(debug=True, host='0.0.0.0', port=8000)