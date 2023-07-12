# For no particular reason
FROM debian:bookworm

# Let's build a demo container to showcase some advanced SSH and sudo login options.
# We want to install openssh-server, libpam-google-authenticator, sudo
# Add iproute2 to report the containers IP address after adding a user
# Also, create the required /run/sshd directory to save another RUN statement.
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    openssh-server \
    libpam-google-authenticator \
    sudo \
    iproute2 && \
    mkdir /run/sshd

# We use this single container for various authentication methods for SSH:
# 1. SK-SSH-Keys with User Verification (SSH: publickey only)
# 2. SSH-Key and TOTP (SSH: publickey + keyboard-interactive)
# 3. Password and TOTP (SSH: keyboard-interactive)
#
# The obvious issue is, that this setup requires three different configurations of
# AuthenticationMethods, as the PAM stack doesn't get any knowledge about what kind
# of publickey authentication already happened.
# Additionally, the PAM stack must exit after TOTP validation in the second case, but
# that's doable with the pam_succeed_if module between TOTP and password stage matching
# on a specific group.
# The first and third case don't conflict each other, but we want to provide a separate
# group for testing so we can omit creating TOTP codes for SK-SSH users without having
# them drop into a broken interactive authentication because they have not TOTP config.
RUN groupadd ssh-key-otp && groupadd sk-ssh-key && groupadd regular-ssh-key

# Debian supplies a drop-in directory for sshd_config, see the file for additional documentation
COPY sshd_auth.conf /etc/ssh/sshd_config.d/auth.conf

# Add the modified copy of PAM sshd configuration.
COPY pam_sshd /etc/pam.d/sshd

# google-authenticator --time-based --disallow-reuse --no-rate-limit --minimal-window --force --no-confirm -QUTF8

COPY add_user.sh /usr/local/bin/add_user

CMD ["/usr/sbin/sshd", "-D"]
