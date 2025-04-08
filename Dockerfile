# Use Node.js LTS version
FROM node:18

# Set working directory
WORKDIR /app

# Copy files
COPY package*.json ./
RUN npm install
COPY . .

# Expose the port 3000
EXPOSE 3000

# Start the app
CMD ["npm", "start"]
