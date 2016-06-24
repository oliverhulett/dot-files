# docker container to build things under c5
function c5()
{
	docker run -u `id -u` -h `hostname` -v /etc/:/etc/ -v ~/:`echo $HOME`/ -v `pwd`:/src -w /src --env-file=<(/usr/bin/env | /usr/bin/grep -vE 'PS1') --tty=true --interactive=true docker-registry.aus.optiver.com/servicedelivery/el5-development "$@"
}
