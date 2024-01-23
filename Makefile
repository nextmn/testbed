.PHONY: default u d t j
compose.yaml: compose.yaml.j2 scripts/jinja/customize.py config.yaml
	j2 --customize scripts/jinja/customize.py -o compose.yaml compose.yaml.j2 config.yaml

j: compose.yaml

pull: compose.yaml
	docker compose pull

u: compose.yaml
	docker compose up
d:
	# don't depends on docker-compose.yaml because we need the old version to delete all
	docker compose down
