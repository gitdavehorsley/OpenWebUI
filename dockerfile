# Start with a base image (consider using a lightweight base image like Alpine for smaller image sizes)
FROM ghcr.io/open-webui/open-webui:main

# (Optional) Add any specific configurations or dependencies needed for your use case
# For example, if you need specific Python packages not included in the default image:
# RUN pip install your_package

# (Optional) Set environment variables, such as disabling multi-user mode
# ENV WEBUI_AUTH=False

# Expose the port where Open WebUI listens (default is 8080)
EXPOSE 8080

# Keep the original entrypoint and command from the base image
# ENTRYPOINT ["bash", "start.sh"]
# CMD ["bash", "start.sh"]
