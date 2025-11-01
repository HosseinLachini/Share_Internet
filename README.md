[![Latest Release](https://img.shields.io/github/v/release/HosseinLachini/Share_Internet)](https://github.com/HosseinLachini/Share_Internet/releases)
[![License](https://img.shields.io/badge/license-GPL--2.0-informational)](#license)
[![Stars](https://img.shields.io/github/stars/HosseinLachini/Share_Internet?style=social)](https://github.com/HosseinLachini/Share_Internet/stargazers)

# 🛠️ eLinux ↔️ PC Internet Sharing Script

This Bash script configures IP forwarding from a Linux PC to an eLinux board to provide internet access to the board.

---

## 📦 Features

- Automatic detection of PC vs eLinux board
- Auto or manual selection of interfaces
- NAT configuration using iptables
- DNS and route setup on the board
- Internet connectivity test

---

## 🚀 Usage

1. Download the script:

```bash   
git clone git@github.com:HosseinLachini/Share_Internet.git
cd Share_Internet
```

    
2. Run on the PC:

![run on PC](img/Linux_PC.png)

```bash    
./internet_sharing.sh
```
    
> Will auto-detect internet and ask which interface connects to the board.

3. Run on the eLinux board:

![run on Linux Board](img/Linux_Board.png)
  
```bash    
./internet_sharing.sh
```
    
> Will ask for interface to PC, IP address, and check internet connectivity.

---

## 💡 Requirements

- PC and board both running Linux
- iptables, ip, and ping available
- Script must be run as a user with sudo access

---

## 🔧 Troubleshooting

If internet doesn't work:

- Ensure PC has internet
- Run script on PC *before* running it on the board
- Check USB/Ethernet cable
- Confirm IP and interface are correct
- On PC, verify iptables -t nat -L includes MASQUERADE rule

---

## 📁 Files

- [internet_sharing.sh](internet_sharing.sh) — the main script
- [README.md](README.md) — this manual

---

## 👤 Author

**Hossein Lachini**  
📫 [GitHub](https://github.com/HosseinLachini) • [LinkedIn](https://www.linkedin.com/in/hossein-lachini/)

## 🪪 License

This project is licensed under the **GPL-2.0** License — see the [LICENSE](LICENSE) file for details.