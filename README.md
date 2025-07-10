# cs-rehlds

## 1. Соберите Docker-образ
   ```bash
    docker build -t private-srv .
   ```
   
## 2. Запустите контейнер
   ```bash
    docker run -d --name srv -p 27015:27015/udp -p 27015:27015/tcp private-srv
  ````

## 3. Проверьте работу
   ```bash
        docker logs -f rehlds-test``
   ```

## 4. Узнайте IP WSL:
```bash
    ip addr show eth0 | grep inet
```