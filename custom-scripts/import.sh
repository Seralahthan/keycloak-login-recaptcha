#!/bin/bash

export KEYCLOAK_HOME=/opt/keycloak
KCADM=$KEYCLOAK_HOME/bin/kcadm.sh
FLOW_ALIAS=recaptcha-flow
EXECUTION_PROVIDER_ID=recaptcha-u-p-form  

for i in {1..10}; do
    $KCADM config credentials --server http://localhost:8080 --realm master --user "$KC_BOOTSTRAP_ADMIN_USERNAME" --password "$KC_BOOTSTRAP_ADMIN_PASSWORD"
    if [ $? -ne 0 ]; then
        echo "Authentication failed. Retrying..."
        sleep 5
        continue
    fi

    custom_realm=$($KCADM get realms/"$REALM_NAME")
    if [ -z "$custom_realm" ]; then
        echo "Creating realm..."
        $KCADM create realms -s realm="${REALM_NAME}" -s enabled=true -s registrationAllowed=true -s sslRequired=none

        echo "Creating flow..."
        FLOW_ID=$($KCADM create authentication/flows -r "$REALM_NAME" -s alias="$FLOW_ALIAS" -s providerId=basic-flow -s topLevel=true -s builtIn=false -i)
        
        echo "Adding standard executions to flow..."
        COOKIE_ID=$($KCADM create authentication/flows/"$FLOW_ALIAS"/executions/execution -r "$REALM_NAME" -b '{"provider": "auth-cookie"}' -i)
        $KCADM update authentication/flows/"$FLOW_ALIAS"/executions -r "$REALM_NAME" -b '{"id": "'"$COOKIE_ID"'", "requirement": "ALTERNATIVE"}'
        
        SPNEGO_ID=$($KCADM create authentication/flows/"$FLOW_ALIAS"/executions/execution -r "$REALM_NAME" -b '{"provider": "auth-spnego"}' -i)
        $KCADM update authentication/flows/"$FLOW_ALIAS"/executions -r "$REALM_NAME" -b '{"id": "'"$SPNEGO_ID"'", "requirement": "DISABLED"}'
        
        IDP_ID=$($KCADM create authentication/flows/"$FLOW_ALIAS"/executions/execution -r "$REALM_NAME" -b '{"provider": "identity-provider-redirector"}' -i)
        $KCADM update authentication/flows/"$FLOW_ALIAS"/executions -r "$REALM_NAME" -b '{"id": "'"$IDP_ID"'", "requirement": "ALTERNATIVE"}'

        echo "Adding execution..."
        EXECUTION_ID=$($KCADM create authentication/flows/"$FLOW_ALIAS"/executions/execution -r "$REALM_NAME" -b '{"provider" : "'"$EXECUTION_PROVIDER_ID"'"}' -i)
        if [ -z "$EXECUTION_ID" ]; then
            echo "Failed to create execution. Check provider ID."
            exit 1
        fi
        echo "Created execution with ID: $EXECUTION_ID"
        
        echo "Setting reCAPTCHA config..."
        $KCADM create authentication/executions/"$EXECUTION_ID"/config -r "$REALM_NAME" -b '{"alias": "recaptcha-config", "config": {"siteKey": "'"$RECAPTCHA_SITE_KEY"'", "siteSecret": "'"$RECAPTCHA_SECRET_KEY"'", "apiConnectTimeout": "1000", "maxHttpConnections": "5", "apiSocketTimeout": "1000", "apiConnectionRequestTimeout": "1000", "httpStatsInterval": "0"}}'

        # $KCADM update realms/${REALM_NAME} -s browserFlow=$FLOW_ALIAS

        $KCADM update realms/${REALM_NAME} -f $KEYCLOAK_HOME/objects/security-defenses.json

        $KCADM update realms/${REALM_NAME} -s loginTheme=mytheme

        $KCADM update realms/master -s sslRequired=none

        echo "Creating user..."
        $KCADM create users -r $REALM_NAME \
            -s username=$USER_NAME \
            -s enabled=true \
            -s email=user@example.com \
            -s firstName=John \
            -s lastName=Doe \
            -s emailVerified=true
        $KCADM set-password -r $REALM_NAME --username $USER_NAME --new-password $USER_PASS

        echo "Creating client 'high-security-client'..."
        CLIENT_ID=$($KCADM create clients -r $REALM_NAME -b '{
          "clientId": "high-security-client",
          "enabled": true,
          "publicClient": true,
          "protocol": "openid-connect",
          "standardFlowEnabled": true,
          "directAccessGrantsEnabled": true,
          "redirectUris": ["http://localhost:8090/*"],
          "webOrigins": ["http://localhost:8090"]
        }' -i)
        
        echo "Client created with ID: $CLIENT_ID"
        
        echo "Setting authentication flow binding override..."
        echo "Flow ID to bind: $FLOW_ID"
        $KCADM update clients/"$CLIENT_ID" -r "$REALM_NAME" -s "authenticationFlowBindingOverrides.browser=$FLOW_ID"
        
        echo "Verifying flow binding..."
        $KCADM get clients/$CLIENT_ID -r $REALM_NAME | grep -A 2 "authenticationFlowBindingOverrides"

        echo "Setup complete!"
        break
    else
        echo "Realm already exists. Skipping."
        break
    fi
    sleep 5
done

if [ $i -eq 10 ]; then
    echo "Setup failed after 10 attempts."
    exit 1
fi