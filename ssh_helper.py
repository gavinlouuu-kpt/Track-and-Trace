#!/usr/bin/env python3
"""SSH helper for remote deployment."""
import sys
import paramiko
import time

HOST = "100.81.210.49"
USER = "gavin"
PASSWORD = "2024"

def ssh_exec(cmd, timeout=120):
    """Execute a command via SSH and return output."""
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(HOST, username=USER, password=PASSWORD, timeout=10)

    stdin, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    out = stdout.read().decode('utf-8', errors='replace')
    err = stderr.read().decode('utf-8', errors='replace')
    exit_code = stdout.channel.recv_exit_status()

    client.close()

    if out:
        print(out, end='')
    if err:
        print(err, end='', file=sys.stderr)

    sys.exit(exit_code)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python ssh_helper.py <command>")
        sys.exit(1)

    cmd = " ".join(sys.argv[1:])
    ssh_exec(cmd)
