@echo off
set /p passwd=<C:\Users\olihul\passwd

REM Some URLs use this...
set http_proxy=http://olihul:%passwd%@sydsquid.aus.optiver.com:3128
set https_proxy=https://olihul:%passwd%@sydsquid.aus.optiver.com:3128

REM ...when they can't use this.
REM set http_proxy=http://olihul:%passwd%@safeweb-au.aus.optiver.com:3129
REM set https_proxy=https://olihul:%passwd%@safeweb-au.aus.optiver.com:3129
