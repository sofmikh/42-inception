# =============================================================
# Inception - Makefile
# =============================================================

NAME    = inception
COMPOSE = srcs/docker-compose.yml

# /home/smikhail/data is the host path used by Docker volumes
# These directories must exist before docker compose creates the volumes
DATA_DIR = /home/smikhail/data

all: setup up

# Create host directories for Docker bind-mount volumes
setup:
	@mkdir -p $(DATA_DIR)/wordpress
	@mkdir -p $(DATA_DIR)/mariadb
	@echo "[setup] Data directories ready at $(DATA_DIR)"

# Build all images from scratch and start containers in detached mode
up:
	@docker compose -f $(COMPOSE) up -d --build
	@echo "[up] All containers are running."

# Stop all containers without removing data
down:
	@docker compose -f $(COMPOSE) down
	@echo "[down] Containers stopped."

# Stop containers and remove Docker volumes (host data is kept)
clean:
	@docker compose -f $(COMPOSE) down -v
	@echo "[clean] Containers and Docker volumes removed."

# Full cleanup: remove all Docker resources and host data directories
# Used to start completely from scratch
fclean: clean
	@docker stop $$(docker ps -qa) 2>/dev/null || true
	@docker rm $$(docker ps -qa) 2>/dev/null || true
	@docker rmi -f $$(docker images -qa) 2>/dev/null || true
	@docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	@docker network rm $$(docker network ls -q) 2>/dev/null || true
	@sudo rm -rf $(DATA_DIR)
	@echo "[fclean] Full cleanup complete."

# Rebuild everything from zero
re: fclean all

.PHONY: all setup up down clean fclean re
