# SSH

## SSH to the nodes from your machine

The nodes are reached through a frontend (`ProxyJump`): the frontend only forwards the connection, so nothing runs on
it. Both hops authenticate by your Kerberos ticket (`kinit $USER@META`), so `~/.ssh/config` needs:

```ssh-config
Host nympha
    HostName nympha.zcu.cz

# MetaCentrum nodes (add the domain of a node that is not covered): through the frontend, into your job there
Host *.metacentrum.cz *.cesnet.cz *.cerit-sc.cz *.fav.zcu.cz *.meta.zcu.cz *.muni.cz *.cuni.cz *.elixir-czech.cz
    ProxyJump nympha
    RequestTTY yes
    RemoteCommand /storage/plzen1/home/<you>/tools/metaenv/bin/metacentrum/job shell

Host nympha *.metacentrum.cz *.cesnet.cz *.cerit-sc.cz *.fav.zcu.cz *.meta.zcu.cz *.muni.cz *.cuni.cz *.elixir-czech.cz
    GSSAPIAuthentication yes
    GSSAPIDelegateCredentials yes
    GSSAPIKeyExchange yes
```

`GSSAPIKeyExchange` verifies the host by Kerberos, so a new node does not ask to accept its host key. The patterns
match also the `HostName` of an alias, so a machine that is not a node but is in these domains (e.g. your server
`*.fav.zcu.cz`, a frontend other than nympha) needs a block before them; the first value of an option wins:

```ssh-config
Host myserver.fav.zcu.cz skirit.ics.muni.cz
    ProxyJump none
    RemoteCommand none
    RequestTTY auto
```

`ssh -G <host> | grep -Ei 'proxyjump|remotecommand'` shows what a host gets.

`ssh <node>` then gives a shell inside your session (`job session`) on that node, batch jobs are not considered; with
more of your sessions there it asks which one, and VS Code (no terminal to ask in) refuses with their list. Without a
session on the node it refuses too, work on a node belongs to a job. Into a batch job by its id:
`ssh -o RemoteCommand='<…>/job shell <id>' <node>`; to the node itself (e.g. the scratch of a failed job):
`ssh -o RemoteCommand=none <node>`.

A command or a file transfer to a node (`ssh <node> <command>`, `scp`, `rsync`) does not go with RemoteCommand, SSH
refuses both at once; give it `-o RemoteCommand=none` (rsync: `-e 'ssh -o RemoteCommand=none'`).

VS Code (Remote - SSH) opens a folder on the node, `code --remote ssh-remote+<node> <folder>` as `job session` prints
it, through the same configuration. It skips RemoteCommand unless its setting allows it, once in its `settings.json`:

```json
"remote.SSH.enableRemoteCommand": true
```

## SSH on the nodes

`ssh` on a node (also of `scp`, `rsync`, git and `uv sync` with git dependencies) works as on the frontend, with
nothing to set up. It reads `~/.ssh` of the home in passwd (`getent passwd $USER`), the node's own one, not of `HOME`
set by `job shell`; `job shell` therefore links `~/.ssh` there to `~/.ssh` of `HOME` when it is missing, once for every
storage a node logs you into. An existing `~/.ssh` there stays, `job shell` prints how to replace it.

`uv sync` hides any question of ssh behind its progress and hangs, also on the frontend: a host new to `known_hosts`
(connect to it once by `ssh`) or a key with a passphrase. For the latter, the default key without a passphrase (on the
frontend, added to the git server):

```bash
ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519
```
