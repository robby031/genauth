/// Maps well-known service/issuer names to their primary domain so we can
/// fetch a brand favicon via Google's favicon API.  Only services that have
/// a reliable, recognisable favicon are listed here.  Unknown issuers fall
/// back to a letter avatar instead of guessing a domain.
class IconService {
  IconService._();

  static const Map<String, String> _domains = {
    // Google ecosystem
    'google': 'google.com',
    'gmail': 'google.com',
    'google account': 'google.com',
    'firebase': 'firebase.google.com',
    'youtube': 'youtube.com',
    // Microsoft ecosystem
    'microsoft': 'microsoft.com',
    'outlook': 'microsoft.com',
    'hotmail': 'microsoft.com',
    'office': 'microsoft.com',
    'office 365': 'microsoft.com',
    'azure': 'azure.microsoft.com',
    'github': 'github.com',
    // Apple
    'apple': 'apple.com',
    'icloud': 'icloud.com',
    // Meta / Facebook
    'facebook': 'facebook.com',
    'meta': 'meta.com',
    'instagram': 'instagram.com',
    'whatsapp': 'whatsapp.com',
    // Twitter / X
    'twitter': 'twitter.com',
    'x': 'x.com',
    // Amazon ecosystem
    'amazon': 'amazon.com',
    'aws': 'aws.amazon.com',
    // Source control
    'gitlab': 'gitlab.com',
    'bitbucket': 'bitbucket.org',
    // Cloud / hosting
    'digitalocean': 'digitalocean.com',
    'heroku': 'heroku.com',
    'netlify': 'netlify.com',
    'vercel': 'vercel.com',
    'cloudflare': 'cloudflare.com',
    // Communication
    'discord': 'discord.com',
    'slack': 'slack.com',
    'zoom': 'zoom.us',
    'twitch': 'twitch.tv',
    // Storage
    'dropbox': 'dropbox.com',
    // Social / professional
    'linkedin': 'linkedin.com',
    'reddit': 'reddit.com',
    // Payments / crypto
    'paypal': 'paypal.com',
    'stripe': 'stripe.com',
    'binance': 'binance.com',
    'coinbase': 'coinbase.com',
    'kraken': 'kraken.com',
    // Password managers
    '1password': '1password.com',
    'lastpass': 'lastpass.com',
    'bitwarden': 'bitwarden.com',
    // Privacy / security
    'proton': 'proton.me',
    'protonmail': 'proton.me',
    'protonvpn': 'protonvpn.com',
    'okta': 'okta.com',
    'auth0': 'auth0.com',
    // Developer tools
    'npm': 'npmjs.com',
    'docker': 'docker.com',
    'atlassian': 'atlassian.com',
    'jira': 'atlassian.com',
    'confluence': 'atlassian.com',
    // CMS / e-commerce
    'shopify': 'shopify.com',
    'wordpress': 'wordpress.com',
    // Productivity
    'notion': 'notion.so',
    'figma': 'figma.com',
    // Other common services
    'salesforce': 'salesforce.com',
    'hubspot': 'hubspot.com',
    'twilio': 'twilio.com',
    'sendgrid': 'sendgrid.com',
    'namecheap': 'namecheap.com',
    'godaddy': 'godaddy.com',
    'robinhood': 'robinhood.com',
  };

  /// Returns a Google Favicon API URL for [issuer] if it is a well-known
  /// service, or null otherwise.  Callers should fall back to a letter avatar
  /// when this returns null.
  static String? faviconUrl(String issuer) {
    if (issuer.isEmpty) return null;
    final key = issuer.trim().toLowerCase();
    final domain = _domains[key];
    if (domain == null) return null;
    return 'https://www.google.com/s2/favicons?domain=$domain&sz=64';
  }
}
