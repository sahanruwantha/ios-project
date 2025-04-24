# Community Alert API Documentation

## Base URL
```
http://localhost:3000/api
```

## Authentication

### Register User
- **Method**: POST
- **Endpoint**: `/auth/register`
- **Request Body**:
```json
{
    "email": "string",
    "password": "string",
    "fullName": "string",
    "phoneNumber": "string"
}
```
- **Response**:
```json
{
    "userId": "string",
    "token": "string",
    "refreshToken": "string",
    "expiresIn": number
}
```

### Login
- **Method**: POST
- **Endpoint**: `/auth/login`
- **Request Body**:
```json
{
    "email": "string",
    "password": "string"
}
```
- **Response**:
```json
{
    "userId": "string",
    "token": "string",
    "refreshToken": "string",
    "expiresIn": number
}
```

### Refresh Token
- **Method**: POST
- **Endpoint**: `/auth/refresh-token`
- **Request Body**:
```json
{
    "refreshToken": "string"
}
```
- **Response**:
```json
{
    "token": "string",
    "refreshToken": "string",
    "expiresIn": number
}
```

## Alerts

### Get Alerts
- **Method**: GET
- **Endpoint**: `/alerts`
- **Query Parameters**:
  - `latitude`: number (optional)
  - `longitude`: number (optional)
  - `radius`: number (optional)
- **Response**:
```json
[
    {
        "id": "string",
        "title": "string",
        "description": "string",
        "category": "Weather" | "Traffic" | "Crime" | "Community" | "Public Safety" | "Infrastructure",
        "priority": "Immediate" | "Important" | "Informational",
        "verificationStatus": "Verified" | "Pending" | "Unverified",
        "location": {
            "latitude": number,
            "longitude": number
        },
        "radius": number,
        "timestamp": "string (ISO date)",
        "source": "string",
        "isActive": boolean
    }
]
```

### Create Alert
- **Method**: POST
- **Endpoint**: `/alerts`
- **Request Body**:
```json
{
    "title": "string",
    "description": "string",
    "category": "Weather" | "Traffic" | "Crime" | "Community" | "Public Safety" | "Infrastructure",
    "priority": "Immediate" | "Important" | "Informational",
    "location": {
        "latitude": number,
        "longitude": number
    },
    "radius": number,
    "source": "string"
}
```
- **Response**: Same as Get Alerts response

## User

### Get User Profile
- **Method**: GET
- **Endpoint**: `/users/{userId}`
- **Response**:
```json
{
    "id": "string",
    "email": "string",
    "fullName": "string",
    "phoneNumber": "string",
    "avatarUrl": "string | null",
    "createdAt": "string (ISO date)",
    "lastLogin": "string (ISO date)"
}
```

### Get User Preferences
- **Method**: GET
- **Endpoint**: `/users/{userId}/preferences`
- **Response**:
```json
{
    "enabledCategories": ["Weather" | "Traffic" | "Crime" | "Community" | "Public Safety" | "Infrastructure"],
    "alertRadius": number,
    "notificationSettings": {
        "soundEnabled": boolean,
        "vibrationEnabled": boolean,
        "criticalAlertsEnabled": boolean,
        "communityAlertsEnabled": boolean
    },
    "emergencyContacts": [
        {
            "id": "string",
            "name": "string",
            "phoneNumber": "string",
            "relationship": "string"
        }
    ]
}
```

### Update User Preferences
- **Method**: PUT
- **Endpoint**: `/users/{userId}/preferences`
- **Request Body**:
```json
{
    "enabledCategories": ["Weather" | "Traffic" | "Crime" | "Community" | "Public Safety" | "Infrastructure"],
    "alertRadius": number,
    "notificationSettings": {
        "soundEnabled": boolean,
        "vibrationEnabled": boolean,
        "criticalAlertsEnabled": boolean,
        "communityAlertsEnabled": boolean
    }
}
```
- **Response**: Same as Get User Preferences response

## Community Resources

### Get Nearby Resources
- **Method**: GET
- **Endpoint**: `/resources/nearby`
- **Query Parameters**:
  - `latitude`: number
  - `longitude`: number
  - `radius`: number
- **Response**:
```json
[
    {
        "id": "string",
        "name": "string",
        "type": "Shelter" | "Hospital" | "Police Station" | "Fire Station" | "Community Center",
        "location": {
            "latitude": number,
            "longitude": number
        },
        "description": "string",
        "contactInfo": "string"
    }
]
```

## Error Responses

All endpoints may return the following error responses:

```json
{
    "error": {
        "code": string,
        "message": string,
        "details": object
    }
}
```

Common error codes:
- 400: Bad Request
- 401: Unauthorized
- 403: Forbidden
- 404: Not Found
- 409: Conflict
- 422: Unprocessable Entity
- 429: Too Many Requests
- 500: Internal Server Error

## Headers

All authenticated requests must include:
```
Authorization: Bearer <token>
Content-Type: application/json
Accept: application/json
``` 