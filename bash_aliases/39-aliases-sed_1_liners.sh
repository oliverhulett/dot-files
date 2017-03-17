# Useful 1-liners for sed, awk, etc.
# For more, see: http://sed.sourceforge.net/sed1line.txt
# Add them as you use them.
alias sed_del-leading-blank-lines='sed -e '"'"'/./,$!d'"'"
alias sed_del-trailing-blank-lines='sed -e :a -e '"'"'/^\n*$/{$d;N;};/\n$/ba'"'"
