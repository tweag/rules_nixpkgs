FROM ubuntu:23.04

RUN apt-get update -qq && \
    apt-get install openssh-server curl xz-utils sudo locales ca-certificates -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -m 0755 /nix && \
    groupadd -r nixbld && \
    chown root /nix && \
    for n in $(seq 1 10); do useradd -c "Nix build user $n" -d /var/empty -g nixbld -G nixbld -M -N -r -s "$(command -v nologin)" "nixbld$n"; done

RUN curl -L https://nixos.org/nix/install | bash

COPY .github/nix-server/keys .

RUN cat ci.pub > $HOME/.ssh/authorized_keys

RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo ". /root/.nix-profile/etc/profile.d/nix.sh" >> $HOME/.bashrc && \
    ln -sf /root/.nix-profile/bin/nix-store /usr/bin/ && \
    ln -sf /root/.nix-profile/bin/nix-daemon /usr/bin/

CMD ["/usr/sbin/sshd", "-D"]
