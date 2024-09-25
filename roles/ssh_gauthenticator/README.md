# ssh one-time passcodes mfa with google authenticator

This role installs google-authenticator and initializes one-time passcodes on the first ssh connection.

The role's default configuration is to disable password authentication, enable public key authentication and configure pam and ssh to support the “Challange Response Authentication” and “Keyboard Interactive” functions required by google-authenticator.

This role has only been tested with Debian.
