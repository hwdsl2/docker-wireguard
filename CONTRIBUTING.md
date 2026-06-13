# Contributing

Thanks for helping improve this project. This repository maintains the Docker image for WireGuard; bare-metal install script changes belong in [wireguard-install](https://github.com/hwdsl2/wireguard-install).

## Before You Start

- Search existing issues and pull requests.
- Keep changes focused and easy to review.
- For upstream WireGuard behavior, check the upstream project first.
- Do not include private keys, client `.conf` files, env secrets, VPN credentials, or logs with secrets.

## Pull Requests

- Update `README.md`, env examples, or compose examples when behavior changes.
- Include the Docker host OS, architecture, image tag, and start method tested.
- Note whether kernel WireGuard or `wireguard-go` was used when relevant.

## Testing

Test the smallest relevant path before opening a PR, for example:

- Build or run the image when Dockerfile/runtime behavior changes.
- Exercise client add/remove/show paths when client management changes.
- Verify container logs, routing, and backend selection when runtime scripts change.
- Run ShellCheck when editing shell scripts.
