@echo off
set /p passwd=<C:\Users\olihul\passwd
set HTTP_PROXY=http://olihul:%passwd%@sydsquid.aus.optiver.com:3128
set HTTPS_PROXY=http://olihul:%passwd%@sydsquid.aus.optiver.com:3128
