# Bijdragen aan Earworm

Bedankt voor je interesse in Earworm. Bijdragen zijn welkom, van bugfixes tot nieuwe features.

## Aan de slag

1. Fork de repository
2. Maak een feature branch: `git checkout -b feature/mijn-feature`
3. Installeer de dev dependencies: `pip install -e ".[dev]"`
4. Maak je wijzigingen
5. Draai de tests: `pytest`
6. Draai de linter: `ruff check .`
7. Commit en push naar je fork
8. Open een pull request

## Code stijl

- We gebruiken [ruff](https://github.com/astral-sh/ruff) voor linting en [black](https://github.com/psf/black) voor formatting
- Max regellengte: 99 tekens
- Docstrings in het Engels (voor internationale toegankelijkheid)
- Type hints waar mogelijk

## Waar kun je mee helpen?

### Audio en ML
- Verbeteren van transcriptienauwkeurigheid, vooral voor niet-piano bronnen
- Experimenteren met andere transcriptiemodellen
- Optimaliseren van de Demucs pipeline

### Muziektheorie
- Betere algoritmen voor moeilijkheidsgraad-vereenvoudiging
- Handscheiding (linker/rechterhand detectie)
- Slimme arrangementen die musicaal kloppen

### Frontend
- Web interface met falling-notes visualisatie
- Web MIDI API integratie
- UX design voor de oefeninterface

### Testing
- Testen met verschillende muziekgenres
- Testen met verschillende MIDI keyboards
- Integratie- en end-to-end tests

## Issues

- Check of je issue al bestaat voordat je een nieuwe aanmaakt
- Gebruik labels waar mogelijk
- Voeg stappen toe om het probleem te reproduceren

## Pull requests

- Houd PRs klein en gefocust op een ding
- Voeg tests toe voor nieuwe functionaliteit
- Update de README als je iets aan de publieke API verandert
- Beschrijf wat je PR doet en waarom

## Vragen?

Open een issue met het label `question`, of start een discussie in de Discussions tab.
