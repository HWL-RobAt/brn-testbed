
elementclass RAWDEV { DEVNAME $devname, DEVICE $device |

  input[0]
  -> rawdev_suppressor::Suppressor()
  -> pullstats::PullStats()
  -> todev::ToDevice(DEVNAME $devname, METHOD LINUX, DEBUG false, BURST 1);



  fromdev::FromDevice(DEVNAME $devname, PROMISC true, SNAPLEN 8190, OUTBOUND true, SNIFFER false, METHOD LINUX, HEADROOM 64, BURST 1)
  -> SetTimestamp()
  -> BRN2SetDeviceAnno(DEVICE $device)
  -> [0]output;
}

elementclass RAWWIFIDEV { DEVNAME $devname, DEVICE $device |


  cst::ChannelStats(DEVICE $device, STATS_DURATION 1000, PROCFILE "/proc/net/madwifi/ath0/channel_utility", PROCINTERVAL 1000, NEIGHBOUR_STATS true, FULL_STATS false, SAVE_DURATION 1000 );
  rawdev::RAWDEV(DEVNAME $devname, DEVICE $device);


  input[0]
  -> WifiSeq()
  -> BrnRadiotapEncap()
  -> rawdev;

  rawdev
  -> dev_decap::BrnRadiotapDecap()
  -> cst
  -> [0]output;
}

BRNAddressInfo(deviceaddress wlan0:eth);
wireless::BRN2Device(DEVICENAME "wlan0", ETHERADDRESS deviceaddress, DEVICETYPE "WIRELESS");

id::BRN2NodeIdentity(NAME NODENAME, DEVICES wireless);

Idle
  -> wifidevice::RAWWIFIDEV(DEVNAME wlan0, DEVICE wireless)
  -> discard::Discard;

sys_info::SystemInfo(NODEIDENTITY id, CPUTIMERINTERVAL 1000);

ControlSocket(tcp, 7777);