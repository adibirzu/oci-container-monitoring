#!/bin/bash
###############################################################################
# OCI Management Agent Sidecar Entrypoint Script
# Installs, registers, and runs Management Agent with Prometheus plugin
###############################################################################

set -e

echo "=========================================="
echo "OCI Management Agent Sidecar"
echo "=========================================="
echo "Region: ${OCI_REGION}"
echo "Metrics Namespace: ${METRICS_NAMESPACE}"
echo "Prometheus Scrape Interval: ${PROMETHEUS_SCRAPE_INTERVAL}"
echo "=========================================="

# Validate required environment variables
if [ -z "$MGMT_AGENT_INSTALL_KEY" ]; then
    echo "ERROR: MGMT_AGENT_INSTALL_KEY environment variable is required"
    exit 1
fi

# Download Management Agent if not already present
if [ ! -f "/tmp/oracle.mgmt_agent.rpm" ]; then
    echo "Downloading Management Agent..."
    echo "URL: https://objectstorage.${OCI_REGION}.oraclecloud.com/n/idtskf8cjzhp/b/installer/o/Linux/latest/oracle.mgmt_agent.rpm"

    # Download with progress and timeout
    wget --verbose --timeout=300 --tries=3 \
        "https://objectstorage.${OCI_REGION}.oraclecloud.com/n/idtskf8cjzhp/b/installer/o/Linux/latest/oracle.mgmt_agent.rpm" \
        -O /tmp/oracle.mgmt_agent.rpm 2>&1 | tee /tmp/download.log

    DOWNLOAD_STATUS=$?
    if [ $DOWNLOAD_STATUS -ne 0 ]; then
        echo "ERROR: Failed to download Management Agent (exit code: $DOWNLOAD_STATUS)"
        echo "Download log:"
        cat /tmp/download.log
        echo ""
        echo "Possible causes:"
        echo "  1. Network connectivity issues"
        echo "  2. Invalid region: ${OCI_REGION}"
        echo "  3. Download URL changed or moved"
        echo "  4. Firewall blocking outbound connections"
        exit 1
    fi

    # Verify downloaded file
    if [ ! -s "/tmp/oracle.mgmt_agent.rpm" ]; then
        echo "ERROR: Downloaded file is empty or doesn't exist"
        ls -lh /tmp/oracle.mgmt_agent.rpm
        exit 1
    fi

    FILE_SIZE=$(stat -f%z "/tmp/oracle.mgmt_agent.rpm" 2>/dev/null || stat -c%s "/tmp/oracle.mgmt_agent.rpm" 2>/dev/null)
    echo "✓ Management Agent downloaded successfully (${FILE_SIZE} bytes)"
fi

# Install Management Agent if not already installed
if [ ! -d "/opt/oracle/mgmt_agent/agent_inst" ]; then
    echo "Installing Management Agent RPM..."
    echo "Running: rpm -ivh /tmp/oracle.mgmt_agent.rpm"

    rpm -ivh /tmp/oracle.mgmt_agent.rpm 2>&1 | tee /tmp/rpm-install.log
    RPM_STATUS=$?

    if [ $RPM_STATUS -ne 0 ]; then
        echo "ERROR: Failed to install Management Agent RPM (exit code: $RPM_STATUS)"
        echo "RPM installation log:"
        cat /tmp/rpm-install.log
        exit 1
    fi

    # Verify installation
    if [ -d "/opt/oracle/mgmt_agent/agent_inst" ]; then
        echo "✓ Management Agent RPM installed successfully"
        ls -la /opt/oracle/mgmt_agent/agent_inst/ | head -20
    else
        echo "ERROR: Installation directory not created"
        exit 1
    fi
fi

# Generate secure wallet password (minimum 8 chars with complexity requirements)
WALLET_PASSWORD=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9!@#$%^&*' | head -c 16)aA1!

# Create input response file for agent setup
echo "Creating response file for agent registration..."
cat > /tmp/mgmt_agent_input.rsp <<EOF
ManagementAgentInstallKey=${MGMT_AGENT_INSTALL_KEY}
AgentDisplayName=$(hostname)-mgmt-agent
CredentialWalletPassword=${WALLET_PASSWORD}
Service.plugin.prometheus.download=true
EOF

# Setup and register Management Agent if not already configured
if [ ! -f "/opt/oracle/mgmt_agent/agent_inst/config/mgmt_agent.properties" ]; then
    echo "=========================================="
    echo "Registering Management Agent with OCI..."
    echo "=========================================="
    echo "This performs:"
    echo "  1. Validating install key"
    echo "  2. Generating communication wallet"
    echo "  3. Generating security artifacts"
    echo "  4. Registering with OCI Management Agent service"
    echo "=========================================="

    # Run agent setup (this registers the agent with OCI)
    echo "Executing setup.sh with response file..."
    echo "Install Key: ${MGMT_AGENT_INSTALL_KEY:0:20}...${MGMT_AGENT_INSTALL_KEY: -10}"
    echo "Agent Name: $(hostname)-mgmt-agent"

    /opt/oracle/mgmt_agent/agent_inst/bin/setup.sh opts=/tmp/mgmt_agent_input.rsp 2>&1 | tee /tmp/setup.log
    SETUP_STATUS=$?

    if [ $SETUP_STATUS -ne 0 ]; then
        echo "ERROR: Agent setup and registration failed (exit code: $SETUP_STATUS)"
        echo ""
        echo "Setup log:"
        cat /tmp/setup.log
        echo ""
        echo "Agent log (if available):"
        cat /opt/oracle/mgmt_agent/agent_inst/log/mgmt_agent.log 2>/dev/null || echo "No log file available yet"
        echo ""
        echo "Please check:"
        echo "  1. Install key is valid and not expired"
        echo "  2. IAM policies allow container instance to register agent"
        echo "  3. Resource Principal authentication is working"
        echo "  4. Network connectivity to OCI services (*.oraclecloud.com)"
        exit 1
    fi

    echo "✓ Management Agent registered successfully with OCI"
else
    echo "✓ Management Agent already registered"
fi

# Wait for agent registration to complete
echo "Waiting for agent registration to finalize..."
sleep 10

# Configure Prometheus plugin
echo "Configuring Prometheus plugin..."
mkdir -p /opt/oracle/mgmt_agent/agent_inst/config/prometheus

# Generate Prometheus plugin configuration
cat > /opt/oracle/mgmt_agent/agent_inst/config/prometheus/prometheusPluginConfig.json <<PLUGEOF
{
  "entities": [
    {
      "namespace": "oci_prometheus_metrics",
      "metricNamespace": "${METRICS_NAMESPACE}",
      "resourceGroup": "$(hostname)",
      "prometheusConfig": {
        "sourceUrl": "http://localhost:9090/metrics",
        "scrapeInterval": "${PROMETHEUS_SCRAPE_INTERVAL}",
        "scrapeTimeout": "${PROMETHEUS_SCRAPE_TIMEOUT}"
      }
    }
  ]
}
PLUGEOF

# Set correct ownership if oracle user exists
if id "oracle" &>/dev/null; then
    chown -R oracle:oracle /opt/oracle/mgmt_agent/agent_inst/config/prometheus
fi

echo "✓ Prometheus plugin configured"

# Cleanup sensitive data
rm -f /tmp/mgmt_agent_input.rsp
rm -f /tmp/oracle.mgmt_agent.rpm

echo "=========================================="
echo "Starting Management Agent..."
echo "=========================================="

# Start the agent service
if [ -f "/opt/oracle/mgmt_agent/agent_inst/bin/agentcore" ]; then
    # Start agent in background
    /opt/oracle/mgmt_agent/agent_inst/bin/agentcore start

    # Wait for agent to start
    sleep 5

    # Verify agent is running
    /opt/oracle/mgmt_agent/agent_inst/bin/agentcore status
    if [ $? -eq 0 ]; then
        echo "✓ Management Agent started successfully"
        echo "✓ Agent is now collecting and forwarding metrics to OCI Monitoring"
        echo ""
        echo "Monitoring Details:"
        echo "  - Namespace: ${METRICS_NAMESPACE}"
        echo "  - Scrape Interval: ${PROMETHEUS_SCRAPE_INTERVAL}"
        echo "  - Metrics Source: http://localhost:9090/metrics"
        echo "=========================================="
    else
        echo "ERROR: Agent failed to start properly"
        cat /opt/oracle/mgmt_agent/agent_inst/log/mgmt_agent.log 2>/dev/null || echo "No log file available"
        exit 1
    fi

    # Keep container running and monitor agent health
    echo "Container running. Monitoring agent health..."
    while true; do
        # Check agent status every 60 seconds
        /opt/oracle/mgmt_agent/agent_inst/bin/agentcore status > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "WARNING: Agent status check failed - attempting restart"
            /opt/oracle/mgmt_agent/agent_inst/bin/agentcore start
            sleep 10
        fi

        # Copy latest log entries to /logs volume for external monitoring
        if [ -f "/opt/oracle/mgmt_agent/agent_inst/log/mgmt_agent.log" ]; then
            tail -n 100 /opt/oracle/mgmt_agent/agent_inst/log/mgmt_agent.log > /logs/agent-latest.log 2>/dev/null || true
        fi

        sleep 60
    done
else
    echo "ERROR: Agent core binary not found at /opt/oracle/mgmt_agent/agent_inst/bin/agentcore"
    exit 1
fi
