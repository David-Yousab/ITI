# Use the official NGINX image as the base
FROM nginx:latest

# Remove default NGINX index.html and add a custom one
RUN echo '<h1>Jenkins Lab 1</h1>' > /usr/share/nginx/html/index.html

# Expose port 90
EXPOSE 90

# Change the default NGINX configuration to listen on port 90
RUN sed -i 's/listen 80;/listen 90;/' /etc/nginx/conf.d/default.conf

# Start NGINX
CMD ["nginx", "-g", "daemon off;"]
