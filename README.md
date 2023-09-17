# wireguard-add-routes
Wireguard with ip route added

This configuration is usable with Daktela WireGuard VPN.

# Install
- install packages (these packages need to be installed: https://www.wireguard.com/install/#installation ), this is only example
  - `wireguard-dkms`
  - `wireguard-tools`
- copy /etc/wireguard/* to your system
- edit /etc/wireguard/daktelawg.conf and fill
  - \__ADD_KEY__
  - \__ADD_YOUT_PRIVATE_IP__
  - \__ADD_SERVER_VPN__
  - \__ADD_SERVER_PORT__
  - \__ADD_SERVER_DNS__
- `systemctl start wg-quick@daktelawg`
- `systemctl enable wg-quick@daktelawg`
- check connection with `wg show daktelawg`

