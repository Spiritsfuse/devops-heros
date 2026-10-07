# Session 8 Screenshots

This directory stores verified execution screenshots for Docker container networking and volume persistence:
- `01_networks_created.png`: Verification of custom bridge networks via `docker network ls`.
- `02_frontend_to_backend_ping.png`: Verification of frontend to backend connectivity.
- `03_frontend_to_database_isolation.png`: Strict network isolation between frontend and database.
- `04_backend_to_database_ping.png`: Backend communicating with database on shared network.
- `05_host_network_apache-cmd.png`: Launching Apache container in host network mode (`--network host`).
- `05_host_network_apache-web.png`: Apache web page accessed directly on host port 80.
- `06_bind_mount_initial-cmd.png`: Running Nginx with bind mounted volume.
- `06_bind_mount_initial-web.png`: Initial page displaying Hello students.
- `07_bind_mount_modified-cmd.png`: Editing host index.html without restarting container.
- `07_bind_mount_modified-web.png`: Live update reflected immediately in browser.
