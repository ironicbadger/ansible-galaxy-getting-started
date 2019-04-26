example: 
	ansible-playbook -i hosts -u alex -b site.yml --limit example

cartman: 
	ansible-playbook -i hosts -u alex -b site.yml --limit cartman 

cartmancomp: 
	ansible-playbook -i hosts -u alex -b site.yml --limit cartman --tags compose

reqs:
	ansible-galaxy install -r requirements.yml

force-reqs:
	ansible-galaxy install -r requirements.yml  --force