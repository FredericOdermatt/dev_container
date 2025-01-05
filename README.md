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

**Build Locally**

```bash
docker build --secret id=chezmoi_read_token,src=/home/frederic/chezmoi_read_token -f Dockerfile -t container_zsh .
```

Todo

- [x] zsh show user and machine in left prompt
- [ ] vimrc / neovim configs
- [ ] default extensions VSC
- [x] docker socket expose
- [ ] vscode to container on remote
