.PHONY: start

start:
	mkdir -p priv
	cp src/favicon.ico priv/favicon.ico
	cp src/app.js priv/app.js
	tailwindcss --content './src/**/*.gleam' --input src/app.css --output priv/app.css
	gleam run

