.PHONY: run-back run-front install-all test-back

# Ejecutar todo (Backend + Frontend)
run:
	powershell -ExecutionPolicy Bypass -File run_app.ps1

# Ejecutar el Backend
run-back:
	cd backend && uvicorn main:app --reload

# Ejecutar el Frontend
run-front:
	cd frontend && flutter run

# Instalar todas las dependencias (Global)
install-all:
	pip install -r requirements.txt
	cd frontend && flutter pub get

# Levantar todo con Docker (Backend + DB)
docker-up:
	docker-compose up --build -d

# Detener contenedores
docker-down:
	docker-compose down

# Ver logs del backend
docker-logs:
	docker logs -f logw_backend
