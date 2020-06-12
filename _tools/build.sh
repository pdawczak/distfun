export MIX_ENV=prod
export SECRET_KEY_BASE=$(LC_ALL=C tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' </dev/urandom | head -c 64)
# export PORT=80

echo "Install deps"
mix do deps.get, deps.compile

echo "Compile assets"
npm --prefix ./assets ci --progress=false --no-audit --loglevel=error
npm run --prefix ./assets deploy

echo "mix phx.digest"
mix phx.digest

echo "mix compile"
mix compile

echo "mix release"
# mix release --path /built_release
mix release --path /artifact

echo "Compress..."
tar -czvf artifact.tar.gz /artifact

mv artifact.tar.gz "/built_release/$(date +"%s")-artifact.tar.gz"
