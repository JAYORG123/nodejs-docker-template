# ============================================
# DOCKERFILE FOR PRODUCTION
# ============================================
# This Dockerfile uses multi-stage builds to create an optimized,
# secure production image with minimal size
# TypeScript is compiled in build stage, only compiled JS goes to production

# ============================================
# STAGE 1: Build TypeScript
# ============================================
# Compile TypeScript to JavaScript
FROM node:20-alpine@sha256:658d0f63e501824d6c23e06d4bb95c71e7d704537c9d9272f488ac03a370d448 AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Copy TypeScript configuration
COPY tsconfig.json ./

# Install ALL dependencies (including devDependencies for TypeScript compiler)
RUN npm ci

# Copy source code
# Note: Paths are relative to build context (project root), not Dockerfile location
# Build context is set to '..' in docker-compose.yml, so './src' refers to <root>/src
COPY src ./src

# Compile TypeScript to JavaScript
# Output will be in the 'dist' folder as configured in tsconfig.json
RUN npm run build

# ============================================
# STAGE 2: Production Dependencies
# ============================================
# Install production dependencies only
FROM node:20-alpine@sha256:658d0f63e501824d6c23e06d4bb95c71e7d704537c9d9272f488ac03a370d448 AS dependencies

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install only production dependencies
# --production flag skips devDependencies (TypeScript, ts-node, etc.)
# --frozen-lockfile ensures exact versions from package-lock.json
RUN npm ci --production --frozen-lockfile

# ============================================
# STAGE 3: Production Image
# ============================================
# Create the final, minimal production image with only compiled code
FROM node:20-alpine@sha256:658d0f63e501824d6c23e06d4bb95c71e7d704537c9d9272f488ac03a370d448 AS production

# Install dumb-init for proper signal handling
# dumb-init ensures signals (like SIGTERM) are properly forwarded to Node.js
# This enables graceful shutdowns when stopping containers
RUN apk add --no-cache dumb-init

WORKDIR /app

# Create a non-root user for security
# Running as non-root is a security best practice
# It limits damage if the container is compromised
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy production dependencies from dependencies stage
# This includes only production node_modules (no TypeScript, ts-node, etc.)
COPY --from=dependencies --chown=nodejs:nodejs /app/node_modules ./node_modules

# Copy package files
COPY --chown=nodejs:nodejs package*.json ./

# Copy ONLY compiled JavaScript from builder stage
# We don't copy TypeScript source files to production image
# This keeps the image smaller and more secure
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist

# Switch to non-root user
# All subsequent commands run as this user
USER nodejs

# Expose application port for documentation and inter-container communication
# Note: Use ports: in docker-compose.yml to actually publish to host
EXPOSE 3000

# Set production environment
ENV NODE_ENV=production

# Use dumb-init as PID 1 to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start the application
CMD ["npm", "start"]

# ============================================
# USAGE
# ============================================
# Build production image:
#   docker compose build
#
# Start container:
#   docker compose up -d
#
# View logs:
#   docker compose logs -f app
#
# Stop container:
#   docker compose down
# ============================================
