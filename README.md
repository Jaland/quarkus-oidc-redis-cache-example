# Quarkus OIDC Redis NPE Reproduction

This project demonstrates a `NullPointerException` that occurs during the first OIDC authentication attempt when using Redis-based token state management with Quarkus OIDC and Google OAuth 2.0.

**Note:** This project includes a PKCE workaround (`quarkus.oidc.authentication.pkce-required=false`) based on community feedback to help reproduce the NPE condition.

## Overview

When using Quarkus OIDC with the Redis token state manager and Google OAuth 2.0, the application throws a `NullPointerException` on the **first** authentication attempt after a successful OAuth callback. Subsequent authentication attempts in the same session work correctly, indicating this is specifically a first-time initialization issue.

## 1. Prerequisites

* Java 17+
* Maven 3.8+
* Docker (for Redis)

## 2. Setup Google OAuth 2.0 Client

1. Go to the [Google Cloud Console Credentials page](https://console.cloud.google.com/apis/credentials).
2. Click **Create Credentials** > **OAuth client ID**.
3. Select **Web application** for the application type.
4. Give it a name (e.g., "Quarkus OIDC Test").
5. Under **Authorized redirect URIs**, add the following URI:
   * `http://localhost:8080/q/oidc/code`
6. Click **Create**.
7. Copy the **Client ID** and **Client Secret** that are generated.

## 3. Configure the Application

Open `src/main/resources/application.properties` and replace the placeholders with your credentials:

> [!NOTE]
> Recommend doing this with application-dev.properties as they are in the gitignore

```properties
quarkus.oidc.client-id=<PASTE_YOUR_GOOGLE_CLIENT_ID_HERE>
quarkus.oidc.credentials.secret=<PASTE_YOUR_GOOGLE_CLIENT_SECRET_HERE>
```

## 4. How to Reproduce the Issue

### Step 1: Start Redis

```bash
docker run --rm --name my-redis -p 6379:6379 redis:7
```

### Step 2: Run the Quarkus Application

```bash
./mvnw quarkus:dev
```

### Step 3: Trigger the Authentication Flow

1. Open a new **incognito/private** browser window to ensure no existing session.
2. Navigate to `http://localhost:8080/hello`.
3. You will be redirected to the Google login page.
4. Complete the authentication process with your Google account.
5. After successful authentication, you'll be redirected back to the application.

### Step 4: Test Logout Functionality (Optional)

Once authenticated, you can test the different logout options:

1. **Local logout**: Navigate to `http://localhost:8080/logout/local`
   - Logs out from the application but keeps your Google session active
   - Refreshing `/hello` will require re-authentication but won't show Google login

2. **Global logout**: Navigate to `http://localhost:8080/logout/global`  
   - Logs out from both the application and Google
   - Completely terminates all sessions

## Expected vs Actual Behavior

### Expected Behavior
After authenticating with Google and being redirected back to the application, you should see the "Hello from RESTEasy Reactive" message.

### Actual Behavior
After authenticating with Google and being redirected back to the application, the Quarkus application throws a `NullPointerException` in the logs. The browser will likely show an error page or 500 status.

If you immediately refresh the page or try to access `http://localhost:8080/hello` again in the same browser session, the authentication succeeds and you see the expected message. **The failure only happens on the very first attempt.**

## Expected Error Logs

When the NPE occurs, you should see something similar to this in the application logs:

```text
ERROR [io.qua.ver.htt.run.QuarkusErrorHandler] (vert.x-eventloop-thread-0) HTTP Request to /q/oidc/code has failed: java.lang.NullPointerException
        at io.quarkus.oidc.redis.runtime.RedisTokenStateManager.getTokens(RedisTokenStateManager.java:XX)
        at io.quarkus.oidc.runtime.CodeAuthenticationMechanism.authenticate(CodeAuthenticationMechanism.java:XXX)
        ...
```

## Debugging Information

This project includes additional logging configuration to help debug the issue:

```properties
quarkus.log.category."io.quarkus.oidc".level=DEBUG
quarkus.log.category."io.quarkus.oidc.redis".level=DEBUG
```

You can examine the logs to see the interaction between the OIDC components and Redis during the authentication flow.

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

* `quarkus-oidc`: Core OIDC functionality with built-in Redis token state management
* `quarkus-redis-client`: Redis connectivity (required for Redis token state management)
* `quarkus-resteasy-reactive-jackson`: RESTful web services

**Note:** Redis token state management is configured through properties (`quarkus.oidc.token-state-manager.strategy=redis`) rather than a separate dependency.

## Available Endpoints

### Protected Endpoints (Require Authentication)
- **`GET /hello`** - Simple greeting endpoint that requires authentication
- **`GET /logout`** - Logout with query parameter support:
  - `/logout` - Local logout (default)
  - `/logout?global=true` - Global logout (also logs out from Google)
- **`GET /logout/local`** - Local logout only (keeps Google session active)
- **`GET /logout/global`** - Global logout (redirects to Google logout)

### Public Endpoints  
- **`GET /logout/success`** - Logout success page (no authentication required)

### Built-in OIDC Endpoints
- **`GET /q/oidc/code`** - OAuth callback endpoint (handled by Quarkus)
- **`GET /q/oidc/logout`** - Global OIDC logout endpoint (handled by Quarkus)

## Troubleshooting

### PKCE Configuration

This project includes `quarkus.oidc.authentication.pkce-required=false` to help reproduce the NPE. This setting:
- Disables Proof Key for Code Exchange (PKCE) which can cause state cookie encryption issues
- Helps isolate the Redis token state manager NPE from other authentication complexities
- Is based on community feedback from similar reported issues

To test with PKCE enabled, remove this configuration or set it to `true`.

### Redis Connection Issues

If you see Redis connection errors, ensure:
1. Docker is running
2. Redis container is started and accessible on port 6379
3. No firewall is blocking the connection

### Google OAuth Issues

If you see OAuth-related errors:
1. Verify your Client ID and Client Secret are correct
2. Ensure the redirect URI in Google Console matches exactly: `http://localhost:8080/q/oidc/code`
3. Make sure your Google Cloud project has the necessary APIs enabled

### Clean Reproduction

To ensure a clean reproduction:
1. Stop the application
2. Clear Redis data: `docker exec my-redis redis-cli FLUSHALL`
3. Use a fresh incognito browser window
4. Restart the application and try again

## Additional Notes

* This issue appears to be related to the Redis token state manager's handling of the initial token storage or retrieval
* The fact that subsequent attempts work suggests a race condition or initialization issue
* The NPE specifically occurs during the OAuth callback processing phase
