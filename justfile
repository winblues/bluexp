build:
  bluebuild build -B podman --tempdir /var/tmp recipes/recipe.yml

test-local:
  bluebuild rebase --tempdir /var/tmp recipes/recipe.yml

generate-iso:
  sudo bluebuild generate-iso --iso-name bluexp-latest.iso image ghcr.io/ledif/bluexp:latest
