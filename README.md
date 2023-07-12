# Example container for SSH authentication methods

The container runs `sshd` and has some custom configuration to provide
three different ways of two-factor authentication. It also contains
an `add_user` script to help adding example users and configuring their
authentication.

## Building and running

To build and run the container, execute the following commands:

```bash
docker build . -t ssh-authn-example
docker run -d --init --rm --name ssh-authn ssh-authn-example
```

This will build and image named `ssh-authn-example` and start a container
named `ssh-authn`, running in the background (`-d`). The container can
be stopped by executing `docker stop ssh-authn`. The `--rm` flag is optional
and will cause the container and all it's state to be removed when stopped.
The `--init` flag is useful to stop the container sanely, as `sshd` for
example won't react to Ctrl+C.

## Adding users and logging in

To add a new user to the running container, execute the following command:

```bash
docker exec -it ssh-authn add_user
```

Follow the instructions of the script. You will have to generate SSH keys on
the host and/or scan a QR Code with an Authenticator App on your phone.

After successful registration, the script will report an SSH command, e.g.
`ssh test@172.17.0.3`. Executing it will prompt the selected authentication
methods an establish an SSH connection to the container. Depending on your
setup and key generation, you may have to add additional parameters like the
identity file.

## Caveats

That's it, basically. Please note that this setup is purely made for demonstration
purposes and I wouldn't use this configuration in production. Using pam_succeed_if
is a hack to make password and TOTP work in parallel with pubkey and TOTP.

In a real world application, if a system should use 2FA for SSH, one of the factors
should always be an SSH public key. They are a field tested and secure technology.
In that case, the PAM configuration can contain a single "sufficient" module without
wonky group logic (then again, it's pretty cool that this is possible).

To usefully support more than one authentication method in PAM in parallel, one would
have to resort back to some module supporting that use case or creating a custom one.

Using SK-backed public keys with required User Verification provides a 2FA method that's
contained within SSHs pubkey authentication. Unfortunately, that means it has to either
be the only 2FA method on a server or offered to a statically defined group of users
by making use of `Match` statements in the `sshd_config`.
