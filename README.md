# Keycloak Login reCAPTCHA Extension

A Keycloak Authenticator SPI extension that adds Google reCAPTCHA v2 protection to the login flow with per-client configuration support.

## Features

- ✅ **Google reCAPTCHA v2 integration** - Adds bot protection to your Keycloak login forms
- ✅ **Per-client authentication flow binding** - Configure different authentication flows for different clients
- ✅ **Custom theme support** - Extends the Keycloak base theme with reCAPTCHA widget
- ✅ **Automated setup** - Includes scripts for automatic realm and client configuration
- ✅ **Docker-based development** - Quick setup with docker-compose
- ✅ **Containerized success page** - Visual confirmation after successful authentication

## Architecture

This extension implements the Keycloak Authenticator SPI to add reCAPTCHA verification as a custom authentication step. The implementation includes:

- **Custom Authenticator** (`RecaptchaUsernamePasswordForm`) - Handles the authentication logic with reCAPTCHA validation
- **Custom Theme** - Extends `keycloak.v2` base theme to include the reCAPTCHA widget in the login form
- **REST Handler** - Manages HTTP connections to Google's reCAPTCHA verification API
- **HTTP Connection Pool** - Optimizes API calls with configurable connection pooling and statistics

## Prerequisites

- Java 21 or higher
- Maven 3.6+
- Docker and Docker Compose
- Google reCAPTCHA v2 keys (see setup instructions below)

## Getting Started

### 1. Register for Google reCAPTCHA

1. Go to [Google reCAPTCHA Admin Console](https://www.google.com/recaptcha/admin/create)
2. Fill in the registration form:
   - **Label**: Give it a name (e.g., "Keycloak Development")
   - **reCAPTCHA type**: Select **reCAPTCHA v2** → "I'm not a robot" Checkbox
   - **Domains**: Add `localhost` (for local testing)
3. Submit the form
4. Copy both the **Site Key** and **Secret Key** - you'll need these in the next step

### 2. Configure Environment Variables

1. Copy the environment template file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and add your reCAPTCHA keys:
   ```bash
   # Get your keys from: https://www.google.com/recaptcha/admin
   RECAPTCHA_SITE_KEY=your_recaptcha_site_key_here
   RECAPTCHA_SECRET_KEY=your_recaptcha_secret_key_here
   
   # Test user credentials for the realm
   USER_NAME=testuser
   USER_PASS=testpassword
   ```

### 3. Build the Project

Build the extension JAR file using Maven:

```bash
mvn clean package
```

This will create `target/recaptcha-login.jar` which contains:
- The custom authenticator implementation
- Service provider configuration
- JBoss deployment descriptors

### 4. Start the Services

Launch Keycloak and the success page using Docker Compose:

```bash
docker-compose up -d
```

This starts two containers:
- **keycloak** (port 8090) - Keycloak server with the reCAPTCHA extension
- **success-page** (port 8091) - Nginx server displaying the post-login success page

### 5. Monitor the Setup

Watch the Keycloak logs to ensure the realm and client are configured correctly:

```bash
docker logs -f keycloak
```

Wait for the message: `Running the server in development mode. DO NOT use this configuration in production.`

You should also see logs indicating:
- Extension loaded successfully
- Realm `test-realm` created
- Authentication flow `recaptcha-flow` configured
- Client `high-security-client` created with flow binding

### 6. Test the Login Flow

Once Keycloak is ready, test the authentication flow:

1. Open the following URL in your browser:
   ```
   http://localhost:8090/realms/test-realm/protocol/openid-connect/auth?client_id=high-security-client&redirect_uri=http://localhost:8091/&response_type=code&scope=openid
   ```

2. You should see the Keycloak login page with:
   - Username field
   - Password field
   - **reCAPTCHA widget** ("I'm not a robot" checkbox)

3. Enter the credentials:
   - **Username**: The value you set in `USER_NAME` (default: `testuser`)
   - **Password**: The value you set in `USER_PASS` (default: `testpassword`)

4. Complete the reCAPTCHA challenge

5. Upon successful authentication, you'll be redirected to the success page showing:
   - "Successfully Logged In!" message
   - Session information
   - Authorization code

### 7. Access the Admin Console

Manage your Keycloak configuration through the admin console:

1. Navigate to: http://localhost:8090/
2. Click **Administration Console**
3. Login with:
   - **Username**: `admin`
   - **Password**: `admin`

From here you can:
- View/edit the `test-realm` realm
- Inspect the `recaptcha-flow` authentication flow
- Configure the `high-security-client` client
- Adjust reCAPTCHA settings in the execution configuration

## Implementation Details

### Custom Theme

The project includes a custom theme (`mytheme`) that extends the Keycloak v2 base theme:

**Location**: `themes/mytheme/login/`

**Key Files**:
- `login.ftl` - Modified login template with reCAPTCHA widget integration
- `theme.properties` - Theme configuration extending `keycloak.v2`
- `resources/css/custom.css` - Custom styling for the login page

The theme adds the Google reCAPTCHA JavaScript library and renders the widget in the login form, seamlessly integrating with Keycloak's existing form handling.

### Automated Configuration Script

The `custom-scripts/import.sh` script automatically configures Keycloak on startup:

**Realm Setup**:
- Creates `test-realm` with registration enabled
- Configures SSL requirement to `none` for local development
- Applies security headers from `objects/security-defenses.json`
- Sets the custom theme (`mytheme`) as the login theme

**Authentication Flow**:
- Creates a custom flow named `recaptcha-flow`
- Adds standard executions: Cookie, SPNEGO, Identity Provider Redirector
- Adds the custom `recaptcha-u-p-form` execution with reCAPTCHA configuration
- Configures reCAPTCHA with:
  - Site key and secret from environment variables
  - Connection timeout settings
  - HTTP connection pool parameters
  - Statistics interval

**Client Configuration**:
- Creates `high-security-client` as a public OpenID Connect client
- Sets redirect URI to `http://localhost:8091/` (success page)
- Binds the client to use `recaptcha-flow` for browser authentication
- Enables standard flow and direct access grants

**Test User**:
- Creates a test user from environment variables
- Sets email, first name, and last name
- Marks email as verified

### reCAPTCHA Configuration Parameters

The authenticator supports the following configuration parameters:

- `siteKey` - Google reCAPTCHA site key
- `siteSecret` - Google reCAPTCHA secret key
- `apiConnectTimeout` - Connection timeout in milliseconds (default: 1000)
- `apiSocketTimeout` - Socket timeout in milliseconds (default: 1000)
- `apiConnectionRequestTimeout` - Connection request timeout in milliseconds (default: 1000)
- `maxHttpConnections` - Maximum HTTP connections in the pool (default: 5)
- `httpStatsInterval` - Statistics logging interval in seconds (0 = disabled)

## Project Structure

```
├── src/main/java/org/keycloak/extensions/recaptcha/
│   ├── HttpStats.java                          # HTTP pool statistics collector
│   ├── RecaptchaUsernamePasswordForm.java      # Main authenticator implementation
│   ├── RecaptchaUsernamePasswordFormFactory.java # SPI factory
│   ├── RestConfiguration.java                  # HTTP client configuration
│   └── RestHandler.java                        # reCAPTCHA API client
├── src/main/resources/META-INF/
│   ├── jboss-deployment-structure.xml          # JBoss module dependencies
│   └── services/
│       └── org.keycloak.authentication.AuthenticatorFactory
├── themes/mytheme/login/                       # Custom login theme
├── custom-scripts/import.sh                    # Automated setup script
├── objects/security-defenses.json              # Browser security headers
├── success-page/index.html                     # Post-login success page
├── docker-compose.yml                          # Docker services configuration
├── .env.example                                # Environment variables template
└── pom.xml                                     # Maven project configuration
```

## Development

### Rebuilding After Changes

If you modify the Java code:

```bash
# Rebuild the JAR
mvn clean package

# Restart Keycloak to load the new version
docker-compose restart keycloak

# Watch the logs
docker logs -f keycloak
```

### Theme Development

Theme changes are hot-reloaded in development mode. Simply:

1. Edit files in `themes/mytheme/login/`
2. Refresh your browser (Ctrl+F5 to clear cache)
3. No restart required

### Viewing Configuration

Access the reCAPTCHA execution configuration:

```bash
# Get the client ID
docker exec keycloak /opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080 --realm master --user admin --password admin

docker exec keycloak /opt/keycloak/bin/kcadm.sh get clients \
  -r test-realm -q clientId=high-security-client
```

## Troubleshooting

### reCAPTCHA Not Showing

1. Check browser console for JavaScript errors
2. Verify `RECAPTCHA_SITE_KEY` is correctly set in `.env`
3. Ensure the theme is set: Check Admin Console → Realm Settings → Themes → Login Theme = `mytheme`

### Authentication Fails with reCAPTCHA Error

1. Verify `RECAPTCHA_SECRET_KEY` is correct in `.env`
2. Check Keycloak logs: `docker logs keycloak | grep recaptcha`
3. Ensure you completed the reCAPTCHA challenge

### Redirect URI Mismatch

1. Ensure the success-page container is running: `docker ps`
2. Verify the redirect URI exactly matches: `http://localhost:8091/`
3. Check client configuration in Admin Console → Clients → high-security-client → Valid Redirect URIs

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `RECAPTCHA_SITE_KEY` | Google reCAPTCHA v2 site key | Yes |
| `RECAPTCHA_SECRET_KEY` | Google reCAPTCHA v2 secret key | Yes |
| `USER_NAME` | Test user username | Yes |
| `USER_PASS` | Test user password | Yes |
| `KC_BOOTSTRAP_ADMIN_USERNAME` | Keycloak admin username | No (default: admin) |
| `KC_BOOTSTRAP_ADMIN_PASSWORD` | Keycloak admin password | No (default: admin) |
| `REALM_NAME` | Name of the realm to create | No (default: test-realm) |

## License

See [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Resources

- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [Keycloak SPI Documentation](https://www.keycloak.org/docs/latest/server_development/)
- [Google reCAPTCHA](https://www.google.com/recaptcha/about/)
- [Keycloak Themes Guide](https://www.keycloak.org/docs/latest/server_development/#_themes)
