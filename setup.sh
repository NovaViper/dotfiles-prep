#!/usr/bin/env sh


cd "$HOME" || exit

DISTRO=$(awk -F'=' '/^ID=/ { gsub("\"","",$2); print tolower($2) } ' /etc/*-release 2>/dev/null)
pinentry_type=""

echo "Running GPG+SSH setup routines"
if [ "${DISTRO}" = "arch" ] || [ "${DISTRO}" = "endeavouros" ]; then
    sudo pacman --noconfirm -S --needed yubikey-manager yubikey-personalization yadm

    if [ "${DISTRO}" = "endeavouros" ]; then
        sudo pacman --noconfirm -S --needed openssh
    fi

elif [ "${DISTRO}" = "linuxmint" ] || [ "${DISTRO}" = "ubuntu" ] || [ "${DISTRO}" = "debian" ]; then
    sudo apt install yubikey-manager yubikey-personalization scdaemon yadm
fi

while true; do
    read -p "What desktop environment are you using? ([K]de, [C]innamon) " de
    case $de in
        K | k | Kde | kde | KDE)
            pinentry_type="qt"
            break
            ;;
        C | c | cinnamon | Cinnamon | CINNAMON)
            pinentry_type="gtk"
            break
            ;;
        *)
            echo "Please enter a valid parameter."
            sleep 5
            ;;
    esac
done

echo "Killing gpg-connect-agent in order to create ~/.gnupg folder"
gpg-connect-agent /bye || exit

echo "Creating gpg-agent.conf with the pinentry program selected based on desktop environment and ssh support enabled"
cat > ~/.gnupg/gpg-agent.conf<< EOF
enable-ssh-support
pinentry-program /usr/bin/pinentry-$pinentry_type
EOF

echo "Setting the environment variables"
export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/gnupg/S.gpg-agent.ssh"
export GPG_TTY="$(tty)"

echo "Restarting gpg-agent"
pkill gpg-agent && gpg-connect-agent /bye || exit
