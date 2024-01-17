.PHONY: default u d t j
docker-compose.yaml: docker-compose.yaml.j2 scripts/jinja/customize.py config.yaml
	j2 --customize scripts/jinja/customize.py -o docker-compose.yaml docker-compose.yaml.j2 config.yaml

j: docker-compose.yaml

pull: docker-compose.yaml
	docker compose pull

u: docker-compose.yaml
	docker compose up
d:
	# don't depends on docker-compose.yaml because we need the old version to delete all
	docker compose down
