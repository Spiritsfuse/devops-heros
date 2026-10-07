# ip address -- unique number identifier for a device
## Internet Protocol


Class A:  1 - 127 
Class B:  128 - 191
Class C: 192-223
Class D: 224-239

0.0.0.0 - 255.255.255.255

120.27.1.0/8
120.27.1.0/16

120.27.1.0

subnetmask: to dif -> host part and network part
255.0.0.0 - class A


197.23.45.10 - 255.255.255.0 - 197.23.34.255

120.27.1.0 - 255.0.0.0 - 120.255.255.255
### 197.23.45.10 - 255.255.255.0. - 197.23.45.255
class A

n/w bit == 8
host bits = 24
no.of hosts= 2^24
no.of usable hosts = (2^24 - 2)


# Range of private IP addresses:
10.0.0.0 - 10.255.255.255

class A
32 bits IP
class A has 8 bits network part.
32-8=24 Host part

120.27.1.0/8
8 network bits
24 host bits


194.23.56.10

255.0.0.0 - Class A
255.255.0.0 - Class B
255.255.255.0 - Class C


-----
finding host 

120.27.1.0 


## 197.23.45.10

---

### Hands-on Linux IP & Subnet Commands

```bash
# 1. Display all IP addresses and interface states
ip -br addr show

# 2. View active default gateway and routing table
ip route show

# 3. Calculate network, broadcast, and host range for a subnet
ipcalc 192.168.1.10/24
```

#### 💡 Command Breakdown (cmd-explained):
- `ip -br addr show`: Modern replacement for `ifconfig`.
  - `-br` (`--brief`): Formats output as a clean single-line table listing interface name (`eth0`, `lo`), operational status (`UP`/`DOWN`), and assigned IPv4/IPv6 CIDR addresses.
  - `addr show`: Queries the Linux kernel netlink interface for assigned addresses.
- `ip route show`: Displays kernel IP routing decisions. The line starting with `default via <gateway_ip> dev <interface>` identifies your router interface forwarding packets destined for external internet networks.
- `ipcalc 192.168.1.10/24`: Subnet calculator utility. Breaks down the CIDR block into Netmask (`255.255.255.0`), Wildcard, Network ID (`192.168.1.0`), HostMin (`192.168.1.1`), HostMax (`192.168.1.254`), Broadcast (`192.168.1.255`), and total usable hosts (`254`).

---

### 📚 Tech Jargons Demystified:
- **IPv4 Address**: A 32-bit logical address structured as 4 decimal octets separated by dots (e.g., `192.168.1.1`), uniquely identifying a host interface on an IP network.
- **Subnet Mask**: A 32-bit mask that delineates where the Network identifier ends and where individual Host identifiers begin (e.g. `255.255.255.0` reserves 24 bits for network and 8 bits for hosts).
- **Usable Hosts Formula ($2^H - 2$)**: In any IPv4 subnet with $H$ host bits, 2 addresses are reserved and cannot be assigned to machines: the all-zeros address (Network ID) and the all-ones address (Subnet Broadcast).
- **RFC 1918 Private IP Ranges**: Non-routable IP ranges reserved strictly for internal enterprise/home networks (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`). They cannot communicate on the public internet without a NAT gateway.
