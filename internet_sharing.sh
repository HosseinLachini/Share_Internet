#!/bin/bash

set -e

echo "🌐 eLinux ↔️ PC Internet Sharing Setup Script"
echo "-------------------------------------------"

# Detect platform
arch=$(uname -m)
if [[ "$arch" == "x86_64" ]]; then
    ROLE="PC"
else
    ROLE="BOARD"
fi

echo "✅ Detected role: $ROLE"

list_all_interfaces() {
    echo
    echo "📡 Available network interfaces:"
    interfaces=()
    mapfile -t interfaces < <(ip -o link show | awk -F': ' '{print $2}' | grep -v lo)

    index=0
    for iface in "${interfaces[@]}"; do
        ipaddr=$(ip -4 -o addr show "$iface" | awk '{printf "%s ", $4}')
        if [[ -z "$ipaddr" ]]; then
            echo "  [$index] $iface (NO IP)"
        else
            echo "  [$index] $iface ($ipaddr)"
        fi
        index=$((index + 1))
    done
}

del_old_route() {
    echo "🔍 Search for old route ..."
    iface=$(ip route | grep default | awk '{print $5}')
    if [[ -n "$iface" ]]; then
        ipaddr=$(ip route | grep default | awk '{print $3}')
        echo "✅ Detected route via $iface and delete it."
        ip route del default via "$ipaddr" dev "$iface"
    else
        echo "ℹ️ No old route find."
    fi
}

# ----------------- PC Role -----------------
if [[ "$ROLE" == "PC" ]]; then
    echo
    echo "➡️ Acting as INTERNET PROVIDER (PC)."

    # Try to detect internet interface
    inet_if=$(ip route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<=NF;i++) if ($i=="dev") print $(i+1); exit}')
    if [[ -n "$inet_if" ]]; then
        echo "✅ Detected internet interface: $inet_if"
    else
        echo "⚠️ Could not auto-detect internet interface."
        list_all_interfaces
        read -p "🌐 Select INTERNET interface by number: " index
        mapfile -t all_ifaces < <(ip -o link show | awk -F': ' '{print $2}' | grep -v lo)
        inet_if="${all_ifaces[$index]}"
        echo "✅ Selected internet interface: $inet_if"
    fi

    # Now list interfaces except the internet one
    echo
    echo "🔌 Select the interface connected to eLinux:"
    filtered_ifaces=()
    mapfile -t filtered_ifaces < <(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | grep -v "^$inet_if$")

    index=0
    for iface in "${filtered_ifaces[@]}"; do
        ipaddr=$(ip -4 -o addr show "$iface" | awk '{printf "%s ", $4}')
        if [[ -z "$ipaddr" ]]; then
            echo "  [$index] $iface (NO IP)"
        else
            echo "  [$index] $iface ($ipaddr)"
        fi
        index=$((index + 1))
    done

    read -p "🔌 Select eLinux-connected interface by number: " jindex
    lan_if="${filtered_ifaces[$jindex]}"

    echo
    echo "✅ Enabling IP forwarding and configuring NAT..."
    sudo sysctl -w net.ipv4.ip_forward=1
    sudo iptables -t nat -A POSTROUTING -o $inet_if -j MASQUERADE
    sudo iptables -A FORWARD -i $lan_if -o $inet_if -j ACCEPT
    sudo iptables -A FORWARD -i $inet_if -o $lan_if -m state --state RELATED,ESTABLISHED -j ACCEPT

    echo "✅ NAT configuration complete. eLinux can now route internet through this machine."

# ----------------- BOARD Role -----------------
elif [[ "$ROLE" == "BOARD" ]]; then
    echo
     echo "➡️ Acting as eLinux BOARD (Client)."

    del_old_route

    list_all_interfaces
    read -p "🔌 Select the interface connected to PC by number: " index
    mapfile -t all_ifaces < <(ip -o link show | awk -F': ' '{print $2}' | grep -v lo)
    pc_if="${all_ifaces[$index]}"
    pc_ip=$(ip -4 -o addr show "$pc_if" | awk '{printf "%s ", $4}')
    pc_ip_mask=$(echo "$pc_ip" | awk -F'/' '{print $2}' | tr -d ' ')
    case "$pc_ip_mask" in
    "24")
        pc_ip_range=$(echo "$pc_ip" | cut -d '.' -f 1,2,3)".xxx"
        pc_ip_regex="^($(echo "$pc_ip" | cut -d '.' -f 1,2,3))(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){1}$"
        ;;
    "16")
        pc_ip_range=$(echo "$pc_ip" | cut -d '.' -f 1,2)".xxx.xxx"
        pc_ip_regex="^($(echo "$pc_ip" | cut -d '.' -f 1,2))(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){2}$"
        ;;
    esac

    while true; do
        # Prompt the user to enter an IP address
        read -p "🛣️  Enter the IP address of the PC's interface (e.g., $pc_ip_range): " pc_ip

        # Check if the IP address matches the regex pattern
        if [[ $pc_ip =~ $pc_ip_regex ]]; then
            echo "✅ The IP address $pc_ip is in the correct range ($pc_ip_range)."
            echo "🔍 Pinging $pc_ip..."
            if ping -c 2 $pc_ip >/dev/null; then
                echo "✅ PC is reachable."
                break
            else
                echo "❌ Cannot reach $pc_ip. Try again."
            fi
        else
            echo "❌ Invalid IP format. Try again."
        fi
    done
    

    echo
    echo "✅ Adding default route via $pc_ip..."
    sudo ip route add default via $pc_ip dev $pc_if || echo "⚠️ Route may already exist."

    echo "✅ Setting DNS to 8.8.8.8..."
    echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null

    echo
    echo "🌐 Testing internet connectivity..."
    if ping -c 2 8.8.8.8 >/dev/null; then
        echo "✅ Internet access confirmed (ping to 8.8.8.8 succeeded)."
    else
        echo "❌ Internet access failed."
        echo "🔧 Troubleshooting tips:"
        echo "  - Check that the PC has internet via selected interface."
        echo "  - Confirm that iptables rules are applied correctly on PC."
        echo "  - Check cable or USB link between PC and eLinux."
        echo "  - Ensure correct gateway IP ($pc_ip) and interface ($pc_if) are used."
    fi
fi

echo
echo "🎉 Setup script finished."
