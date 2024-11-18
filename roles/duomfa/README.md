# Duo MFA

A role to install and configure Duo Unix, Two-Factor Authentication, using `pam_duo`.

Tested on Debian 12, Ubuntu 22 and Ubuntu 24


## First Steps

From https://duo.com/docs/duounix

> 1. Sign up for a Duo account.
> 2. Log in to the Duo Admin Panel and navigate to Applications -> Protect an Application.
> 3. Locate UNIX Application in the applications list. Click Protect to get your **integration key, secret key, and API hostname**.

and put them in `duomfa_duo_config`, see the `defaults/main.yml` file.


## Is it possible to configure Duo Unix to accept either password or SSH key authentication?

The short answer is no, but there are workarounds.

From https://help.duo.com/s/article/2169

> The desired logic looks like:
> 
> 1. User opens a remote SSH session to the Unix system.
> 2. Unix system checks for the presence of valid SSH keys.
> 3. If valid SSH keys then prompt for 2FA, allowing access on successful 2FA (no password).
> 4. If no SSH keys, prompt for username and password.
> 5. If valid username and password, then prompt for 2FA.
> 
> The key item to remember is that the use of SSH keys and when to require them happens outside of PAM, directly in the sshd_config file itself. It ultimately falls under OpenSSH. This behavior presents some significant challenges for systems that have a mix of users that login with SSH keys or passwords, where it would be desirable to fallback to accepting either method for primary authentication before invoking Duo.

The article proposes a solution combining `pam_duo` and `login_duo`, but there is also CERN's [pam_2fa](https://github.com/CERN-CERT/pam_2fa/) module, which allows you to obtain the same results without using `login_duo`.


## Using pam_2fa

You need to build and install [pam_2fa](https://github.com/CERN-CERT/pam_2fa/), add `ExposeAuthInfo` to `duomfa_sshd_config` and update `duomfa_pam_common_auth` for `pam_ssh_user_auth.so`, see the `defaults/main.yml` file.