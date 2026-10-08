# Robert Bruegger — IT Portfolio Website

A responsive static portfolio website for your resume and home lab projects.

## Files
- `index.html` — content and page structure
- `css/styles.css` — fonts, colors, layout, mobile styling
- `js/main.js` — mobile navigation and copyright year
- `docs/` — add your real resume PDF here
- `assets/` — add screenshots, photos, and project diagrams

## Preview at work
Unzip the folder and double-click `index.html`. No installation or server required.

## Customize
1. Update project descriptions in `index.html` as your lab progresses.
2. Edit `css/styles.css` to adjust fonts/colors. `--accent` changes the green highlight.
3. Save your real resume as `docs/Robert_Bruegger_Resume.pdf`.
4. In `index.html`, change `href="docs/README.txt"` to `href="docs/Robert_Bruegger_Resume.pdf"` and the button text to `Download resume PDF`.
5. Add a professional email link if desired: `<a href="mailto:your-email@example.com">Email me</a>`.

## Deploy later on Proxmox
When Proxmox is running, create a small Debian or Ubuntu VM/LXC, install Nginx, and copy these files to its web root (commonly `/var/www/html`). You can also host the same files with Apache or IIS. Do not expose the Proxmox admin interface to the public internet. Use HTTPS and a reverse proxy or secure tunnel when publishing.

## Notes
This project uses HTML, CSS, and **JavaScript**, not Java. A static portfolio needs no backend or database. Descriptions are intentionally careful about what is complete versus planned.


## Education section (updated October 2026)

The navigation now includes a dedicated **Education** section (`#education`). It contains:
- System Administration Specialist — Associate Degree, in progress, Madison College
- Desktop Support Technician — Associate Degree, completed Spring 2026, Madison College
- AWS Academy Cloud Foundations
- Google Foundations of Cybersecurity

Edit these details directly in `index.html` as your coursework and credentials change. The Experience section separately lists Evo Counseling and Community Living Connections. No server or build tools are needed to preview: open `index.html` in a browser.
