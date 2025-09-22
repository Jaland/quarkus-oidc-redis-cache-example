# Quarkus OIDC with Google OAuth and Redis Token Storage

This project demonstrates how to use Quarkus OIDC with Google as an OAuth provider and Redis for token state management.

## Overview

This example shows how to:
- Configure Quarkus OIDC to use Google as the identity provider
- Store authentication tokens in Redis for scalability and session management
- Implement secured endpoints with OAuth authentication
- Handle logout functionality (local and global)

## Prerequisites

* Java 17+
* Maven 3.8+
* Docker (for Redis)
* Google Cloud Console account

## Setup Google OAuth 2.0 Client

1. Go to the [Google Cloud Console Credentials page](https://console.cloud.google.com/apis/credentials).
2. Click **Create Credentials** > **OAuth client ID**.
3. Select **Web application** for the application type.
4. Give it a name (e.g., "Quarkus OIDC Example").
5. Under **Authorized redirect URIs**, add:
   * `http://localhost:8080/q/oidc/code`
6. Click **Create**.
7. Copy the **Client ID** and **Client Secret**.

## Configuration

### Create `application-dev.properties`

Create `src/main/resources/application-dev.properties` with your Google credentials:

```properties
# OIDC Configuration
quarkus.oidc.provider=google
quarkus.oidc.client-id=<YOUR_GOOGLE_CLIENT_ID>
quarkus.oidc.credentials.secret=<YOUR_GOOGLE_CLIENT_SECRET>
quarkus.oidc.application-type=web_app

# Important: Set grant type to refresh for proper token management
quarkus.oidc-client.grant.type=refresh

# Use Redis for token state management
quarkus.oidc.token-state-manager.strategy=redis
quarkus.oidc.token-state-manager.redis.key-prefix=q_oidc

# Redis configuration
quarkus.redis.hosts=redis://localhost:6379

# Optional: Disable PKCE if you encounter state cookie issues
quarkus.oidc.authentication.pkce-required=false
```

> [!NOTE]
> The `application-dev.properties` file is in `.gitignore` to keep your credentials secure.

### Key Configuration Points

**`quarkus.oidc-client.grant.type=refresh`** - This is **essential** for proper token refresh functionality. Without this, your application may not handle token expiration correctly.

## Running the Application

### Step 1: Start Redis

```bash
docker run --rm --name my-redis -p 6379:6379 redis:7
```

### Step 2: Run the Quarkus Application

```bash
./mvnw quarkus:dev
```

### Step 3: Test Authentication

1. Open a browser and navigate to `http://localhost:8080/hello`
2. You'll be redirected to Google's login page
3. Complete authentication with your Google account
4. You'll be redirected back and see the "Hello from RESTEasy Reactive" message

## Available Endpoints

### Protected Endpoints (Require Authentication)
- **`GET /hello`** - Simple greeting endpoint
- **`GET /logout`** - Local logout (invalidates local session only)

### Public Endpoints  
- **`GET /logout/success`** - Logout success page

### Built-in OIDC Endpoints
- **`GET /q/oidc/code`** - OAuth callback endpoint (handled by Quarkus)
- **`GET /q/oidc/logout`** - Global OIDC logout endpoint (handled by Quarkus)

## Project Structure

```text
├── pom.xml
├── README.md
└── src
    └── main
        ├── java
        │   └── org
        │       └── acme
        │           ├── GreetingResource.java
        │           └── LogoutResource.java
        └── resources
            └── application.properties
```

## Key Dependencies

* `quarkus-oidc`: Core OIDC functionality
* `quarkus-oidc-redis-token-state-manager`: Redis-based token state management
* `quarkus-redis-client`: Redis connectivity
* `quarkus-rest-jackson`: RESTful web services

## How Redis Token Storage Works

When you authenticate:
1. Quarkus exchanges the authorization code for tokens with Google
2. The access token, refresh token, and ID token are stored in Redis
3. A session cookie containing a reference to the Redis key is sent to your browser
4. Subsequent requests use the session cookie to look up tokens from Redis

This approach provides:
- **Scalability**: Multiple application instances can share the same token store
- **Security**: Tokens are stored server-side, not in browser cookies
- **Session Management**: Easy to invalidate sessions by removing Redis entries

## Troubleshooting

### Redis Connection Issues
If you see Redis connection errors:
1. Ensure Docker is running
2. Verify Redis container is accessible on port 6379
3. Check that no firewall is blocking the connection

### Google OAuth Issues
If you see OAuth-related errors:
1. Verify your Client ID and Client Secret are correct
2. Ensure the redirect URI matches exactly: `http://localhost:8080/q/oidc/code`
3. Make sure your Google Cloud project has the necessary APIs enabled

### Token Refresh Issues
If tokens aren't refreshing properly:
1. Ensure `quarkus.oidc-client.grant.type=refresh` is set
2. Check that your Google OAuth client supports refresh tokens
3. Verify Redis is accessible and tokens are being stored

## Known Issues

### Manual Token Deletion from Redis

**⚠️ Important:** If you manually delete tokens from Redis while a session is active, it will cause a `NullPointerException` when the application tries to access the session:

```
java.lang.NullPointerException: Cannot invoke "io.quarkus.oidc.AuthorizationCodeTokens.getAccessToken()" because "session" is null
	at io.quarkus.oidc.runtime.CodeAuthenticationMechanism$5.apply(CodeAuthenticationMechanism.java:354)
	at io.quarkus.oidc.runtime.CodeAuthenticationMechanism$5.apply(CodeAuthenticationMechanism.java:351)
	at io.smallrye.context.impl.wrappers.SlowContextualFunction.apply(SlowContextualFunction.java:21)
	at io.smallrye.mutiny.operators.uni.UniOnItemTransformToUni$UniOnItemTransformToUniProcessor.performInnerSubscription(UniOnItemTransformToUni.java:68)
	at io.smallrye.mutiny.operators.uni.UniOnItemTransformToUni$UniOnItemTransformToUniProcessor.onItem(UniOnItemTransformToUni.java:57)
	...
```

**Solution:** Always use the proper logout endpoints (`/logout` or `/q/oidc/logout`) instead of manually deleting tokens from Redis. If you need to clear Redis for testing, also clear browser cookies or use an incognito window.

## Resources

- [Quarkus OIDC Guide](https://quarkus.io/guides/security-oidc-code-flow-authentication)
- [Google OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2)
- [Redis Documentation](https://redis.io/documentation)