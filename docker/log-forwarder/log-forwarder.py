#!/usr/bin/env python3
"""
OCI Log Forwarder Sidecar
Monitors log files and forwards them to OCI Logging service
Uses Resource Principal authentication for secure access
"""

import os
import sys
import time
import json
import logging
from datetime import datetime
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import oci
from oci.loggingingestion import LoggingClient
from oci.loggingingestion.models import PutLogsDetails, LogEntryBatch, LogEntry

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('log-forwarder')

class LogForwarder:
    """Forwards logs from shared volume to OCI Logging"""

    def __init__(self):
        self.log_mount_path = os.getenv('LOG_MOUNT_PATH', '/logs')
        self.log_file = os.getenv('LOG_FILE', 'application.log')
        self.log_ocid = os.getenv('LOG_OCID', '')
        self.log_header = os.getenv('LOG_HEADER', 'container-logs')
        self.batch_size = int(os.getenv('BATCH_SIZE', '100'))
        self.flush_interval = int(os.getenv('FLUSH_INTERVAL', '5'))

        self.log_path = os.path.join(self.log_mount_path, self.log_file)
        self.position = 0
        self.buffer = []
        self.last_flush = time.time()

        # Initialize OCI client with Resource Principal
        try:
            signer = oci.auth.signers.get_resource_principals_signer()
            self.logging_client = LoggingClient(config={}, signer=signer)
            logger.info("✓ Initialized OCI Logging client with Resource Principal")
        except Exception as e:
            logger.error(f"✗ Failed to initialize OCI client: {e}")
            logger.info("Will continue monitoring logs but won't forward to OCI")
            self.logging_client = None

        logger.info(f"Log Forwarder Configuration:")
        logger.info(f"  Log Path: {self.log_path}")
        logger.info(f"  Log OCID: {self.log_ocid[:50]}..." if self.log_ocid else "  Log OCID: Not configured")
        logger.info(f"  Batch Size: {self.batch_size}")
        logger.info(f"  Flush Interval: {self.flush_interval}s")

    def read_new_logs(self):
        """Read new log entries from the log file"""
        try:
            if not os.path.exists(self.log_path):
                return []

            with open(self.log_path, 'r') as f:
                f.seek(self.position)
                lines = f.readlines()
                self.position = f.tell()
                return [line.strip() for line in lines if line.strip()]
        except Exception as e:
            logger.error(f"Error reading log file: {e}")
            return []

    def create_log_entry(self, message):
        """Create an OCI LogEntry object"""
        return LogEntry(
            data=message,
            id=f"{int(time.time() * 1000)}",
            time=datetime.utcnow()
        )

    def flush_buffer(self):
        """Flush buffered logs to OCI Logging"""
        if not self.buffer or not self.logging_client or not self.log_ocid:
            self.buffer = []
            return

        try:
            log_entries = [self.create_log_entry(msg) for msg in self.buffer]

            log_entry_batch = LogEntryBatch(
                entries=log_entries,
                source=self.log_header,
                type="application",
                defaultlogentrytime=datetime.utcnow()
            )

            put_logs_details = PutLogsDetails(
                specversion="1.0",
                log_entry_batches=[log_entry_batch]
            )

            self.logging_client.put_logs(
                log_id=self.log_ocid,
                put_logs_details=put_logs_details
            )

            logger.info(f"✓ Forwarded {len(self.buffer)} log entries to OCI Logging")
            self.buffer = []
            self.last_flush = time.time()

        except Exception as e:
            logger.error(f"✗ Error forwarding logs: {e}")
            # Keep buffer for retry

    def process_logs(self):
        """Process new log entries"""
        new_logs = self.read_new_logs()

        if new_logs:
            logger.debug(f"Read {len(new_logs)} new log entries")
            self.buffer.extend(new_logs)

            # Flush if buffer is full or flush interval exceeded
            should_flush = (
                len(self.buffer) >= self.batch_size or
                (time.time() - self.last_flush) >= self.flush_interval
            )

            if should_flush:
                self.flush_buffer()

    def run(self):
        """Main loop"""
        logger.info("=" * 60)
        logger.info("OCI Log Forwarder Started")
        logger.info("=" * 60)
        logger.info(f"Monitoring: {self.log_path}")
        logger.info(f"Press Ctrl+C to stop")
        logger.info("=" * 60)

        try:
            while True:
                self.process_logs()
                time.sleep(1)

        except KeyboardInterrupt:
            logger.info("\nShutting down gracefully...")
            if self.buffer:
                logger.info("Flushing remaining logs...")
                self.flush_buffer()
            logger.info("Stopped.")
        except Exception as e:
            logger.error(f"Fatal error: {e}")
            sys.exit(1)

class LogFileHandler(FileSystemEventHandler):
    """Watchdog event handler for log file changes"""

    def __init__(self, forwarder):
        self.forwarder = forwarder

    def on_modified(self, event):
        if not event.is_directory and event.src_path == self.forwarder.log_path:
            self.forwarder.process_logs()

def main():
    """Main entry point"""
    forwarder = LogForwarder()

    # Start file watcher
    event_handler = LogFileHandler(forwarder)
    observer = Observer()
    observer.schedule(event_handler, forwarder.log_mount_path, recursive=False)
    observer.start()

    try:
        forwarder.run()
    finally:
        observer.stop()
        observer.join()

if __name__ == "__main__":
    main()
