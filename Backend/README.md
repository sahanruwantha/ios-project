# Community Alert API

A FastAPI-based backend service for a community alert system that allows users to create and receive alerts about various events in their area.

## Features

- User authentication and authorization
- Alert creation and management
- User preferences management
- Nearby community resources lookup
- Location-based alert filtering

## Setup

1. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Run the application:
```bash
uvicorn main:app --host 0.0.0.0 --port 3000 --reload
```

The API will be available at `http://localhost:3000/api`

## API Documentation

Once the server is running, you can access the interactive API documentation at:
- Swagger UI: `http://localhost:3000/docs`
- ReDoc: `http://localhost:3000/redoc`

## Database

The application uses SQLite as the database. The database file will be automatically created at `./community_alert.db` when you first run the application.

## Security

- JWT-based authentication
- Password hashing using bcrypt
- CORS enabled for all origins (configure as needed for production)

## Environment Variables

For production use, you should set the following environment variables:
- `SECRET_KEY`: A secure secret key for JWT token generation
- `DATABASE_URL`: Database connection URL (defaults to SQLite)

## API Endpoints

### Authentication
- POST `/auth/register`: Register a new user
- POST `/auth/login`: Login and get access token

### Alerts
- GET `/alerts`: Get all alerts (with optional location filtering)
- POST `/alerts`: Create a new alert

### Users
- GET `/users/{user_id}`: Get user profile
- GET `/users/{user_id}/preferences`: Get user preferences
- PUT `/users/{user_id}/preferences`: Update user preferences

### Community Resources
- GET `/resources/nearby`: Get nearby community resources

## Development

To run tests:
```bash
# Add test commands here when tests are implemented
```

## License

MIT 