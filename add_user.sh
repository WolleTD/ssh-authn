#!/bin/bash
set -eu

read -p "Username: " username
[ -n "$username" ] || { echo "A username is required!"; exit 1; }

useradd -m -s /usr/bin/bash $username

group=
genkey=
genotp=
genpwd=

echo "Which authentication method should be configured?"
select method in \
    "SK-SSH-Keys with User Verification" \
    "SSH-Keys and One-Time-Password" \
    "Password and One-Time-Password" \
    "Password only" \
    "SSH-Keys only"
do
    case "$method" in
        SK-SSH-Keys*)
            group=sk-ssh-key
            genkey=1
            ;;
        "SSH-Keys only")
            group=regular-ssh-key
            genkey=1
            ;;
        "SSH-Keys and"*)
            group=ssh-key-otp
            genotp=1
            genkey=1
            ;;
        "Password and"*)
            genotp=1
            genpwd=1
            ;;
        "Password only")
            genpwd=1
            ;;
        *)
            continue ;;
    esac
    break
done

# If group isn't empty, add the new user to it
[ -n "$group" ] && usermod -a -G $group $username

if [ $genkey ]; then
    # We are running inside of the docker container, the user has to generate their SSH keys
    # somewhere else and paste the public key into the prompt.
    [ "$group" = "sk-ssh-key" ] && sk=" -t ed25519-sk -O verify-required" || sk=

    echo -e "\nNow generate a keypair using \e[1mssh-keygen$sk\e[0m."
    echo -e "Additional parameters are optional.\n"
    echo "When done, paste the publickey from the generated .pub file here and hit enter."
    read -p "Enter public key: " pubkey
    runuser -u $username -- mkdir /home/$username/.ssh
    echo "$pubkey" | runuser -u $username -- tee /home/$username/.ssh/authorized_keys
    echo "Generated authorized_keys file."
fi

if [ $genpwd ]; then
    # Just run passwd...
    echo "Set a user password:"
    passwd $username
fi

if [ $genotp ]; then
    echo "Executing google-authenticator."
    # We are running interactively, so we can forward the user to the google-authenticator tool.
    # We won't let it ask silly questions though, but only use the code verification part.
    runuser -u $username -- google-authenticator \
        --time-based \
        --disallow-reuse \
        --no-rate-limit \
        --minimal-window \
        --force \
        --qr-mode=UTF8
fi

addr=$(ip addr show dev eth0 | awk '/inet /{sub(/\/.+/,"",$2);print $2}')
echo -e "User and authentication set up, now try logging in:\n"
echo -e "    \e[1mssh $username@$addr\e[0m"
