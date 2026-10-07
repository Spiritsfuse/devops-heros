# Docker Resources

- https://docs.docker.com/get-started/docker-overview/
- https://www.geeksforgeeks.org/devops/architecture-of-docker/

```bash
docker stop $(docker ps -q)
```
- `docker ps -q` → gets IDs of running containers
- `docker stop` → stops them

#### 💡 Command Breakdown (cmd-explained):
- `$(...)`: Command substitution in Bash/Linux shell. Executes the nested command first and passes its stdout as arguments to the outer command.
- `docker ps -q`: `-q` (`--quiet`) suppresses headers and table columns, outputting only the numeric hexadecimal Container IDs of active running containers.
- `docker stop`: Dispatches `SIGTERM` to each returned Container ID for clean process termination.

```bash
docker rm $(docker ps -aq)
```
* `docker ps -aq` → gets IDs of all containers, including stopped ones
* `docker rm` → removes them

#### 💡 Command Breakdown (cmd-explained):
- `docker ps -aq`: Combines `-a` (`--all`, showing exited, created, and running containers) with `-q` (numeric IDs only).
- `docker rm`: Frees up host storage by deleting the writable filesystem layers of all stopped containers.

Force remove all containers

If you want to stop + remove all containers in one command:

```bash
docker rm -f $(docker ps -aq)
```

#### 💡 Command Breakdown (cmd-explained):
- `docker rm -f`: `-f` (`--force`) issues a `SIGKILL` to forcefully terminate running containers before immediately removing them, bypassing the need to run `docker stop` first.

3. Remove all Docker images
```bash
docker rmi $(docker images -q)
```

Force remove all images
```bash
docker rmi -f $(docker images -q)
```

#### 💡 Command Breakdown (cmd-explained):
- `docker images -q`: Lists only the Image IDs of all locally cached images.
- `docker rmi`: Deletes images from local storage.
- `-f` (`--force`): Forces image removal even if multiple tags reference the same image ID or if stopped containers still reference it.

For a complete Docker cleanup:
```bash
docker system prune -a --volumes
```

#### 💡 Command Breakdown (cmd-explained):
- `docker system prune`: Deep-cleans unreferenced Docker objects across the entire engine.
- `-a` (`--all`): Removes all unused images (not just dangling ones without tags).
- `--volumes`: Prunes all unused anonymous and unattached persistent volumes to reclaim disk space.

---

### 📚 Tech Jargons Demystified:
- **Dangling Images**: Images that have no name or tag (displayed as `<none>:<none>`). They typically occur when you rebuild an image with an existing tag, leaving the old layers untagged.
- **Command Substitution (`$()`)**: A Unix shell feature that executes the inner command in a subshell and replaces the string with its standard output, allowing dynamic piping of IDs between CLI tools.
- **Container Cleanup**: Unstopped and unremoved containers consume disk space in `/var/lib/docker/containers/` and keep ports or volume locks occupied. Routine pruning keeps the local development environment clean.



