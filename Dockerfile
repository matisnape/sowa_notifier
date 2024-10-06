# Use the official Elixir image as the base image
FROM elixir:1.16-alpine AS build

# Install build dependencies
RUN apk add --no-cache build-base git

# Set the working directory
WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy mix.exs and mix.lock files
COPY mix.exs mix.lock ./

# Install dependencies
RUN mix deps.get --only prod

# Copy the rest of the application code
COPY . .

# Compile the project
RUN MIX_ENV=prod mix compile

# Start a new build stage
FROM elixir:1.16-alpine AS app

# Install hex and rebar in the final image
RUN mix local.hex --force && \
    mix local.rebar --force

# Add a label to identify the container
LABEL app="sowa_notifier"

# Set the working directory
WORKDIR /app

# Copy the compiled application from the build stage
COPY --from=build /app /app

# Set the environment to production
ENV MIX_ENV=prod

# Expose the port the app runs on
EXPOSE 8080

# Run the application
CMD ["mix", "run", "--no-halt"]
