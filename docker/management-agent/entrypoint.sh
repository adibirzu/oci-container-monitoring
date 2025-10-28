#!/bin/bash
###############################################################################
# OCI Management Agent Sidecar Entrypoint Script
# Installs and configures Management Agent with Prometheus plugin
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
    wget -q "https://objectstorage.${OCI_REGION}.oraclecloud.com/n/idtskf8cjzhp/b/installer/o/Linux/latest/oracle.mgmt_agent.rpm" \
        -O /tmp/oracle.mgmt_agent.rpm

    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to download Management Agent"
        exit 1
    fi
    echo "Management Agent downloaded successfully"
fi

# Install Management Agent if not already installed
if [ ! -d "/opt/oracle/mgmt_agent/agent_inst" ]; then
    echo "Installing Management Agent..."
    rpm -ivh /tmp/oracle.mgmt_agent.rpm

    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to install Management Agent"
        exit 1
    fi
    echo "Management Agent installed successfully"
fi

# Generate wallet password
WALLET_PASSWORD=$(openssl rand -base64 32)

# Create input response file for agent setup
cat > /tmp/mgmt_agent_input.rsp <<EOF
ManagementAgentInstallKey=${MGMT_AGENT_INSTALL_KEY}
AgentDisplayName=$(hostname)-mgmt-agent-sidecar
CredentialWalletPassword=${WALLET_PASSWORD}
Service.plugin.prometheus.download=true
PrometheusEmitterUrl=http://localhost:9090
EOF

# Setup Management Agent if not already configured
if [ ! -f "/opt/oracle/mgmt_agent/agent_inst/config/mgmt_agent.properties" ]; then
    echo "Configuring Management Agent..."
    /opt/oracle/mgmt_agent/agent_inst/bin/setup.sh opts=/tmp/mgmt_agent_input.rsp

    if [ $? -ne 0 ]; then
        echo "WARNING: Agent setup encountered issues, will retry..."
        sleep 10
        /opt/oracle/mgmt_agent/agent_inst/bin/setup.sh opts=/tmp/mgmt_agent_input.rsp || true
    fi
    echo "Management Agent configured successfully"
fi

# Wait for agent to initialize
echo "Waiting for agent to initialize..."
sleep 15

# Configure Prometheus plugin
echo "Configuring Prometheus plugin..."
mkdir -p /opt/oracle/mgmt_agent/agent_inst/config/prometheus

# Generate Prometheus plugin configuration from template
cat > /opt/oracle/mgmt_agent/agent_inst/config/prometheus/prometheusPluginConfig.json <<PLUGEOF
{
  "entities": [
    {
      "namespace": "oci_prometheus_metrics",
      "metricNamespace": "${METRICS_NAMESPACE}",
      "resourceGroup": "$(hostname)-sidecar",
      "prometheusConfig": {
        "sourceUrl": "http://localhost:9090",
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

echo "Prometheus plugin configured successfully"

# Cleanup
rm -f /tmp/mgmt_agent_input.rsp
rm -f /tmp/oracle.mgmt_agent.rpm

echo "=========================================="
echo "Starting Management Agent..."
echo "=========================================="

# Start the agent (it will run in foreground)
if [ -f "/opt/oracle/mgmt_agent/agent_inst/bin/agentcore" ]; then
    echo "Agent is ready. Monitoring metrics from /metrics volume"
    echo "Logs available in /logs volume"

    # Keep container running and monitor agent
    while true; do
        # Check agent status
        /opt/oracle/mgmt_agent/agent_inst/bin/agentcore status || {
            echo "WARNING: Agent status check failed"
        }

        # Log agent activity
        if [ -f "/opt/oracle/mgmt_agent/agent_inst/log/mgmt_agent.log" ]; then
            tail -n 5 /opt/oracle/mgmt_agent/agent_inst/log/mgmt_agent.log > /logs/agent-latest.log
        fi

        sleep 60
    done
else
    echo "ERROR: Agent core binary not found"
    exit 1
fi
