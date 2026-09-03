# ==========================================
# Stage 1: Build & Dependencies
# ==========================================
FROM node:18-alpine AS builder

WORKDIR /app

# Copy dependency manifests
COPY package*.json ./

# Install all dependencies
RUN npm install

# Copy application source code
COPY . .

# ==========================================
# Stage 2: Minimal Production Runtime
# ==========================================
FROM node:18-alpine AS production

WORKDIR /app

# Copy package manifests and install only production dependencies
COPY --from=builder /app/package*.json ./
RUN npm install --omit=dev

# Copy application source from builder stage
COPY --from=builder /app/server.js ./

# Document port exposure
EXPOSE 8080

# Start application
CMD ["npm", "start"]
