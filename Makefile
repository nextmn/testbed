.PHONY: default u d t j
docker-compose.yaml: docker-compose.yaml.j2 scripts/jinja/customize.py config.yaml
	j2 --customize scripts/jinja/customize.py -o docker-compose.yaml config.yaml

j: docker-compose.yaml
