# Dev Container

My docker dev container

**Base Execution**
```bash
docker run -it --rm fredericodermatt1/dev-container
```

**Expose Base Docker Socket**
```bash
docker run -it --rm --group-add 988 -v /var/run/docker.sock:/var/run/docker.sock fredericodermatt1/dev-container
```

Todo

- [x] zsh show user and machine in left prompt
- [ ] vimrc / neovim configs
- [ ] default extensions VSC
- [x] docker socket expose
- [ ] vscode to container on remote
