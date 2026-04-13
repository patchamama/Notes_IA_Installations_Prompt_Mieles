
### Installation

Mac OS X

```sh
brew install ollama
ollama
brew install opencode

# Install agents (gentle-ai agents and settings) See: https://github.com/Gentleman-Programming/gentle-ai
curl -fsSL https://raw.githubusercontent.com/Gentleman-Programming/gentle-ai/main/scripts/install.sh | bash

# Install glm-4.7 flash model
ollama pull hf.co/unsloth/GLM-4.7-Flash-GGUF:UD-Q4_K_XL

#  Launch opencode with Ollama integration
ollama launch opencode --config
```

- Activate for the use of the free/paid model in https://opencode.ai/zen to use `opencode Go`

### IOS/Android APP to test local models

- Google AI Edge Gallery para modelos locales de Google como Gemma 4.

### Mode save tokens

-  [Caveman: why use many tokens when few do trick](https://github.com/patchamama/caveman)

Install

```sh
claude plugin marketplace add JuliusBrussee/caveman && claude plugin install caveman@caveman
```

Trigger with:
```
/caveman or `Codex $caveman`
"talk like caveman"
"caveman mode"
"less tokens please"
```

Stop with: `"stop caveman" or "normal mode"`

### Agent Assistants

- [Portable AI agent skills. One CLI. Every coding assistant.](https://www.npmjs.com/package/@skilly-hand/skilly-hand)

| Command                     | Description                                              |
|----------------------------|----------------------------------------------------------|
| npx skilly-hand install    | Install skills into the current project                  |
| npx skilly-hand detect     | Auto-detect project stack and suggest skills            |
| npx skilly-hand list       | List all available skills in the catalog                |
| npx skilly-hand doctor     | Diagnose installation and configuration issues          |
| npx skilly-hand uninstall  | Remove installed skills    

### Improve the search (grep) for information in the documents

- [mgrep: A calm, CLI-native way to semantically grep everything, like code, images, pdfs and more.](https://github.com/mixedbread-ai/mgrep)
