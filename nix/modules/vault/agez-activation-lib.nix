#
# Lib functions to generate NixOS activation scripts to decrypt and
# set up Age secrets.
#
{ config, lib, pkgs, ... }:
let
  age = "${pkgs.age}/bin/age";
  ageKey = config.odbox.vault.agez.key;
  ageDir = config.odbox.vault.agez.dir;
  locale = config.i18n.defaultLocale or "C";
  join = lib.strings.concatStringsSep "\n";
in rec {

  # Wipe out the secrets dir from the previous activation (if any),
  # then set up a fresh one where to decrypt secrets for the current
  # NixOS activation.
  setup = ''
    echo "[agez] setting up base dir: ${ageDir}"
    rm -rf "${ageDir}" || true
    mkdir "${ageDir}"
    chmod 0755 "${ageDir}"
  '';

  # Extract the content of an Age-encrypted file into a clear-text file.
  decrypt = {
    # Path to the Age-encrypted file.
    encryptedFile,
    # Path to the file that will contain the decrypted content.
    decryptedFile,
    ...
  }:
  ''
    echo "[agez] decrypting: ${encryptedFile} to: ${decryptedFile}"
    mkdir -p $(dirname "${decryptedFile}")
    LANG=${locale} ${age} \
        -d -i "${ageKey}" \
        -o "${decryptedFile}" "${encryptedFile}"
  '';

  # Set up ownership and permissions for a decrypted file.
  assign = {
    # Path to the file that contains the decrypted content.
    decryptedFile,
    # The username or ID of the user who should own the decrypted file.
    # Defaults to the root user.
    user ? "0",
    # The group name or ID of the group who should have access to the
    # decrypted file. Defaults to the root group.
    group ? "0",
    # File permissions in `chmod` format. Defaults to `0400`.
    perms ? "0400",
    ...
  }:
  ''
    echo "[agez] assigning ownership and permissions to: ${decryptedFile}"
    chown "${user}:${group}" "${decryptedFile}"
    chmod ${perms} "${decryptedFile}"
  '';

  # Generate the activation script to decrypt the given files.
  # Notice you'd typically insert this script after the `specialfs`
  # which mounts a `tmpfs` on `/run`. In fact, typically the base
  # directory containing decrypted files should be under `/run` so
  # the decrypted files sit in memory instead of disk.
  #
  # Args:
  # - xs. A list of sets, each in the format accepted by `decrypt`.
  makeDecryptionScript = xs: join ([ setup ] ++ map decrypt xs);

  # Generate the activation script to assign ownership and permissions
  # to the decrypted files.
  # Notice you've got to insert this script after the `users` and `groups`
  # scripts as well as the above `makeDecryptionScript`. In fact, this
  # script assumes the Age files have been decrypted and users/groups
  # have been set up.
  #
  # Args:
  # - xs. A list of sets, each in the format accepted by `assign`.
  makeAssignmentScript = xs: join (map assign xs);

}