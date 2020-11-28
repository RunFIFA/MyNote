echo off
netsh interface ip set address name="本地连接" source=dhcp
echo off
netsh interface ip set dns name="本地连接" source=dhcp