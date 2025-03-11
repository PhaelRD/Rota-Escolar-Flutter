# Usar Node.js como base
FROM node:18

# Definir diretório de trabalho
WORKDIR /app

# Copiar arquivos
COPY package*.json ./
RUN npm install

COPY . .

# Expor porta
EXPOSE 8080

# Rodar app
CMD ["node", "index.js"]
