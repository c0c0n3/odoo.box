#
# A collection of widely-used Linux sys-admin tools.
# You can use most of these tools on MacOS too since we automatically
# remove the few packages that are Linux-specific when instantiating
# the Nix expression on MacOS.
#
{ pkgs }:
with pkgs;
let
  isLinux = stdenv.isLinux;
  ifLinux = ps: if isLinux then ps else [];
in rec {

  core = [
    coreutils      # universal basic file, shell and text tools
    inetutils      # common net tools: ping, traceroute, hostname, whois, ftp,
                   # telnet, etc.
  ] ++ ifLinux [
    util-linux     # common sys tools
  ];

  devices = ifLinux [
    hwinfo         # probe available hardware
    pciutils       # probe PCI bus
    usbutils       # probe connected USB devices
  ];

  disk = [
    dua            # disk analyser---better du
    duf            # disk usage---better df
    smartmontools  # control & monitor disks through S.M.A.R.T.
  ] ++ ifLinux [
    hdparm         # manage hardware params & test disk performance
    parted         # partition editor
    sdparm         # complements hdparm
  ];

  filesystem = [
    bat            # cat w/ syntax highlighting and automatic paging
    eza            # file listing w/ tree view too---better ls
    ripgrep        # text search---better grep
    ripgrep-all    # also search in PDFs, zip, tar.gz, etc.
  ];

  processes = [
    lsof           # fds, sockets, pipes, etc. processes are using
    procs          # process viewer---better ps
  ];

  network = [
    bandwhich      # bandwidth usage monitor
    curl           # transfer data using various network protocols
    dogdns         # DNS lookup client---better dig
    gping          # ping with a graph
    netcat         # read and write over TCP or UDP
    nmap           # network scanner
    openssh        # secure networking utilities based on the SSH protocol
    tcpdump        # packet analyser
    trippy         # fancy net diagnostics---better traceroute + ping + mtr
  ] ++ ifLinux [
    ethtool        # view & modify NIC and driver params
    iproute2       # manage & monitor network interfaces---ip, ss, etc.
  ];

  version-control = [
    git
  ];

  compression = [
    zip
    unzip
  ];

  text-processing = [
    jq
  ];

  misc = ifLinux [
    lesspipe
    mkpasswd
  ];

  all = core ++ devices ++ disk ++ filesystem ++ processes ++ network ++
        version-control ++ compression ++ text-processing ++ misc;

}