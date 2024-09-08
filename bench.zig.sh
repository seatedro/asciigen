# zig build run -Drelease -- -i images/skull.png -o ascii.png -e -c -b 15.0
zig build run -Drelease -- -i "https://w.wallhaven.cc/full/85/wallhaven-856dlk.png" -o ascii.png -e -c --full_characters --sorted_ovr
