DOCKER_COMPOSE = ./srcs/docker-compose.yml
DATA_DIR = /home/mamaratr/data


all: up

up:
	@mkdir -p $(DATA_DIR)/mariadb
	@mkdir -p $(DATA_DIR)/wordpress
	@docker compose -f $(DOCKER_COMPOSE) up -d --build
	@echo "Containers started"

down:
	@docker compose -f $(DOCKER_COMPOSE) down
	@echo "Containers stopped"

clean: down
	@docker compose -f $(DOCKER_COMPOSE) down --rmi all
	@echo "Clean"

fclean: clean
	@docker compose -f $(DOCKER_COMPOSE) down --rmi all -v
	@rm -rf $(DATA_DIR)/wordpress/*
	@rm -rf $(DATA_DIR)/mariadb/*
	@echo "Full clean"

re: fclean all

.PHONY: all up down clean fclean re