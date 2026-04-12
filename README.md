
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

### Mode save tokens

-  [Caveman: why use many tokens when few do trick](https://github.com/patchamama/caveman)

### Agent Assistants

- [Portable AI agent skills. One CLI. Every coding assistant.](https://www.npmjs.com/package/@skilly-hand/skilly-hand)
