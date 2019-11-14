# Sydent

## Installing

To install you will first need to generate an ED25519 signing key if you do not have one already.
You can do this by running:

```bash
./scripts/generate-key
```

Then you can install with:

```bash
helm install --set config.crypto."ed25519\.signingkey"="<Signing Key>" .
```
