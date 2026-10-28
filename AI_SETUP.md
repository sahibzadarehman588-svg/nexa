# NEXIA AI Service Setup Guide

## Overview

NEXIA integrates with AI services to provide intelligent features like:
- AI Chat Assistant
- Voice AI Assistant
- Document AI (summarization)
- Receipt Scanner (intelligent parsing)

To use these features, you need to configure an AI API key. NEXIA supports OpenAI-compatible APIs.

## Supported AI Providers

### OpenAI (Recommended)
- **Models**: GPT-3.5-turbo, GPT-4, GPT-4-turbo
- **API Endpoint**: https://api.openai.com/v1/chat/completions
- **Pricing**: Pay-per-use, see [OpenAI Pricing](https://openai.com/pricing)
- **Documentation**: [OpenAI API Docs](https://platform.openai.com/docs)

### OpenAI-Compatible Providers
NEXIA can work with any OpenAI-compatible API:
- **Azure OpenAI**: Microsoft's managed OpenAI service
- **Anthropic Claude**: Via OpenAI-compatible endpoints
- **Local AI**: Ollama, LocalAI, or other local LLM servers
- **Custom Endpoints**: Any server implementing the OpenAI API format

## Setup Instructions

### Step 1: Get an API Key

#### For OpenAI:
1. Visit [https://platform.openai.com/](https://platform.openai.com/)
2. Sign up or log in
3. Navigate to API Keys section
4. Create a new API key
5. Copy the API key (starts with `sk-...`)

#### For Azure OpenAI:
1. Set up an Azure OpenAI resource
2. Get the API key and endpoint URL
3. Use the endpoint URL as the base URL in NEXIA

#### For Local AI (Ollama):
1. Install Ollama from [https://ollama.ai/](https://ollama.ai/)
2. Run Ollama with OpenAI-compatible API server
3. Use `http://localhost:11434/v1/chat/completions` as base URL
4. Leave API key empty or use any placeholder

### Step 2: Configure AI Service in NEXIA

1. Open NEXIA app
2. Navigate to **AI Chat** screen
3. Tap the configuration warning message or look for settings
4. Enter your API key
5. Tap "Save"

**Note**: Your API key is stored locally on your device and never sent to NEXIA servers.

### Step 3: Configure Advanced Settings (Optional)

If you're using a custom AI provider, you may need to configure:
- **Base URL**: The API endpoint URL
- **Model**: The specific model to use (e.g., `gpt-4`, `gpt-3.5-turbo`)

These settings can be configured in the AI settings screen.

## Model Recommendations

### For General Use
- **GPT-3.5-turbo**: Fast, cost-effective, good for most tasks
- **Recommended for**: Chat, document summarization, receipt parsing

### For Advanced Use
- **GPT-4**: More accurate, better reasoning
- **Recommended for**: Complex queries, detailed analysis
- **Note**: Higher cost and slower response time

### For Cost Optimization
- **GPT-3.5-turbo**: Most cost-effective
- **Local AI**: Free if running locally (no API costs)
- **Recommended for**: Development, testing, cost-sensitive use

## Cost Estimation

### OpenAI Pricing (as of 2024)
- **GPT-3.5-turbo**: ~$0.002 per 1K tokens (input), $0.002 per 1K tokens (output)
- **GPT-4**: ~$0.03 per 1K tokens (input), $0.06 per 1K tokens (output)

### Estimated NEXIA Usage
- **AI Chat**: ~100-200 tokens per interaction
- **Document Summarization**: ~500-1000 tokens per document
- **Receipt Parsing**: ~300-500 tokens per receipt
- **Voice Assistant**: ~100-200 tokens per interaction

**Example Cost (GPT-3.5-turbo)**:
- 100 chat interactions: ~$0.04
- 50 document summaries: ~$0.10
- 100 receipts: ~$0.06
- **Total**: ~$0.20 per month for moderate use

## Security Best Practices

### API Key Security
- **Never Share**: Don't share your API key with others
- **Rotate Regularly**: Change your API key periodically
- **Revoke If Compromised**: Immediately revoke if leaked
- **Use Environment Variables**: For development, use environment variables

### Usage Monitoring
- **Check Usage**: Monitor your API usage regularly
- **Set Limits**: Set usage limits in your AI provider dashboard
- **Review Bills**: Review your billing statements

### Rate Limiting
NEXIA implements client-side rate limiting:
- **Maximum**: 60 requests per minute
- **Automatic**: Requests are automatically throttled
- **Error Messages**: Clear messages when limits are exceeded

## Troubleshooting

### Common Issues

#### "AI service not configured"
- **Cause**: API key not set
- **Solution**: Configure your API key in AI Chat settings

#### "Invalid API key"
- **Cause**: Incorrect API key
- **Solution**: Verify your API key and re-enter it

#### "Rate limit exceeded"
- **Cause**: Too many requests in short time
- **Solution**: Wait a few minutes before trying again

#### "Request timed out"
- **Cause**: Network issue or slow response
- **Solution**: Check your internet connection and try again

#### "Network error"
- **Cause**: No internet connection
- **Solution**: Check your internet connection

### Testing Your Setup

1. **Test AI Chat**:
   - Open AI Chat screen
   - Send a simple message like "Hello"
   - Verify you get a response

2. **Test Document AI**:
   - Open Document AI screen
   - Capture or select a document
   - Generate a summary
   - Verify you get a summary

3. **Test Receipt Scanner**:
   - Open Receipt Scanner screen
   - Capture or select a receipt
   - Verify data extraction works

## Local AI Setup (Advanced)

### Using Ollama

1. **Install Ollama**:
   ```bash
   # macOS/Linux
   curl -fsSL https://ollama.ai/install.sh | sh

   # Windows
   # Download from https://ollama.ai/download
   ```

2. **Start Ollama Server**:
   ```bash
   ollama serve
   ```

3. **Download a Model**:
   ```bash
   ollama pull llama2
   ```

4. **Configure NEXIA**:
   - Base URL: `http://localhost:11434/v1/chat/completions`
   - Model: `llama2`
   - API Key: (leave empty or use any placeholder)

### Using LocalAI

1. **Install LocalAI**:
   ```bash
   docker run -p 8080:8080 localai/localai
   ```

2. **Configure NEXIA**:
   - Base URL: `http://localhost:8080/v1/chat/completions`
   - Model: (depends on installed models)
   - API Key: (leave empty or use any placeholder)

## Support

For issues with AI service configuration:
- Check the [Security Documentation](SECURITY.md) for security considerations
- Review your AI provider's documentation
- Check NEXIA's help documentation

## Privacy Notice

- Your API key is stored locally on your device
- API keys are never transmitted to NEXIA servers
- Your data is sent directly to the AI provider you configure
- Review your AI provider's privacy policy for details on data handling

## Version History

- **v1.0.0**: Initial AI setup guide
