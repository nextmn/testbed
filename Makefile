.PHONY: default u d t j test
build:
	mkdir build

build/compose.yaml: build compose.yaml.j2 scripts/jinja/customize.py config.yaml
	j2 --customize scripts/jinja/customize.py -o build/compose.yaml compose.yaml.j2 config.yaml

test: build/compose.yaml
	yamllint build

j: build/compose.yaml

pull: build/compose.yaml
	docker compose --project-directory build pull

u: build/compose.yaml
	docker compose --project-directory build up
d:
	# don't depends on docker-compose.yaml because we need the old version to delete all
	docker compose --project-directory build down
