# ssh-session-recording

[PROOF OF CONCEPT] Github-based session authorization with session recording via asciinema.

## Installation:

### asciinema

```shell
apt-add-repository -y ppa:zanchey/asciinema
apt-get update > /dev/null
apt-get -y install asciinema 
asciinema auth
```

### forego

```shell
curl -o /tmp/forego-stable-linux-amd64.tgz https://bin.equinox.io/c/ekMN3bCZFUn/forego-stable-linux-amd64.tgz | tar zxC /usr/local/bin
```

### sshfront

```shell
wget -qO - https://github.com/gliderlabs/sshfront/releases/download/v0.2.1/sshfront_0.2.1_$(uname -sm|tr \  _).tgz | tar zxC /usr/local/bin
apt-get -y install libssl-dev python-dev python-cryptography python-pip python-virtualenv
virtualenv /usr/local/virtualenv/sshfront-handler
source /usr/local/virtualenv/sshfront-handler/bin/activate
pip install github3.py watchdog
```
write the auth-handler to `/usr/local/bin/auth-handler` and make it executable
write the ssh-handler to  `/usr/local/bin/ssh-handler` and make it executable

### Procfile

```yaml
sshfront: sshfront -a=/usr/local/bin/auth-handler -p=2222 /usr/local/bin/ssh-handler
watchmedo: watchmedo shell-command --pattern="*.log" --drop --ignore-directories --recursive --wait --command='if test "${watch_event_type}" = "modified"; then sleep 1; asciinema upload "${watch_src_path}"; fi' /var/log/asciinema
```

## Configuration

- `asciinema`:
  - command: `asciinema auth`
  - file: `~/.config/asciinema/config`
  - description: run the command, which will create a file that contains a token. The output will be a url you must visit to approve a token. This file can be templated out if necessary via configuration management.
  - example:
    ```
    [api]
    token = ASCIINEMA_TOKEN
    ```
- `auth-handler`:
  - command: N/A
  - file: `~/.config/auth-handler/config`
  - description: Contains an `auth-handler` section, with an `org`, comma-delimitedlist of `teams`, and a `token` for a user within the organization
  - example:
    ```
    [auth-handler]
    org = github
    teams = developers,operations
    token = GITHUB_TOKEN
    ```

## Usage

Start everything locally

```
forego run
```

And then try to ssh to your server

## Description

This repository will guide you through running a programmable ssh server called [sshfront](https://github.com/gliderlabs/sshfront). 
Upon any ssh attempt, `sshfront` will invoke an `auth-handler` with the `username` and `keyfile_contents` as arguments. The `auth-handler` is
written in python, and will attempt to use the github api in order to:

- retrieve the configured github organization's teams
- retrieves the teams that are whitelisted for SSH access
- check to see if the `username` matches a user within those teams
- exit `0` if there is a matching user in that team who has an ssh key matching `keyfile_contents`

On failure, the connection will be aborted.

On success, the `handler` will be invoked, which is a thin wrapper around invoking `asciinema`. `asciinema` will be configured
to write ssh output to a file in `/var/log/asciinema`. This happens on exit, and otherwise the session is kept in memory with `asciinema`.
The entire session is just a normal bash session that the user is free to do whatever they like in.

Outside of `sshfront`, we also run a `watchmedo` watcher. The `watchmedo` binary comes from the `watchdog` python package. This lets us run 
an arbitrary handler whenever a file is created, updated, or deleted. In our case, we run a handler to upload the asciinema video when it is
updated (created is too early as it is zero-length then). We can't do this via a `trap` or other trick in the `ssh-handler` as ssh connections
may be violently torn down.


### Caveats

The demo is run as root, so all ssh sessions will be given root. This may be mitigated by running the ssh session as another user.

Neither sshfront nor asciinema have been audited for security errors. If you run them, it may be possible to break out or privilege escalate.

### Future Enhancements

- Create a `disconnected-handler` for auto-uploading `asciinema` casts instead of having a separate command.
- If the above isn't possible, use a programmable watcher written in golang like [reflex](https://github.com/cespare/reflex).
- Rewrite auth-handler in golang and distribute as a binary. Or rewrite in bash with only `python` as a dependency for json parsing.
- Bundling `auth-handler` and `ssh-handler` - via [go-basher](https://github.com/progrium/go-basher) - with `sshfront` as a single binary.
- Use short-lived cache for calls to the github `api`, especially for retrieving the initial organization/teams.
- Better logging.
