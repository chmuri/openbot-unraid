#!/usr/bin/env python3
"""
OpenBot Server & Telemetry Agent for Unraid OS.
Provides WebUI, telemetry endpoints, and hardware peripheral mapping (USB/Serial, BLE, Cameras).
"""

import os
import sys
import glob
import logging
from http.server import HTTPServer, BaseHTTPRequestHandler
import json

PORT = int(os.environ.get("OPENBOT_PORT", "8080"))
CONFIG_DIR = os.environ.get("OPENBOT_CONFIG_DIR", "/config")
DATA_DIR = os.environ.get("OPENBOT_DATA_DIR", "/data")
LOG_LEVEL = os.environ.get("LOG_LEVEL", "INFO").upper()

logging.basicConfig(
    level=getattr(logging, LOG_LEVEL, logging.INFO),
    format="%(asctime)s [%(levelname)s] %(message)s"
)
logger = logging.getLogger("OpenBot")

class OpenBotHTTPHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            response = {"status": "healthy", "service": "openbot", "port": PORT}
            self.wfile.write(json.dumps(response).encode("utf-8"))
        elif self.path == "/api/status" or self.path == "/":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            
            serial_devices = glob.glob("/dev/ttyUSB*") + glob.glob("/dev/ttyACM*")
            video_devices = glob.glob("/dev/video*")
            dri_devices = glob.glob("/dev/dri/*")
            
            status = {
                "name": "OpenBot Unraid Edition",
                "version": os.environ.get("OPENBOT_VERSION", "1.0.0"),
                "status": "online",
                "config_dir": CONFIG_DIR,
                "data_dir": DATA_DIR,
                "peripherals": {
                    "serial_ports": serial_devices,
                    "video_cameras": video_devices,
                    "dri_nodes": dri_devices,
                    "dbus_bluetooth": os.path.exists("/var/run/dbus/system_bus_socket")
                }
            }
            self.wfile.write(json.dumps(status, indent=2).encode("utf-8"))
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        logger.debug("%s - - [%s] %s" % (self.client_address[0], self.log_date_time_string(), format % args))

def run():
    logger.info("Starting OpenBot Unraid Server...")
    logger.info(f"Port: {PORT}")
    logger.info(f"Volume paths: CONFIG={CONFIG_DIR}, DATA={DATA_DIR}")
    
    server_address = ("0.0.0.0", PORT)
    httpd = HTTPServer(server_address, OpenBotHTTPHandler)
    logger.info(f"Server listening on http://0.0.0.0:{PORT}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        logger.info("Stopping OpenBot server...")
        httpd.server_close()
        sys.exit(0)

if __name__ == "__main__":
    run()
