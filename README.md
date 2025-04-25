# CommuintyAlert

A community-based alert system consisting of an iOS application and a FastAPI backend that enables users to create and receive real-time alerts about various events in their area.

## Demo

https://github.com/sahanruwantha/ios-project/raw/main/app_demo.mkv

## Project Structure

```
ios-project/
├── Backend/           # FastAPI backend service
└── CommuintyAlert/    # iOS application
```

## Backend Setup

### Prerequisites
- Python 3.8 or higher

### Installation & Setup

1. Navigate to the Backend directory:
```bash
cd Backend
```

2. Create and activate a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Run the application:
```bash
uvicorn main:app --host 0.0.0.0 --port 3000 --reload
```

The API will be available at `http://localhost:3000/api`

### API Documentation
Once the server is running, access the interactive API documentation at:
- Swagger UI: `http://localhost:3000/docs`
- ReDoc: `http://localhost:3000/redoc`

### Environment Variables
For production deployment, configure:
- `SECRET_KEY`: JWT token generation secret key
- `DATABASE_URL`: Database connection URL (defaults to SQLite)

## iOS Application Setup

### Prerequisites
- Xcode 14.0 or higher
- iOS 15.0+ deployment target

The iOS app connects to the backend API by default at `http://localhost:3000`. If you need to change this:

1. Open the project in Xcode
2. Locate the configuration file (e.g., `Configuration.swift` or similar)
3. Update the `baseURL` to your backend API endpoint

## Features

### Backend
- User authentication and authorization
- Alert creation and management
- User preferences management
- Nearby community resources lookup
- Location-based alert filtering
- JWT-based security
- SQLite database (configurable)

### iOS Application
- Real-time alert system with multiple categories
- Interactive map interface with custom annotations
- User reporting system with photo attachments
- Customizable user preferences
- Face ID authentication
- Offline capability
- Push notifications
- Location-based services