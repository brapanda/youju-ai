# Youju UI review prototype

`index.html` is an independent, dependency-free browser prototype for reviewing the design. It is **not the compiled Flutter application**.

Open the file in a browser, or serve the repository root with `python -m http.server 8765` and open `/design/` locally. No external API, map service or AI model is called.

Implemented review interactions:

- Mint-green light/dark themes, saved locally in this browser.
- Home, map/list, favorites, AI entrance and personal page navigation.
- Address/community search; transaction/type/bedroom/price filters and empty states.
- Illustrative map markers, selection and compact property preview.
- Property photo gallery and detail dialog.
- Favorites stored in this browser only, without an account.

All listing attributes are synthetic demo content. Photos were cropped from the old-app videos supplied by the user, only for this design review. Photos and sample attributes are not verified to describe the same property. The schematic map does not represent real geographic positions. AMPRE, Mapbox, authentication, device location, AI and multilingual services are not connected here.

UI checks ran with Playwright and system Chromium at 390×844 and 1440×1000, covering the interactions above and no horizontal overflow/page errors. These browser checks do not validate Flutter, Android or iOS builds.
