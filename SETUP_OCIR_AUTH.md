# OCIR Authentication Setup Guide

## Quick Setup Instructions

### Step 1: Create Auth Token in OCI Console

1. Open your browser and go to: https://cloud.oracle.com
2. Sign in to your OCI account
3. Click on your **profile icon** (top right corner)
4. Select **My Profile**
5. In the left menu under **Resources**, click **Auth Tokens**
6. Click **Generate Token** button
7. Enter description: `OCIR Docker Push`
8. Click **Generate Token**
9. **⚠️ COPY THE TOKEN IMMEDIATELY** (you won't be able to see it again!)

### Step 2: Update Configuration File

Your OCI username has been identified as: **alexandru.birzu@oracle.com**

Edit this file:
```bash
/Users/abirzu/dev/oci-monitoring/config/oci-monitoring.env
```

Find these lines (around line 72-73):
```bash
export OCIR_USERNAME="frxfz3gch4zb/YOUR_OCI_USERNAME"
export OCIR_PASSWORD=""
```

Replace them with:
```bash
export OCIR_USERNAME="frxfz3gch4zb/alexandru.birzu@oracle.com"
export OCIR_PASSWORD="YOUR_AUTH_TOKEN_FROM_STEP_1"
```

**Important**: Also remove or comment out the duplicate empty `OCIR_USERNAME=""` on line 99

### Step 3: Build and Push Docker Images

After saving the config file, run:

```bash
cd /Users/abirzu/dev/oci-monitoring/docker
./build-all.sh
```

This will:
- Login to OCIR using your credentials
- Build 3 Docker images:
  1. Management Agent Sidecar
  2. Prometheus Sidecar
  3. Application with Metrics
- Push all images to: `fra.ocir.io/frxfz3gch4zb/oci-monitoring/`

Expected time: **15-30 minutes**

### Step 4: Enable Sidecar Architecture

After images are successfully pushed, edit the config file again:

```bash
/Users/abirzu/dev/oci-monitoring/config/oci-monitoring.env
```

Change these settings (around lines 36 and 52-54):
```bash
# Disable legacy
export ENABLE_MANAGEMENT_AGENT="false"

# Enable sidecar architecture
export ENABLE_SHARED_VOLUMES="true"
export ENABLE_MANAGEMENT_AGENT_SIDECAR="true"
export ENABLE_PROMETHEUS_SIDECAR="true"
```

### Step 5: Deploy with Sidecars

```bash
cd /Users/abirzu/dev/oci-monitoring
./scripts/deploy.sh deploy
```

---

## Quick Command Reference

```bash
# View your OCI username
oci iam user list --compartment-id $(oci iam compartment list --query 'data[0]."compartment-id"' --raw-output) \
  --query 'data[?"lifecycle-state"==`ACTIVE`].name' --output table

# Test OCIR login manually
docker login fra.ocir.io
# Username: frxfz3gch4zb/alexandru.birzu@oracle.com
# Password: <your-auth-token>

# Check if images exist in OCIR
oci artifacts container image list \
  --compartment-id ocid1.compartment.oc1..aaaaaaaagy3yddkkampnhj3cqm5ar7w2p7tuq5twbojyycvol6wugfav3ckq \
  --query 'data.items[].{"Repository":"repository-name"}' --output table
```

---

## Troubleshooting

### Error: "denied: Anonymous users are only allowed read access"
- **Cause**: Auth token not configured or incorrect
- **Solution**: Double-check username format and auth token

### Error: "unauthorized: authentication required"
- **Cause**: Auth token expired or invalid
- **Solution**: Generate a new auth token

### Build succeeds but push fails
- **Cause**: Network or permissions issue
- **Solution**: Check IAM policies allow you to push to OCIR

---

## Security Notes

- **Never commit** the auth token to git
- Auth tokens expire after you regenerate them
- You can have multiple auth tokens (useful for CI/CD)
- Store the token securely (password manager recommended)

---

**Current Status**:
- ✅ OCI Namespace detected: `frxfz3gch4zb`
- ✅ Your username identified: `alexandru.birzu@oracle.com`
- ⏳ Auth token: Needs to be created
- ⏳ Docker images: Ready to build after auth setup

**Once you complete Steps 1-2, let me know and I'll help with the build process!**
