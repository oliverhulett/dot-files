@echo off
set /p passwd=<C:\Users\olihul\passwd
set HTTP_PROXY=http://olihul:%passwd%@sydproxy.comp.optiver.com:8080
set HTTPS_PROXY=http://olihul:%passwd%@sydproxy.comp.optiver.com:8080
