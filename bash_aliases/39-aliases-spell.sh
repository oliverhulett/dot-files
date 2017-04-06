
unalias spell 2>/dev/null
function spell()
{
	echo $* | aspell pipe --suggest --guess
}
