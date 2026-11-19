# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Przegląd

Portfolio użytkownika (`pkarpiuk.github.io`) na GitHub Pages: anglojęzyczna, statyczna gablotka z projektami. Publikacja = push na `main`. **Na stronie nie wolno używać JS** (lightbox działa na samym CSS przez `:target`).

## Architektura

- `index.json` — jedyne źródło danych o projektach (`projects[]`: `name`, `description`, `tags`, `links`, `screenshots[{file, alt}]`).
- `generate.rb` — `ruby generate.rb` wstawia karty projektów do `index.html` między znaczniki `<!-- BEGIN SHOWCASE -->` / `<!-- END SHOWCASE -->` oraz tworzy miniatury screenshotów w `imgs/thumbs/` (ImageMagick). Nie edytuj ręcznie treści między znacznikami — zostanie nadpisana.
- `index.html` — ręczny szkielet strony (nagłówek, stopka) + wygenerowana gablotka.
- `main.css` — style, w tym ciemny motyw (`prefers-color-scheme`) i lightbox.
- `imgs/` — oryginalne screenshoty; `imgs/thumbs/` — miniatury (generowane).

Po zmianie `index.json` zawsze uruchom `ruby generate.rb`. Podgląd lokalny: `python3 -m http.server`.

## Git

Po każdej zmianie rób commit automatycznie. Nie wykonuj `git push` — pushe robi użytkownik.
