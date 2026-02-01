# AI Motorcycle Visual Identifier

**Platform**: n8n
**Status**: Production
**Purpose**: Webhook-triggered image analysis with AI recommendations

## What It Does

Upload a motorcycle image → Get AI identification + recommendations via email.

## Workflow Visualization

```
┌─────────────────────────────────────────────────────────────────┐
│                    MOTORCYCLE IDENTIFIER                         │
└─────────────────────────────────────────────────────────────────┘

[Webhook POST]
    │ (Image upload)
    ↓
[Binary → Base64 Conversion]
    ↓
[OpenAI Vision API]
    │ → Identifies: Make, model, year, features
    ↓
[OpenRouter LLM + SerpAPI]
    │ → Generates: Recommendations, similar bikes, pricing
    ↓
[Markdown → HTML]
    │ → Formats results
    ↓
[Gmail API]
    │ → Delivers email with analysis
    ↓
[Complete]
```

## APIs Used

1. **Webhook** - Event trigger
2. **OpenAI GPT-4o Vision** - Image analysis
3. **OpenRouter LLM** - Recommendation generation
4. **SerpAPI** - Web search for market data
5. **Gmail API** - Email delivery

## Technical Skills Demonstrated

**Integration Engineering**:
- Webhook-based event handling
- Multi-API orchestration (5 APIs chained)
- Data transformation pipeline (binary → base64 → JSON → markdown → HTML)
- Error handling and conditional logic

**Data Processing**:
- Binary image processing
- JSON parsing and manipulation
- Format conversion (markdown/HTML)
- Email templating

**Authentication**:
- API key management
- OAuth2 (Gmail)

**Prompt Engineering**:
- Vision API prompts for structured output
- Multi-step LLM reasoning
- Context passing between APIs

## Why This Matters

This pattern (webhook → analysis → enrichment → notification) is common in enterprise integrations:
- Order processing → validation → fulfillment → confirmation
- Support tickets → classification → routing → notification
- Form submissions → processing → CRM update → email

**Transferable to**: Zapier, Make, Frends (Visma), MuleSoft, Power Automate

---

*Part of [Hetzner Homelab Infrastructure](../../README.md)*
