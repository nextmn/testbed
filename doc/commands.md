# Available commands
## Set
- dataplane
  - `make set/dataplane/nextmn-srv6`: use NextMN SRv6 (default)
  - `make set/dataplane/nextmn-upf`: use NextMN UPFs
  - `make set/dataplane/free5gc`: use Free5GC's UPFs
- number of UEs: `make set/nb-ue/<number>` (max: 2)
- number of Edges: `make set/nb-edges/<number>` (max: 2)

## Pull
When you update the git repository, please ensure to update Docker images as well.
- `make pull` pulls required images to run the project with the current configuration.
- `make pull/all` pulls all images used by the project.

## Running the testbed
- `make build`: build the testbed, without running it
- `make clean`: clean the build directory
- `make up`: equivalent of `docker compose up -d`
- `make up-fg`: equivalent of `docker compose up`
- `make down`: equivalent of `docker compose down`
- `make restart`: equivalent of `docker compose restart`
- `make ps`: equivalent of `docker compose ps`
- `make l`: equivalent of `docker compose logs`
- `make lf`: equivalent of `docker compose logs -f`
- `make ctrl`: open in your browser the control API URLs of NextMN SRv6 nodes

## Using containers
- `make e/<container-name>`: enter the base container
- `make t/<container-name>`: enter the container with debug tools
- `make db/<container-name>`: enter the database associated with a container (for NextMN-SRv6)
- `make l/<container-name>`: show logs of a container
- `make lf/<container-name>`: show logs of a container (continuous)
- `make ping/<container-source-name>/<container-target-name>`: ping from `container-source` to `container-target`

## Using UEs
- `make ue/ip/<ue-number>`: show IP Address of the UE within the Mobile Network
- `make ue/ping/<ue-source-number>/<ue-target-number>`: ping from `ue-source` to `ue-target`
