# ---------- Stage 1: Build the React app ----------
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev
COPY . .
RUN npm run build

# ---------- Stage 2: Serve the build using Nginx ----------
FROM nginx:alpine
# Copy React build output from the "build" stage to Nginx html folder
COPY --from=build /app/build /usr/share/nginx/html

# Expose port 80 to the host
EXPOSE 80

# Keep Nginx running in foreground
CMD ["nginx", "-g", "daemon off;"]

