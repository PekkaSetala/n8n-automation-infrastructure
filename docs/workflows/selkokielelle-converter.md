# Selkokielelle - Plain Language Converter

**Platform**: n8n
**Status**: Production
**Purpose**: Automated Finnish text simplification (accessibility compliance)

## What It Does

Submit complex Finnish text → Get plain-language version via email (side-by-side comparison).

## Workflow Visualization

```
┌─────────────────────────────────────────────────────────────────┐
│                   SELKOKIELELLE CONVERTER                        │
└─────────────────────────────────────────────────────────────────┘

[Tally Form Webhook]
    │ (User submits text + email)
    ↓
[Data Extraction]
    │ → Original text, user email
    ↓
[OpenRouter LLM (GPT-4)]
    │ → Applies 15+ plain-language guidelines
    │ → Complex Finnish → Simple Finnish
    ↓
[Markdown → HTML]
    │ → Side-by-side comparison layout
    ↓
[Gmail API]
    │ → Delivers comparison email
    ↓
[Complete]
```

## APIs Used

1. **Tally Webhook** - Form submission trigger
2. **OpenRouter LLM** - Text transformation (GPT-4)
3. **Gmail API** - Email delivery

## Technical Skills Demonstrated

**Integration Engineering**:
- Form webhook integration
- API orchestration (form → AI → email)
- Data extraction from webhooks
- Error handling and validation

**Complex Prompt Engineering**:
- 15+ Finnish plain-language guidelines encoded in prompt
- Sentence length limits (8-12 words)
- Vocabulary simplification rules
- Active voice requirements
- Structured AI output formatting

**Data Transformation**:
- Text processing (complex → plain language)
- Markdown → HTML conversion
- Email styling with CSS
- Side-by-side comparison layout

**Compliance Automation**:
- Finnish accessibility standards (Selkokieli)
- EU Accessibility Directive compliance
- Government communication requirements

## Why This Matters

**Real Use Cases**:
- Government: Public sector communications
- Healthcare: Patient instructions, medical forms
- Legal: Contract simplification
- Corporate: HR policies, employee handbooks

**Business Impact**:
- Time reduction: 30-60 min → 5-10 min per page (80-90% faster)
- Consistency: Automated compliance vs. manual interpretation
- Scale: Process volumes impossible manually

**Integration Pattern** (form → transformation → notification) applies to:
- Translation workflows
- Content summarization
- Tone adjustment (formal → casual)
- Document generation

**Transferable to**: Power Automate, Zapier, Make, Frends (Visma)

---

*Part of [Hetzner Homelab Infrastructure](../../README.md)*
